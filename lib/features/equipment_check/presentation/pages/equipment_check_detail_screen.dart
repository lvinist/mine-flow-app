import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/core/presentation/widgets/card_meta_wrap.dart';
import 'package:mine_flow/core/presentation/widgets/confirm_destructive_action.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_item.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';
import 'package:mine_flow/features/equipment_check/domain/repositories/equipment_check_repository.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_bloc.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_event.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_state.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

/// Screen displaying the inspection details of a single equipment check record.
///
/// Implements STEP-55.7 (FC-54.7-001):
/// - Replaces inline [ExpansionTile] with a route-backed inspection detail (/teams/equipment-check/:id).
/// - Responsive geometry via [AppResponsiveSheet]: Web right inspector (480–600dp),
///   Android/mobile route-backed full page ([mobileFullPage: true]).
/// - Shows all checklist results (15–30 items), defect remarks, metadata,
///   inspector ID, timestamp, and delete action.
class EquipmentCheckDetailScreen extends StatelessWidget {
  final EquipmentCheckRepository repository;
  final String checkId;
  final EquipmentCheck? existingCheck;
  final Uri? routeUri;
  final VoidCallback? onClose;
  final bool Function(String siteId)? siteAuthorizationGuard;

  const EquipmentCheckDetailScreen({
    super.key,
    required this.repository,
    required this.checkId,
    this.existingCheck,
    this.routeUri,
    this.onClose,
    this.siteAuthorizationGuard,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = EquipmentCheckBloc(repository: repository);
        bloc.add(LoadEquipmentCheckByIdEvent(checkId));
        return bloc;
      },
      child: EquipmentCheckDetailView(
        checkId: checkId,
        existingCheck: existingCheck,
        routeUri: routeUri,
        onClose: onClose,
        siteAuthorizationGuard: siteAuthorizationGuard,
      ),
    );
  }
}

class EquipmentCheckDetailView extends StatelessWidget {
  final String checkId;
  final EquipmentCheck? existingCheck;
  final Uri? routeUri;
  final VoidCallback? onClose;
  final bool Function(String siteId)? siteAuthorizationGuard;

  const EquipmentCheckDetailView({
    super.key,
    required this.checkId,
    this.existingCheck,
    this.routeUri,
    this.onClose,
    this.siteAuthorizationGuard,
  });

  void _handleClose(BuildContext context) {
    if (onClose != null) {
      onClose!();
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

  IconData _getEquipmentIcon(EquipmentType type) {
    switch (type) {
      case EquipmentType.gnss:
        return LucideIcons.locateFixed;
      case EquipmentType.totalStation:
        return LucideIcons.landmark;
      case EquipmentType.drone:
        return LucideIcons.plane;
    }
  }

  void _safeShowToast(
    BuildContext context,
    String message, {
    bool isDestructive = false,
  }) {
    try {
      showFToast(
        context: context,
        variant: isDestructive
            ? FToastVariant.destructive
            : FToastVariant.primary,
        title: Text(message),
      );
    } catch (_) {
      // Graceful fallback when FToaster is not in test context
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final routeIdentity = routeUri?.toString() ?? 'equipment-check-detail';

    return BlocConsumer<EquipmentCheckBloc, EquipmentCheckState>(
      listener: (context, state) {
        if (state is EquipmentHistoryLoaded) {
          _safeShowToast(context, 'Catatan pemeriksaan berhasil dihapus.');
          _handleClose(context);
        } else if (state is EquipmentCheckError) {
          _safeShowToast(context, state.message, isDestructive: true);
        }
      },
      builder: (context, state) {
        if (state is EquipmentHistoryLoaded) {
          return const SizedBox.shrink();
        }

        if (state is EquipmentCheckLoading && existingCheck == null) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: l10n.equipmentCheckDetailTitle,
            mode: AppResponsiveSheetMode.readOnlyInspector,
            mobileFullPage: true,
            onDismissApproved: () => _handleClose(context),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: FCircularProgress(),
              ),
            ),
          );
        }

        if (state is EquipmentCheckError && existingCheck == null) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: l10n.equipmentCheckDetailTitle,
            mode: AppResponsiveSheetMode.readOnlyInspector,
            mobileFullPage: true,
            onDismissApproved: () => _handleClose(context),
            body: AppStatePanel(
              title: l10n.dataNotFound,
              message: state.message,
              actionLabel: l10n.equipmentCheckBack,
              onAction: () => _handleClose(context),
            ),
          );
        }

        final check = state is EquipmentCheckDetailLoaded
            ? state.check
            : existingCheck;

