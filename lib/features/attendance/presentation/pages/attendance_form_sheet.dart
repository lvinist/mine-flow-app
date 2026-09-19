import 'dart:async';

// Material: this file uses a Material primitive with no ForUI equivalent.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/core/offline/sync_queue_manager.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_crew_draft.dart';
import 'package:mine_flow/features/attendance/domain/entities/attendance_status.dart';
import 'package:mine_flow/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_bloc.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_event.dart';
import 'package:mine_flow/features/attendance/presentation/bloc/attendance_form_state.dart';
import 'package:mine_flow/features/attendance/presentation/widgets/attendance_crew_card.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

/// Route-hosted batch attendance sheet (STEP-55.5, master spec §4.4).
///
/// D1/D2 geometry comes from [AppResponsiveSheet]; D4 dirty guard is wired
/// through the sheet's `isDirty`/`isBusy`. Durable identity is the URL
/// `?date=YYYY-MM-DD&siteId=<id>` — refresh/deep link reconstructs the sheet
/// without in-memory `extra`. There is intentionally **no** per-member
/// inspector (D7 verdict): every choice is inline in the card.
class AttendanceFormSheet extends StatelessWidget {
  final AttendanceRepository repository;
  final AuthRepository? authRepository;
  final SyncQueueManager? syncQueueManager;

  /// Durable date from the URL (`?date=`); null defaults to local today.
  final DateTime? initialDate;

  /// Durable site from the URL (`?siteId=`); defaults only when authorized.
  final String? siteId;

  /// Cache-only identity (survives nothing).
  final Uri? routeUri;

  final VoidCallback? onClose;

  const AttendanceFormSheet({
    super.key,
    required this.repository,
    this.authRepository,
    this.syncQueueManager,
    this.initialDate,
    this.siteId,
    this.routeUri,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final targetDate = initialDate ?? DateTime(now.year, now.month, now.day);

    return BlocProvider(
      create: (context) => AttendanceFormBloc(
        repository: repository,
        authRepository: authRepository,
        syncQueueManager: syncQueueManager,
      )..add(AttendanceFormStarted(date: targetDate, siteId: siteId)),
      child: AttendanceFormSheetView(routeUri: routeUri, onClose: onClose),
    );
  }
}

class AttendanceFormSheetView extends StatefulWidget {
  final Uri? routeUri;
  final VoidCallback? onClose;

  const AttendanceFormSheetView({
    super.key,
    required this.routeUri,
    this.onClose,
  });

  @override
  State<AttendanceFormSheetView> createState() =>
      _AttendanceFormSheetViewState();
}

class _AttendanceFormSheetViewState extends State<AttendanceFormSheetView> {
  final Map<String, TextEditingController> _reasonControllers = {};
  final Map<String, FocusNode> _reasonFocusNodes = {};
  final ScrollController _scrollController = ScrollController();
  static final DateFormat _dateFormat = DateFormat(
    'EEEE, d MMMM yyyy',
    'id_ID',
  );

  @override
  void dispose() {
    for (final controller in _reasonControllers.values) {
      controller.dispose();
    }
    for (final node in _reasonFocusNodes.values) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  TextEditingController _reasonControllerFor(String userId) =>
      _reasonControllers.putIfAbsent(userId, () => TextEditingController());

  FocusNode _reasonFocusNodeFor(String userId) =>
      _reasonFocusNodes.putIfAbsent(userId, FocusNode.new);

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      // Cold URL without a stack: go to the list, preserving query context.
      context.go(AppRoutes.attendance);
    }
  }

  void _changeDate(DateTime date) {
    context.read<AttendanceFormBloc>().add(AttendanceFormDateChanged(date));
  }

  void _saveBatch() {
    context.read<AttendanceFormBloc>().add(
      AttendanceFormSubmitted(loggedBy: currentUserId()),
    );
  }

