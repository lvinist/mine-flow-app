import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/core/presentation/widgets/confirm_destructive_action.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_state.dart';

/// Responsive modal sheet displaying details of a land clearing record.
class LandClearingInspectorScreen extends StatelessWidget {
  final TrackingRepository repository;
  final String recordId;
  final LandClearingRecord? existingRecord;
  final Uri? routeUri;
  final VoidCallback? onClose;

  const LandClearingInspectorScreen({
    super.key,
    required this.repository,
    required this.recordId,
    this.existingRecord,
    this.routeUri,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LandClearingBloc(repository: repository)
        ..add(
          InitializeLandClearingFormEvent(
            siteId:
                '', // not needed for viewing existing record if record is passed/loaded
            zoneId: '',
            foremanId: '',
            existingRecord: existingRecord,
            recordId: recordId,
          ),
        ),
      child: _LandClearingInspectorView(
        recordId: recordId,
        routeUri: routeUri,
        onClose: onClose,
      ),
    );
  }
}

class _LandClearingInspectorView extends StatelessWidget {
  final String recordId;
  final Uri? routeUri;
  final VoidCallback? onClose;

  const _LandClearingInspectorView({
    required this.recordId,
    this.routeUri,
    this.onClose,
  });

  void _handleClose(BuildContext context) {
    if (onClose != null) {
      onClose!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.landClearing);
    }
  }

  void _openEdit(BuildContext context, String tab, LandClearingRecord record) {
    final query = {'tab': tab, ...?routeUri?.queryParameters};
    context
        .pushNamed(
          'land-clearing-edit',
          pathParameters: {'id': recordId},
          queryParameters: query,
          extra: record,
        )
        .then((_) {
          if (context.mounted) {
            context.read<LandClearingBloc>().add(
              InitializeLandClearingFormEvent(
                siteId: '',
                zoneId: '',
                foremanId: '',
                existingRecord: record,
              ),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    return BlocBuilder<LandClearingBloc, LandClearingState>(
      builder: (context, state) {
        final routeIdentity = routeUri?.toString() ?? 'land-clearing-inspector';

        if (state is LandClearingLoading || state is LandClearingInitial) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: 'Detail Land Clearing',
            mode: AppResponsiveSheetMode.readOnlyInspector,
            onDismissApproved: () => _handleClose(context),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: FCircularProgress(),
              ),
            ),
          );
        }

        if (state is LandClearingError) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: 'Detail Land Clearing',
            mode: AppResponsiveSheetMode.readOnlyInspector,
            onDismissApproved: () => _handleClose(context),
            body: AppStatePanel(
              title: 'Data Tidak Ditemukan',
              message: state.message,
              actionLabel: 'Kembali',
              onAction: () => _handleClose(context),
            ),
          );
        }

        if (state is LandClearingFormState) {
          final record = state.record;

          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: 'Detail Land Clearing',
            subtitle: record.zoneId.isNotEmpty
                ? 'Zona: ${record.zoneId}'
                : null,
            mode: AppResponsiveSheetMode.readOnlyInspector,
            onDismissApproved: () => _handleClose(context),
            footer: SizedBox(
              width: double.infinity,
              child: FButton(
                variant: FButtonVariant.destructive,
                onPress: () async {
                  final proceed = await confirmDestructiveAction(
                    context,
                    message:
                        'Hapus data land clearing ini? Tindakan tidak dapat dibatalkan.',
                  );
                  if (proceed && context.mounted) {
                    context.read<LandClearingBloc>().add(
                      DeleteLandClearingRecordEvent(record.id),
                    );
                    _handleClose(context);
                  }
                },
                child: const Text('Hapus Data'),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(theme, dateFormat, record),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    theme: theme,
                    title: 'Rencana (Plan)',
                    icon: LucideIcons.ruler,
                    area: record.planArea,
                    onEdit: () => _openEdit(context, 'plan', record),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    theme: theme,
                    title: 'Realisasi (Actual)',
                    icon: LucideIcons.checkCircle,
                    area: record.actualArea,
                    notes: record.notes,
                    onEdit: () => _openEdit(context, 'actual', record),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeaderInfo(
    FThemeData theme,
    DateFormat dateFormat,
    LandClearingRecord record,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.calendarDays,
                size: 16,
                color: theme.colors.mutedForeground,
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(record.clearingDate),
                style: theme.typography.body.sm.copyWith(
                  color: theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
          if (record.method != null && record.method!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  LucideIcons.construction,
                  size: 16,
                  color: theme.colors.mutedForeground,
                ),
                const SizedBox(width: 8),
                Text(
                  record.method!,
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required FThemeData theme,
    required String title,
    required IconData icon,
    required double area,
    String? notes,
    required VoidCallback onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: theme.colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: theme.typography.body.md.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  FButton(
                    variant: FButtonVariant.ghost,
                    onPress: onEdit,
                    child: const Icon(LucideIcons.pencil, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Luas (m²)',
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      Text(
                        area.toStringAsFixed(1),
                        style: theme.typography.display.sm.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 40, color: theme.colors.border),
                  Column(
                    children: [
                      Text(
                        'Luas (Ha)',
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      Text(
                        (area / 10000.0).toStringAsFixed(4),
                        style: theme.typography.display.sm.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Catatan',
                  style: theme.typography.body.xs.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(notes, style: theme.typography.body.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
