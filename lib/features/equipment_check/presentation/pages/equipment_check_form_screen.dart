import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';
import 'package:mine_flow/features/equipment_check/domain/repositories/equipment_check_repository.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_bloc.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_event.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_state.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/check_type_toggle.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/condition_summary_badge.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/equipment_type_tabs.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/sop_checklist_item_card.dart';

/// Screen for completing digital SOP pre-work and post-work equipment condition checks.
///
/// Migrated in STEP-55.7 (FC-54.7-003):
/// - Replaced Scaffold/AppBar with route-backed [AppResponsiveSheet].
/// - Enforces universal dirty guard (D4) so dismiss/back doesn't lose unsaved changes.
/// - Validates authorized site context; foreman identity derived from auth session, never URL.
/// - One clear scroll owner managed by [AppResponsiveSheet].
/// - Persistent footer submit action with safe areas / IME handling.
class EquipmentCheckFormScreen extends StatelessWidget {
  final EquipmentCheckRepository repository;
  final String siteId;
  final String foremanId;
  final EquipmentType initialEquipmentType;
  final CheckType initialCheckType;
  final Uri? routeUri;
  final VoidCallback? onSubmitSuccess;
  final VoidCallback? onClose;
  final bool Function(String siteId)? siteAuthorizationGuard;

  const EquipmentCheckFormScreen({
    super.key,
    required this.repository,
    required this.siteId,
    required this.foremanId,
    this.initialEquipmentType = EquipmentType.gnss,
    this.initialCheckType = CheckType.preWork,
    this.routeUri,
    this.onSubmitSuccess,
    this.onClose,
    this.siteAuthorizationGuard,
  });

  /// Resolves the session user id through the widget tree first.
  ///
  /// STEP-55.7 RESIDUAL (2026-09-21): the form route sits below
  /// `MineFlowApp`'s root `BlocProvider<AuthCubit>`. Falls back to the
  /// process-wide global only when pumped outside the app root.
  String? _resolveSessionUserId(BuildContext context) {
    try {
      return context.read<AuthCubit>().state.user?.id;
    } catch (_) {
      return currentUserId();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Authenticated foreman identity must not come from the URL.
    // The tree-resolved session wins over the explicit parameter, mirroring
    // the pre-residual behavior where the global session won.
    final sessionUserId = _resolveSessionUserId(context);
    final effectiveForemanId = sessionUserId?.isNotEmpty == true
        ? sessionUserId!
        : (foremanId.isNotEmpty ? foremanId : (sessionUserId ?? ''));

    final isAuthorized = (siteAuthorizationGuard ?? isAuthorizedSite)(siteId);

    return BlocProvider(
      create: (context) {
        final bloc = EquipmentCheckBloc(repository: repository);
        if (isAuthorized) {
          bloc.add(
            LoadEquipmentCheckEvent(
              siteId: siteId,
              foremanId: effectiveForemanId,
              equipmentType: initialEquipmentType,
              checkType: initialCheckType,
            ),
          );
        }
        return bloc;
      },
      child: EquipmentCheckFormView(
        siteId: siteId,
        routeUri: routeUri,
        onSubmitSuccess: onSubmitSuccess,
        onClose: onClose,
        siteAuthorizationGuard: siteAuthorizationGuard,
      ),
    );
  }
}

class EquipmentCheckFormView extends StatefulWidget {
  final String siteId;
  final Uri? routeUri;
  final VoidCallback? onSubmitSuccess;
  final VoidCallback? onClose;
  final bool Function(String siteId)? siteAuthorizationGuard;

  const EquipmentCheckFormView({
    super.key,
    required this.siteId,
    this.routeUri,
    this.onSubmitSuccess,
    this.onClose,
    this.siteAuthorizationGuard,
  });

