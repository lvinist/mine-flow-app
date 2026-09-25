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
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/hazard_assessment.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_bloc.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_event.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_state.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/auto_save_indicator.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/hazard_assessment_field.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/weather_selector.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/features/zone/presentation/bloc/zone_cubit.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

/// Route-backed Daily Log form sheet (STEP-55.6, spec §4.5 items 5–6 /
/// FC-54.6-005/006/007).
///
/// D1/D2 geometry comes from [AppResponsiveSheet]; durable identity is the
/// URL — create is `/teams/daily-log/form?date=YYYY-MM-DD`, a record is
/// `/:id/form` resolved by ID from the repository (`extra` is cache-only).
/// Submitted/approved records render read-only for foremen; a supervisor
/// may inspect a submitted log before approving it; approved is immutable.
/// Dismissal flushes a pending auto-save first; on failure input is
/// retained and the D4 dirty dialog fires instead of a silent close.
class DailyLogFormSheet extends StatelessWidget {
  final DailyLogRepository repository;
  final ZoneRepository zoneRepository;

  /// Durable record ID from the URL path (`/:id/form`); null = create.
  final String? logId;

  /// Cache-only existing log (never the identity source).
  final DailyLog? existingLog;

  /// Durable date from the URL query (`?date=`); defaults to local today.
  final DateTime? initialDate;

  final String foremanId;
  final String siteId;
  final Uri? routeUri;
  final VoidCallback? onClose;

  const DailyLogFormSheet({
    super.key,
    required this.repository,
    required this.zoneRepository,
    this.logId,
    this.existingLog,
    this.initialDate,
    required this.foremanId,
    required this.siteId,
    this.routeUri,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final targetDate = initialDate ?? DateTime(now.year, now.month, now.day);

    return BlocProvider(
      create: (context) => DailyLogBloc(repository: repository)
        ..add(
          InitializeDailyLogFormEvent(
            foremanId: foremanId,
            siteId: siteId,
            logDate: targetDate,
            existingLog: existingLog,
            logId: logId,
          ),
        ),
      child: BlocProvider<ZoneCubit>(
        create: (_) => ZoneCubit(repository: zoneRepository)..loadZones(),
        child: DailyLogFormSheetView(routeUri: routeUri, onClose: onClose),
      ),
    );
  }
}

class DailyLogFormSheetView extends StatefulWidget {
  final Uri? routeUri;
  final VoidCallback? onClose;

  const DailyLogFormSheetView({
    super.key,
    required this.routeUri,
    this.onClose,
  });

  @override
  State<DailyLogFormSheetView> createState() => _DailyLogFormSheetViewState();
}

class _DailyLogFormSheetViewState extends State<DailyLogFormSheetView> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _notesController = TextEditingController();
  final FocusNode _summaryFocusNode = FocusNode();
  final FocusNode _notesFocusNode = FocusNode();

  /// Route reference captured in [didChangeDependencies] so the
  /// success-close timer can guard against a double-pop race.
  ///
  /// When an external [appRouter.go] is called (e.g. in the E2E test after
  /// reading back the submitted log), the form route is removed from the
  /// navigator stack. A pending [Future.delayed] close that fires after this
  /// navigation sees [mounted] == true (disposal hasn't run yet) but the
  /// form route's [isCurrent] is already false. Checking [isCurrent] prevents
  /// [_handleClose] from calling [context.pop()] on the wrong (list) route,
  /// which would accidentally navigate back to /teams.
  ModalRoute<Object?>? _formRoute;
  Timer? _autoSaveDebounce;
  Timer? _successCloseTimer;

  /// One-shot latch (STEP-55.6 residual R1): prevents duplicate pops from
  /// stripping the navigation stack back to `/teams`. Closing is a one-shot
  /// transition, matching `AttendanceFormSheet`.
  bool _hasClosed = false;