  /// STEP-55.11: the sync-queue stream (`watchAll`) emits once per enqueued
  /// mutation, and the success state keeps `successMessage` non-null across
  /// those emits. Without this latch the BlocConsumer listener re-fires on
  /// every queue change and `_handleClose` pops the route once per enqueued
  /// record — six records strip the whole stack back to the branch root.
  /// Closing is a one-shot transition, same idiom as the dirty-dismiss latch
  /// in `AppResponsiveSheet`.
  bool _hasClosed = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AttendanceFormBloc, AttendanceFormState>(
      listener: (context, state) {
        if (state is AttendanceFormLoaded) {
          if (state.successMessage != null) {
            if (_hasClosed) return;
            _hasClosed = true;
            showFToast(
              context: context,
              title: Text(state.successMessage!),
              duration: const Duration(seconds: 2),
            );
            _handleClose();
          } else if (state.firstInvalidUserId != null) {
            _focusFirstInvalid(state.firstInvalidUserId!);
          }
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final title = l10n.attendanceFormTitle;
        final routeId = widget.routeUri?.toString() ?? 'attendance-form';

        if (state is AttendanceFormLoading || state is AttendanceFormInitial) {
          return AppResponsiveSheet(
            routeIdentity: routeId,
            title: title,
            mode: AppResponsiveSheetMode.form,
            onDismissApproved: _handleClose,
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: FCircularProgress(),
              ),
            ),
          );
        }

        if (state is AttendanceFormError) {
          final l10n = AppLocalizations.of(context);
          return AppResponsiveSheet(
            routeIdentity: routeId,
            title: title,
            mode: AppResponsiveSheetMode.form,
            onDismissApproved: _handleClose,
            body: AppStatePanel(
              title: l10n.dataNotFound,
              message: state.message,
              actionLabel: l10n.backToList,
              onAction: _handleClose,
            ),
          );
        }

        final loaded = state as AttendanceFormLoaded;

        // Seed reason controllers from the draft's remarks so a cold-
        // reconstructed sheet (refresh/deep link) shows saved reasons. Only
        // seed when the controller is fresh (empty) AND the bloc has no
        // in-flight edit for that user — otherwise a remount would clobber
        // text the user is typing.
        for (final draft in loaded.drafts) {
          final controller = _reasonControllerFor(draft.userId);
          if (controller.text.isEmpty && draft.trimmedRemarks != null) {
            controller.text = draft.trimmedRemarks!;
          }
        }

        return AppResponsiveSheet(
          routeIdentity: routeId,
          title: title,
          mode: AppResponsiveSheetMode.form,
          isDirty: loaded.isDirty,
          isBusy: loaded.isSubmitting,
          onDismissApproved: _handleClose,
          body: _buildBody(context, loaded),
          footer: _buildFooter(context, loaded),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AttendanceFormLoaded state) {
    if (state.drafts.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return AppStatePanel(
        title: l10n.attendanceEmptyRosterTitle,
        message: l10n.attendanceEmptyRosterBody,
        icon: LucideIcons.users,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderRow(context, state),
        const SizedBox(height: 16),
        if (state.validationError != null) ...[
          FAlert(
            variant: FAlertVariant.destructive,
            title: Text(state.validationError!),
          ),
          const SizedBox(height: 12),
        ],
        if (state.saveError != null) ...[
          FAlert(
            variant: FAlertVariant.destructive,
            title: Text(state.saveError!),
          ),
          const SizedBox(height: 12),
        ],
        for (final draft in state.drafts)
          AttendanceCrewCard(
            key: ValueKey('attendance-draft-${draft.userId}'),
            draft: draft,
            syncState: state.syncStates[draft.userId],
            reasonController: _reasonControllerFor(draft.userId),
            reasonFocusNode: _reasonFocusNodeFor(draft.userId),
            onStatusSelected: (status) => _selectStatus(draft, status),
            onRemarksChanged: (remarks, {clear = false}) =>
                _changeRemarks(draft, remarks, clear: clear),
            onRetrySync:
                state.syncStates[draft.userId] == AttendanceSyncState.failed
                ? () => _retrySync(draft)
                : null,
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// One responsive header row (spec §4.4 item 2): date left, bulk action
  /// right; wraps on narrow widths while preserving date-first order and
  /// 48dp targets.
  Widget _buildHeaderRow(BuildContext context, AttendanceFormLoaded state) {
    final l10n = AppLocalizations.of(context);
    final formattedDate = _dateFormat.format(state.date);
    final hasUnset = state.drafts.any((draft) => draft.isUnset);

    return Semantics(
      label: l10n.attendanceHeaderSemantics,
      container: true,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200),
            child: FButton(
              variant: FButtonVariant.outline,
              onPress: () async {
                final picked = await AppCalendarDialog.showSingle(
                  context,
                  initialDate: state.date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null && context.mounted) {
                  _changeDate(picked);
                }
              },
              prefix: const Icon(LucideIcons.calendarDays),
              child: Text(formattedDate),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200),
            child: FButton(
              variant: FButtonVariant.secondary,
              onPress: hasUnset
                  ? () => context.read<AttendanceFormBloc>().add(
                      const AttendanceFormBulkMarkPresent(),
                    )
                  : null,
              prefix: const Icon(LucideIcons.checkCheck),
              child: Text(l10n.attendanceBulkMarkPresent),
            ),
          ),
        ],
      ),
    );
  }

  void _selectStatus(AttendanceCrewDraft draft, AttendanceStatus status) async {
    final bloc = context.read<AttendanceFormBloc>();

    // Changing Izin/Sakit → Alpa/Masuk with a non-empty reason requires
    // confirmation before the reason is discarded (spec §4.4 item 5).
    final currentDraft = draft;
    final reasonLingers =
        currentDraft.trimmedRemarks != null &&
        status != AttendanceStatus.leave &&
        status != AttendanceStatus.sick;

    if (reasonLingers) {
      final discard = await _confirmDiscardReason(context, currentDraft);
      if (discard == null || !discard) return;
      if (!mounted) return;
      // The confirmation is a promise to remove the reason: clear the owned
      // controller AND dispatch an explicit remarks clear so a stale reason
      // cannot be saved against the now-reasonless status (spec §4.4 item 5).
      _reasonControllerFor(currentDraft.userId).clear();
      bloc.add(
        AttendanceFormRemarksChanged(userId: currentDraft.userId, clear: true),
      );
    }

    bloc.add(
      AttendanceFormStatusSelected(userId: currentDraft.userId, status: status),
    );
  }

  Future<bool?> _confirmDiscardReason(
    BuildContext context,
    AttendanceCrewDraft draft,
  ) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.attendanceDiscardReasonTitle),
        content: Text(
          l10n.attendanceDiscardReasonBody(draft.trimmedRemarks ?? ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: FTheme.of(dialogContext).colors.destructive,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.attendanceDiscardReasonConfirm),
          ),
        ],
      ),
    );
  }

  void _changeRemarks(
    AttendanceCrewDraft draft,
    String? remarks, {
    bool clear = false,
  }) {
    context.read<AttendanceFormBloc>().add(
      AttendanceFormRemarksChanged(
        userId: draft.userId,
        remarks: remarks,
        clear: clear,
      ),
    );
  }

  /// Per-record sync retry (spec §4.4 item 6): a failed card's labelled
  /// `Coba lagi` re-enqueues only that record's queue item.
  void _retrySync(AttendanceCrewDraft draft) {
    final recordId = draft.existingRecord?.id;
    if (recordId == null) return;
    context.read<AttendanceFormBloc>().add(
      AttendanceFormRetrySyncRequested(recordId: recordId),
    );
  }

  /// Focus and scroll to the first invalid row (spec §4.4 item 8).
  void _focusFirstInvalid(String userId) {
    final node = _reasonFocusNodeFor(userId);
    node.requestFocus();
    final targetContext = context;
    Scrollable.ensureVisible(
      targetContext,
      alignment: 0.2,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// Save footer (spec §4.4 item 8): `Simpan Absensi (N Kru)`, reachable
  /// above the IME, disabled only during submission.
  Widget _buildFooter(BuildContext context, AttendanceFormLoaded state) {
    final theme = FTheme.of(context);
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: FButton(
        key: const Key('save_attendance_batch_button'),
        onPress: state.isSubmitting ? null : _saveBatch,
        prefix: state.isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: FCircularProgress(
                  size: .sm,
                  style: .delta(
                    iconStyle: .delta(color: theme.colors.primaryForeground),
                  ),
                ),
              )
            : const Icon(LucideIcons.save),
        child: Text(
          state.isSubmitting
              ? l10n.attendanceSaving
              : l10n.attendanceSaveCount(state.crewCount),
        ),
      ),
    );
  }
}