        if (check == null) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: l10n.equipmentCheckDetailTitle,
            mode: AppResponsiveSheetMode.readOnlyInspector,
            mobileFullPage: true,
            onDismissApproved: () => _handleClose(context),
            body: AppStatePanel(
              title: l10n.dataNotFound,
              message: l10n.equipmentCheckInvalidRecord,
              actionLabel: l10n.equipmentCheckBack,
              onAction: () => _handleClose(context),
            ),
          );
        }

        // Site context authorization check (FC-54.7-001, FC-54.7-003)
        final isAuthorized = (siteAuthorizationGuard ?? isAuthorizedSite)(
          check.siteId,
        );
        if (!isAuthorized) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: l10n.equipmentCheckDetailTitle,
            mode: AppResponsiveSheetMode.readOnlyInspector,
            mobileFullPage: true,
            onDismissApproved: () => _handleClose(context),
            body: AppStatePanel(
              title: l10n.equipmentCheckAccessDeniedTitle,
              message: l10n.equipmentCheckAccessDeniedMessage,
              actionLabel: l10n.equipmentCheckBack,
              onAction: () => _handleClose(context),
            ),
          );
        }

        final dateFormat = DateFormat('dd MMMM yyyy, HH:mm');
        final isPass = check.status == CheckStatus.passed;
        final statusColor = isPass
            ? theme.colors.secondary
            : theme.colors.destructive;
        final passedCount = check.checklist
            .where((item) => item.isPassed == true)
            .length;
        final failedCount = check.checklist
            .where((item) => item.isPassed == false)
            .length;
        final totalCount = check.checklist.length;

        final user = authCubit?.state.user;
        final isSupervisor = user?.isSupervisor ?? false;

        return AppResponsiveSheet(
          routeIdentity: routeIdentity,
          title: l10n.equipmentCheckDetailTitle,
          subtitle:
              '${check.equipmentType.displayName} • ${check.checkType.displayName}',
          mode: AppResponsiveSheetMode.readOnlyInspector,
          mobileFullPage: true,
          onDismissApproved: () => _handleClose(context),
          footer: isSupervisor
              ? SizedBox(
                  width: double.infinity,
                  child: FButton(
                    variant: FButtonVariant.destructive,
                    onPress: () async {
                      final confirmed = await confirmDestructiveAction(
                        context,
                        message: l10n.equipmentCheckDeleteConfirmMessage,
                      );
                      if (confirmed == true && context.mounted) {
                        context.read<EquipmentCheckBloc>().add(
                          DeleteEquipmentCheckEvent(
                            checkId: check.id,
                            siteId: check.siteId,
                          ),
                        );
                      }
                    },
                    prefix: const Icon(LucideIcons.trash2, size: 16),
                    child: Text(l10n.equipmentCheckDeleteRecord),
                  ),
                )
              : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header summary card
              FCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colors.muted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getEquipmentIcon(check.equipmentType),
                              color: theme.colors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  check.equipmentType.displayName,
                                  style: theme.typography.body.lg.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (check.serialNumber != null &&
                                    check.serialNumber!.isNotEmpty)
                                  Text(
                                    l10n.equipmentCheckSerialNumber(
                                      check.serialNumber!,
                                    ),
                                    style: theme.typography.body.sm.copyWith(
                                      color: theme.colors.mutedForeground,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Status Badge
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPass
                                    ? LucideIcons.checkCircle
                                    : LucideIcons.alertTriangle,
                                size: 16,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              AppStatusBadge(
                                label: check.status.displayName.toUpperCase(),
                                color: statusColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const FDivider(),
                      const SizedBox(height: 12),

                      // Metadata chips
                      CardMetaWrap(
                        spacing: 8,
                        children: [
                          CardMetaChip(
                            icon: Icon(
                              LucideIcons.user,
                              size: 14,
                              color: theme.colors.mutedForeground,
                            ),
                            label: Text(
                              l10n.equipmentCheckInspector(check.foremanId),
                              style: theme.typography.body.xs.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ),
                          CardMetaChip(
                            icon: Icon(
                              LucideIcons.clock,
                              size: 14,
                              color: theme.colors.mutedForeground,
                            ),
                            label: Text(
                              dateFormat.format(check.checkTime),
                              style: theme.typography.body.xs.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ),
                          CardMetaChip(
                            icon: Icon(
                              LucideIcons.mapPin,
                              size: 14,
                              color: theme.colors.mutedForeground,
                            ),
                            label: Text(
                              l10n.equipmentCheckSite(check.siteId),
                              style: theme.typography.body.xs.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ),
                          CardMetaChip(
                            icon: Icon(
                              LucideIcons.shieldCheck,
                              size: 14,
                              color: theme.colors.mutedForeground,
                            ),
                            label: Text(
                              check.isOperational
                                  ? 'Siap Operasi'
                                  : 'Perlu Perbaikan',
                              style: theme.typography.body.xs.copyWith(
                                color: check.isOperational
                                    ? theme.colors.secondary
                                    : theme.colors.destructive,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Checklist Section Header
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    l10n.equipmentCheckResultHeader,
                    style: theme.typography.body.xs.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    l10n.equipmentCheckResultSummary(
                      passedCount,
                      failedCount,
                      totalCount,
                    ),
                    style: theme.typography.body.xs.copyWith(
                      color: theme.colors.mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Checklist Item List
              ...check.checklist.map(
                (item) => _buildDetailItemCard(context, item),
              ),

              if (check.remarks != null &&
                  check.remarks!.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.equipmentCheckAdditionalRemarks,
                  style: theme.typography.body.xs.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                FCard(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.fileText,
                          size: 16,
                          color: theme.colors.mutedForeground,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            check.remarks!,
                            style: theme.typography.body.sm,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItemCard(BuildContext context, CheckItem item) {
    final theme = FTheme.of(context);
    final isPassed = item.isPassed == true;
    final isFailed = item.isPassed == false;
    final statusColor = isPassed
        ? theme.colors.secondary
        : (isFailed ? theme.colors.destructive : theme.colors.mutedForeground);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    isPassed
                        ? LucideIcons.checkCircle2
                        : (isFailed
                              ? LucideIcons.xCircle
                              : LucideIcons.helpCircle),
                    size: 18,
                    color: statusColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Labelled badge with dual icon + text (FC-54.7-002, FC-54.7-004)
                  AppStatusBadge(
                    label: isPassed ? 'PASS' : (isFailed ? 'FAIL' : 'UNTESTED'),
                    color: statusColor,
                  ),
                ],
              ),
              if (item.remarks != null && item.remarks!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colors.muted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        size: 14,
                        color: theme.colors.destructive,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.remarks!,
                          style: theme.typography.body.xs.copyWith(
                            color: theme.colors.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