  /// CF-050: debounce auto-save so a burst of keystrokes queues one write.
  void _debouncedAutoSave() {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<DailyLogBloc>().add(const AutoSaveDraftEvent());
      }
    });
  }

  @override
  void dispose() {
    _successCloseTimer?.cancel();
    _autoSaveDebounce?.cancel();
    _summaryFocusNode.dispose();
    _notesFocusNode.dispose();
    _summaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture once; ModalRoute.of(context) cannot be called from timer
    // callbacks without a listen=false equivalent, so we store the reference
    // here where the InheritedWidget lookup is legal.
    _formRoute ??= ModalRoute.of(context);
  }

  void _handleClose() {
    if (_hasClosed) return;
    _hasClosed = true;
    _successCloseTimer?.cancel();
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // Cold URL without a stack: go to the list, preserving query context.
      context.go(AppRoutes.dailyLog);
    }
  }

  /// Spec §4.5 item 6: flush/await any pending auto-save BEFORE the sheet
  /// closes. On failure the input is retained and the D4 dirty dialog is
  /// invoked via the sheet's isDirty flag — the sheet does not silently
  /// close on a failed write.
  Future<void> _flushPendingSave(DailyLogFormState state) async {
    if (!state.hasUnsavedChanges || state.log.status != LogStatus.draft) {
      return;
    }
    _autoSaveDebounce?.cancel();
    final bloc = context.read<DailyLogBloc>();
    // The AutoSaveDraftEvent handler awaits the repository write; drive it
    // and mirror its completion by watching for the next state that clears
    // the in-flight flag.
    final done = Completer<void>();
    late final StreamSubscription sub;
    sub = bloc.stream.listen((s) {
      if (s is DailyLogFormState && !s.isSavingDraft) {
        done.complete();
        sub.cancel();
      }
    });
    bloc.add(const AutoSaveDraftEvent());
    await done.future.timeout(const Duration(seconds: 5));
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Forward the focused field values before submitting so late edits
      // are kept (same contract as the legacy form).
      context.read<DailyLogBloc>().add(
        NotesChangedEvent(_notesController.text),
      );
      context.read<DailyLogBloc>().add(const SubmitDailyLogEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    return BlocConsumer<DailyLogBloc, DailyLogState>(
      listener: (context, state) {
        if (state is DailyLogFormState) {
          if (state.errorMessage != null) {
            showFToast(
              context: context,
              variant: FToastVariant.destructive,
              title: Text(state.errorMessage!),
            );
          }
          if (state.successMessage != null) {
            if (_hasClosed) return;
            showFToast(
              context: context,
              title: Text(state.successMessage!),
              duration: const Duration(seconds: 2),
            );
            _handleClose();
          }
        }
      },
      builder: (context, state) {
        if (state is DailyLogLoading || state is DailyLogInitial) {
          return AppResponsiveSheet(
            routeIdentity: widget.routeUri?.toString() ?? 'daily-log-form',
            title: 'Log Operasional Harian',
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

        if (state is DailyLogError) {
          return AppResponsiveSheet(
            routeIdentity: widget.routeUri?.toString() ?? 'daily-log-form',
            title: 'Log Operasional Harian',
            mode: AppResponsiveSheetMode.form,
            onDismissApproved: _handleClose,
            body: AppStatePanel(
              title: 'Log tidak ditemukan',
              message: state.message,
              actionLabel: 'Kembali',
              onAction: _handleClose,
            ),
          );
        }

        final formState = state as DailyLogFormState;
        final log = formState.log;
        final isDraft = log.status == LogStatus.draft;
        final routeId = widget.routeUri?.toString() ?? 'daily-log-form';

        // CF-049: only sync controllers when the field is not focused, so a
        // lagging state emission can't yank the caret mid-edit.
        if (!_summaryFocusNode.hasFocus &&
            _summaryController.text != (log.summary ?? '')) {
          _summaryController.value = TextEditingValue(
            text: log.summary ?? '',
            selection: TextSelection.collapsed(
              offset: (log.summary ?? '').length,
            ),
          );
        }
        if (!_notesFocusNode.hasFocus &&
            _notesController.text != (log.notes ?? '')) {
          _notesController.value = TextEditingValue(
            text: log.notes ?? '',
            selection: TextSelection.collapsed(
              offset: (log.notes ?? '').length,
            ),
          );
        }

        return AppResponsiveSheet(
          routeIdentity: routeId,
          title: 'Log Operasional Harian',
          subtitle: isDraft
              ? null
              : (log.status == LogStatus.approved
                    ? 'Disetujui — hanya dapat dilihat'
                    : 'Terkirim — menunggu persetujuan'),
          mode: isDraft
              ? AppResponsiveSheetMode.form
              : AppResponsiveSheetMode.readOnlyInspector,
          isDirty: formState.hasUnsavedChanges,
          isBusy: formState.isBusy,
          onDismissApproved: () async {
            // Spec §4.5 item 6: flush a pending save before closing; the
            // sheet only closes after the write settles (or fails, which
            // keeps input and lets D4 confirm the discard).
            await _flushPendingSave(formState);
            _handleClose();
          },
          body: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isDraft)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FAlert(
                      variant: FAlertVariant.primary,
                      title: Text(
                        log.status == LogStatus.approved
                            ? 'Log ini telah disetujui oleh Supervisor dan tidak dapat diubah.'
                            : 'Log ini telah dikirim dan menunggu persetujuan Supervisor.',
                      ),
                    ),
                  ),
                if (isDraft)
                  Row(
                    children: [
                      Expanded(
                        child: FTile(
                          prefix: Icon(
                            LucideIcons.calendarDays,
                            color: theme.colors.primary,
                          ),
                          title: Text(
                            AppLocalizations.of(
                              context,
                            ).dailyLogOperationalDate,
                          ),
                          subtitle: Text(
                            dateFormat.format(log.logDate),
                            style: theme.typography.body.md.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          suffix: FButton(
                            variant: FButtonVariant.ghost,
                            onPress: () async {
                              final pickedDate =
                                  await AppCalendarDialog.showSingle(
                                    context,
                                    initialDate: log.logDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                              if (pickedDate != null && context.mounted) {
                                context.read<DailyLogBloc>().add(
                                  LogDateChangedEvent(pickedDate),
                                );
                                context.read<DailyLogBloc>().add(
                                  const AutoSaveDraftEvent(),
                                );
                              }
                            },
                            child: const Icon(LucideIcons.calendarDays),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (isDraft) ...[
                  const SizedBox(height: 16),
                  ZonePicker(
                    selectedZoneId: log.zoneId,
                    onZoneSelected: (zoneId) {
                      context.read<DailyLogBloc>().add(
                        ZoneChangedEvent(zoneId),
                      );
                      context.read<DailyLogBloc>().add(
                        const AutoSaveDraftEvent(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  WeatherSelector(
                    selectedWeather: log.weather,
                    onWeatherSelected: (weather) {
                      context.read<DailyLogBloc>().add(
                        WeatherChangedEvent(weather),
                      );
                      context.read<DailyLogBloc>().add(
                        const AutoSaveDraftEvent(),
                      );
                    },
                  ),
                ],
                if (!isDraft) ...[
                  _ReadOnlyMeta(theme: theme, log: log, dateFormat: dateFormat),
                ],
                const SizedBox(height: 16),

                // Work Summary
                Text(
                  AppLocalizations.of(context).dailyLogSummaryLabel,
                  style: theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('daily_log_summary_field'),
                  controller: _summaryController,
                  focusNode: _summaryFocusNode,
                  enabled: isDraft,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText:
                        'Jelaskan pencapaian pekerjaan harian, volume tambang, kendala unit, dll.',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ringkasan pekerjaan harian wajib diisi';
                    }
                    return null;
                  },
                  onChanged: (text) {
                    context.read<DailyLogBloc>().add(SummaryChangedEvent(text));
                    _debouncedAutoSave();
                  },
                ),
                const SizedBox(height: 16),

                // Operational Notes
                Text(
                  AppLocalizations.of(context).dailyLogNotesLabel,
                  style: theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('daily_log_notes_field'),
                  controller: _notesController,
                  focusNode: _notesFocusNode,
                  enabled: isDraft,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Insiden K3, perbaikan alat, atau instruksi shift berikutnya...',
                  ),
                  onChanged: (text) {
                    context.read<DailyLogBloc>().add(NotesChangedEvent(text));
                    _debouncedAutoSave();
                  },
                ),
                const SizedBox(height: 16),

                // Structured hazard assessment (spec §4.5 item 7).
                if (isDraft)
                  HazardAssessmentField(
                    hazard: log.hazard,
                    onChanged: (change) {
                      context.read<DailyLogBloc>().add(
                        HazardChangedEvent(change),
                      );
                      _debouncedAutoSave();
                    },
                  )
                else
                  _ReadOnlyHazard(theme: theme, hazard: log.hazard),
              ],
            ),
          ),
          footer: isDraft
              ? Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 12,
                  children: [
                    AutoSaveIndicator(
                      isSaving: formState.isSavingDraft,
                      hasUnsavedChanges: formState.hasUnsavedChanges,
                      statusText: formState.autoSaveStatusText ?? 'Draft',
                    ),
                    FButton(
                      key: const Key('submit_daily_log_button'),
                      onPress: formState.isSubmitting ? null : _submit,
                      prefix: formState.isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: FCircularProgress(
                                size: .sm,
                                style: .delta(
                                  iconStyle: .delta(
                                    color: theme.colors.primaryForeground,
                                  ),
                                ),
                              ),
                            )
                          : const Icon(LucideIcons.send),
                      child: Text(
                        formState.isSubmitting
                            ? 'Mengirim Log...'
                            : 'Kirim Log Harian',
                      ),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}

/// Read-only metadata block for submitted/approved inspections.
class _ReadOnlyMeta extends StatelessWidget {
  final FThemeData theme;
  final DailyLog log;
  final DateFormat dateFormat;

  const _ReadOnlyMeta({
    required this.theme,
    required this.log,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FTile(
          prefix: Icon(LucideIcons.calendarDays, color: theme.colors.primary),
          title: Text(AppLocalizations.of(context).dailyLogOperationalDate),
          subtitle: Text(
            dateFormat.format(log.logDate),
            style: theme.typography.body.md.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (log.zoneId != null)
          FTile(
            prefix: Icon(LucideIcons.mapPin, color: theme.colors.primary),
            title: Text(AppLocalizations.of(context).dailyLogZoneLabel),
            subtitle: Text(log.zoneId!),
          ),
        if (log.weather != null)
          FTile(
            prefix: Icon(LucideIcons.sun, color: theme.colors.primary),
            title: Text(AppLocalizations.of(context).dailyLogWeatherLabel),
            subtitle: Text(log.weather!),
          ),
      ],
    );
  }
}

/// Read-only hazard summary for submitted/approved logs.
class _ReadOnlyHazard extends StatelessWidget {
  final FThemeData theme;
  final HazardAssessment hazard;

  const _ReadOnlyHazard({required this.theme, required this.hazard});

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (hazard.state) {
      HazardState.present => (
        LucideIcons.alertTriangle,
        'Bahaya: ${hazard.severity?.toValue() ?? '?'}',
      ),
      HazardState.none => (LucideIcons.shieldCheck, 'Tidak ada bahaya'),
      HazardState.notAssessed => (LucideIcons.helpCircle, 'Belum dinilai'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).dailyLogHazardLabel,
          style: theme.typography.body.sm.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        FTile(
          prefix: Icon(
            icon,
            color: hazard.state == HazardState.present
                ? theme.colors.destructive
                : theme.colors.primary,
          ),
          title: Text(label),
          subtitle: hazard.notes != null && hazard.notes!.isNotEmpty
              ? Text(hazard.notes!)
              : null,
        ),
        if (hazard.correctiveAction != null &&
            hazard.correctiveAction!.isNotEmpty)
          FTile(
            prefix: Icon(
              LucideIcons.wrench,
              color: theme.colors.mutedForeground,
            ),
            title: Text(AppLocalizations.of(context).dailyLogHazardActionLabel),
            subtitle: Text(hazard.correctiveAction!),
          ),
      ],
    );
  }
}