  @override
  State<EquipmentCheckFormView> createState() => _EquipmentCheckFormViewState();
}

class _EquipmentCheckFormViewState extends State<EquipmentCheckFormView> {
  late final TextEditingController _serialNumberController;
  late final TextEditingController _remarksController;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _serialNumberController = TextEditingController();
    _remarksController = TextEditingController();
    _serialNumberController.addListener(_onSerialChanged);
    _remarksController.addListener(_onRemarksChanged);
  }

  void _onSerialChanged() {
    setState(() {
      if (_serialNumberController.text.isNotEmpty) {
        _isDirty = true;
      }
    });
    context.read<EquipmentCheckBloc>().add(
      UpdateSerialNumberEvent(_serialNumberController.text),
    );
  }

  void _onRemarksChanged() {
    setState(() {
      if (_remarksController.text.isNotEmpty) {
        _isDirty = true;
      }
    });
    context.read<EquipmentCheckBloc>().add(
      UpdateRemarksEvent(_remarksController.text),
    );
  }

  void _handleClose(BuildContext context) {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return;
      }
    } catch (_) {}
    try {
      if (context.canPop()) {
        context.pop();
        return;
      }
      context.go(AppRoutes.equipmentCheck);
    } catch (_) {}
  }

  @override
  void dispose() {
    _serialNumberController.removeListener(_onSerialChanged);
    _remarksController.removeListener(_onRemarksChanged);
    _serialNumberController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final routeIdentity = widget.routeUri?.toString() ?? 'equipment-check-form';

    // Site context authorization check (FC-54.7-003)
    final isAuthorized = (widget.siteAuthorizationGuard ?? isAuthorizedSite)(
      widget.siteId,
    );

    if (!isAuthorized) {
      return AppResponsiveSheet(
        routeIdentity: routeIdentity,
        title: 'Inspeksi SOP Peralatan',
        mode: AppResponsiveSheetMode.form,
        onDismissApproved: () => _handleClose(context),
        body: AppStatePanel(
          title: 'Akses Ditolak',
          message: 'Lokasi kerja tidak valid atau Anda tidak memiliki akses.',
          actionLabel: 'Kembali ke daftar',
          onAction: () => _handleClose(context),
        ),
      );
    }

    return BlocConsumer<EquipmentCheckBloc, EquipmentCheckState>(
      listener: (context, state) {
        if (state is EquipmentCheckSubmitted) {
          showFToast(context: context, title: Text(state.message));
          setState(() => _isDirty = false);
          if (widget.onSubmitSuccess != null) {
            widget.onSubmitSuccess!();
          } else {
            _handleClose(context);
          }
        } else if (state is EquipmentCheckError) {
          showFToast(
            context: context,
            variant: FToastVariant.destructive,
            title: Text(state.message),
          );
        }
      },
      builder: (context, state) {
        if (state is EquipmentCheckLoading || state is EquipmentCheckInitial) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: 'Inspeksi SOP Peralatan',
            mode: AppResponsiveSheetMode.form,
            onDismissApproved: () => _handleClose(context),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: FCircularProgress(),
              ),
            ),
          );
        }

        final loadedState = state is EquipmentCheckLoaded
            ? state
            : (state is EquipmentCheckSubmitted
                  ? EquipmentCheckLoaded(
                      siteId: state.check.siteId,
                      foremanId: state.check.foremanId,
                      equipmentType: state.check.equipmentType,
                      checkType: state.check.checkType,
                      serialNumber: state.check.serialNumber ?? '',
                      checkTime: state.check.checkTime,
                      checklist: state.check.checklist,
                      remarks: state.check.remarks ?? '',
                    )
                  : null);

        if (loadedState == null) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: 'Inspeksi SOP Peralatan',
            mode: AppResponsiveSheetMode.form,
            onDismissApproved: () => _handleClose(context),
            body: AppStatePanel(
              title: 'Gagal Memuat',
              message: 'Gagal memuat formulir SOP peralatan.',
              actionLabel: 'Kembali ke daftar',
              onAction: () => _handleClose(context),
            ),
          );
        }

        final bloc = context.read<EquipmentCheckBloc>();

        return AppResponsiveSheet(
          routeIdentity: routeIdentity,
          title: 'Inspeksi SOP Peralatan',
          subtitle: 'Pemeriksaan kondisi alat',
          mode: AppResponsiveSheetMode.form,
          isDirty: _isDirty,
          isBusy: loadedState.isSubmitting,
          onDiscard: () {
            setState(() => _isDirty = false);
          },
          onDismissApproved: () => _handleClose(context),
          footer: SizedBox(
            width: double.infinity,
            height: 48,
            child: FButton(
              // CF-017 + CF-039: disabled until every SOP item has an
              // explicit verdict and a serial number is entered.
              onPress:
                  (loadedState.isSubmitting ||
                      !loadedState.isComplete ||
                      _serialNumberController.text.trim().isEmpty)
                  ? null
                  : () => bloc.add(const SubmitEquipmentCheckEvent()),
              child: loadedState.isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: FCircularProgress(
                        size: .sm,
                        style: .delta(
                          iconStyle: .delta(
                            color: theme.colors.primaryForeground,
                          ),
                        ),
                      ),
                    )
                  : Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          loadedState.unansweredCount > 0
                              ? 'Jawab semua item SOP (${loadedState.totalCount - loadedState.unansweredCount}/${loadedState.totalCount})'
                              : 'Simpan Inspeksi SOP (${loadedState.passedCount}/${loadedState.totalCount} Lolos)',
                          maxLines: 1,
                        ),
                      ),
                    ),
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Equipment Type Selector Tabs
              EquipmentTypeTabs(
                selectedType: loadedState.equipmentType,
                onTypeSelected: (type) {
                  setState(() => _isDirty = true);
                  bloc.add(SelectEquipmentTypeEvent(type));
                },
              ),
              const SizedBox(height: 16),

              // Check Type (Pre-work vs Post-work) Toggle
              CheckTypeToggle(
                selectedCheckType: loadedState.checkType,
                onCheckTypeChanged: (checkType) {
                  setState(() => _isDirty = true);
                  bloc.add(SelectCheckTypeEvent(checkType));
                },
              ),
              const SizedBox(height: 16),

              // Equipment Serial Number Field
              FTextField(
                control: FTextFieldControl.managed(
                  controller: _serialNumberController,
                ),
                label: const Text('Nomor Seri Alat / ID Unit'),
                hint: 'Misal: Trimble-GNSS-8891 / TS-Leica-02',
              ),
              const SizedBox(height: 16),

              // Operational Condition Summary Badge
              ConditionSummaryBadge(
                status: loadedState.overallStatus,
                isOperational: loadedState.isOperational,
                passedCount: loadedState.passedCount,
                totalCount: loadedState.totalCount,
              ),
              const SizedBox(height: 20),

              // Section Header: SOP Checklist Items
              Text(
                'DAFTAR CEK KELAYAKAN SOP',
                style: theme.typography.body.xs.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colors.primary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              // Checklist Item Cards (One clear scroll owner: AppResponsiveSheet body)
              ...loadedState.checklist.map(
                (item) => SopChecklistItemCard(
                  key: ValueKey(item.id),
                  item: item,
                  onToggle: (isPassed, remarks) {
                    setState(() => _isDirty = true);
                    bloc.add(
                      ToggleCheckItemEvent(
                        itemId: item.id,
                        isPassed: isPassed,
                        remarks: remarks,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Overall Inspection Notes / Remarks
              FTextField(
                control: FTextFieldControl.managed(
                  controller: _remarksController,
                ),
                maxLines: 2,
                label: const Text('Catatan Tambahan Inspeksi'),
                hint: 'Misal: Cuaca berawan, lokasi sektor pit A2',
              ),
            ],
          ),
        );
      },
    );
  }
}
