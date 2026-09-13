import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/core/presentation/widgets/confirm_destructive_action.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';
import 'package:mine_flow/features/equipment_check/domain/repositories/equipment_check_repository.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_bloc.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_event.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_state.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/equipment_check_card.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/domain/repositories/reporting_repository.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/app_contextual_report_dialog.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/main.dart';

/// Main screen displaying history log of completed equipment SOP condition checks.
///
/// Migrated in STEP-55.7 (FC-54.7-001, FC-54.7-005, FC-54.7-006):
/// - Replaced inline expansion detail with route-backed detail navigation (/teams/equipment-check/:id).
/// - Replaced standalone report push with contextual report dialog [showAppContextualReportDialog].
/// - Popover-first filtering via [AppFilterPopover] and active filter summary pills.
/// - Purged Material FAB and TextField in favor of ForUI token-aligned controls.
class EquipmentHistoryScreen extends StatelessWidget {
  final EquipmentCheckRepository repository;
  final String siteId;
  final String foremanId;
  final ReportingRepository? reportingRepository;
  final ZoneRepository? zoneRepository;

  const EquipmentHistoryScreen({
    super.key,
    required this.repository,
    required this.siteId,
    required this.foremanId,
    this.reportingRepository,
    this.zoneRepository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          EquipmentCheckBloc(repository: repository)
            ..add(LoadEquipmentHistoryEvent(siteId: siteId)),
      child: EquipmentHistoryView(
        repository: repository,
        siteId: siteId,
        foremanId: foremanId,
        reportingRepository: reportingRepository,
        zoneRepository: zoneRepository,
      ),
    );
  }
}

class EquipmentHistoryView extends StatefulWidget {
  final EquipmentCheckRepository repository;
  final String siteId;
  final String foremanId;
  final ReportingRepository? reportingRepository;
  final ZoneRepository? zoneRepository;

  const EquipmentHistoryView({
    super.key,
    required this.repository,
    required this.siteId,
    required this.foremanId,
    this.reportingRepository,
    this.zoneRepository,
  });

  @override
  State<EquipmentHistoryView> createState() => _EquipmentHistoryViewState();
}

class _EquipmentHistoryViewState extends State<EquipmentHistoryView> {
  EquipmentType? _selectedEquipmentType;
  CheckStatus? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
      _debouncedSearch();
    }
  }

  void _debouncedSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _onFilterChanged(context);
    });
  }

  void _onFilterChanged(BuildContext context) {
    context.read<EquipmentCheckBloc>().add(
      LoadEquipmentHistoryEvent(
        siteId: widget.siteId,
        equipmentTypeFilter: _selectedEquipmentType,
        statusFilter: _selectedStatus,
        searchQuery: _searchController.text,
      ),
    );
  }

  Future<void> _openNewCheck() async {
    await context.pushNamed(
      'equipment-check-form',
      queryParameters: {'siteId': widget.siteId},
    );
    if (mounted) {
      _onFilterChanged(context);
    }
  }

  void _openDetail(String checkId, EquipmentCheck check) {
    context
        .pushNamed(
          'equipment-check-detail',
          pathParameters: {'id': checkId},
          extra: check,
        )
        .then((_) {
          if (mounted) {
            _onFilterChanged(context);
          }
        });
  }

  Future<void> _openReportDialog(BuildContext context) async {
    final repRepo =
        widget.reportingRepository ?? appServices?.reportingRepository;
    final zRepo = widget.zoneRepository ?? appServices?.zoneRepository;
    if (repRepo == null || zRepo == null) return;

    await showAppContextualReportDialog(
      context: context,
      reportType: ReportType.equipmentCheck,
      sourceTitle: 'Inspeksi Peralatan',
      reportingRepository: repRepo,
      zoneRepository: zRepo,
    );
  }

  Future<void> _showFilterPopover(BuildContext context) async {
    EquipmentType? tempType = _selectedEquipmentType;
    CheckStatus? tempStatus = _selectedStatus;

    await showAppFilterPopover<void>(
      context: context,
      builder: (popoverContext) {
        return StatefulBuilder(
          builder: (context, setPopoverState) {
            return AppFilterPopover(
              onApply: () {
                setState(() {
                  _selectedEquipmentType = tempType;
                  _selectedStatus = tempStatus;
                });
                _onFilterChanged(this.context);
                Navigator.of(popoverContext).pop();
              },
              onReset: () {
                setState(() {
                  _selectedEquipmentType = null;
                  _selectedStatus = null;
                });
                _onFilterChanged(this.context);
                Navigator.of(popoverContext).pop();
              },
              onCancel: () => Navigator.of(popoverContext).pop(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipe Peralatan',
                    style: FTheme.of(
                      context,
                    ).typography.body.sm.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FButton(
                        key: const Key('filter_equipment_all'),
                        variant: tempType == null
                            ? FButtonVariant.primary
                            : FButtonVariant.outline,
                        onPress: () => setPopoverState(() => tempType = null),
                        child: const Text('Semua Tipe'),
                      ),
                      FButton(
                        key: const Key('filter_equipment_gnss'),
                        variant: tempType == EquipmentType.gnss
                            ? FButtonVariant.primary
                            : FButtonVariant.outline,
                        onPress: () => setPopoverState(
                          () => tempType = EquipmentType.gnss,
                        ),
                        child: const Text('GNSS Receiver'),
                      ),
                      FButton(
                        key: const Key('filter_equipment_ts'),
                        variant: tempType == EquipmentType.totalStation
                            ? FButtonVariant.primary
                            : FButtonVariant.outline,
                        onPress: () => setPopoverState(
                          () => tempType = EquipmentType.totalStation,
                        ),
                        child: const Text('Total Station'),
                      ),
                      FButton(
                        key: const Key('filter_equipment_drone'),
                        variant: tempType == EquipmentType.drone
                            ? FButtonVariant.primary
                            : FButtonVariant.outline,
                        onPress: () => setPopoverState(
                          () => tempType = EquipmentType.drone,
                        ),
                        child: const Text('Drone / UAV'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Status Kelayakan',
                    style: FTheme.of(
                      context,
                    ).typography.body.sm.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FButton(
                        key: const Key('filter_status_all'),
                        variant: tempStatus == null
                            ? FButtonVariant.primary
                            : FButtonVariant.outline,
                        onPress: () => setPopoverState(() => tempStatus = null),
                        child: const Text('Semua Status'),
                      ),
                      FButton(
                        key: const Key('filter_status_passed'),
                        variant: tempStatus == CheckStatus.passed
                            ? FButtonVariant.primary
                            : FButtonVariant.outline,
                        onPress: () => setPopoverState(
                          () => tempStatus = CheckStatus.passed,
                        ),
                        child: const Text('Passed / Operasional'),
                      ),
                      FButton(
                        key: const Key('filter_status_flagged'),
                        variant: tempStatus == CheckStatus.flagged
                            ? FButtonVariant.primary
                            : FButtonVariant.outline,
                        onPress: () => setPopoverState(
                          () => tempStatus = CheckStatus.flagged,
                        ),
                        child: const Text('Flagged / Perbaikan'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final hasActiveFilter =
        _selectedEquipmentType != null || _selectedStatus != null;

    return FScaffold(
      header: FHeader.nested(
        title: Text(
          'Riwayat Inspeksi Peralatan',
          style: theme.typography.display.sm.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                // Search & Filter Bar Section
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: theme.colors.background,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FTextField(
                              key: const Key('equipment_search_field'),
                              control: FTextFieldControl.managed(
                                controller: _searchController,
                              ),
                              hint: 'Cari S/N, tipe alat, atau catatan...',
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 48,
                            child: FButton(
                              key: const Key('equipment_filter_button'),
                              variant: hasActiveFilter
                                  ? FButtonVariant.primary
                                  : FButtonVariant.outline,
                              prefix: const Icon(LucideIcons.filter, size: 16),
                              onPress: () => _showFilterPopover(context),
                              child: const Text('Filter'),
                            ),
                          ),
                        ],
                      ),
                      if (hasActiveFilter) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (_selectedEquipmentType != null)
                              FButton(
                                variant: FButtonVariant.outline,
                                onPress: () {
                                  setState(() => _selectedEquipmentType = null);
                                  _onFilterChanged(context);
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Tipe: ${_selectedEquipmentType!.displayName}',
                                      style: theme.typography.body.xs,
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(LucideIcons.x, size: 14),
                                  ],
                                ),
                              ),
                            if (_selectedStatus != null)
                              FButton(
                                variant: FButtonVariant.outline,
                                onPress: () {
                                  setState(() => _selectedStatus = null);
                                  _onFilterChanged(context);
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Status: ${_selectedStatus!.displayName}',
                                      style: theme.typography.body.xs,
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(LucideIcons.x, size: 14),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const FDivider(),

                // History List View
                Expanded(
                  child: BlocBuilder<EquipmentCheckBloc, EquipmentCheckState>(
                    builder: (context, state) {
                      if (state is EquipmentCheckLoading) {
                        return const Center(child: FCircularProgress());
                      }

                      if (state is EquipmentCheckError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                state.message,
                                style: theme.typography.body.md.copyWith(
                                  color: theme.colors.destructive,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FButton(
                                onPress: () => _onFilterChanged(context),
                                child: const Text('Muat Ulang'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is EquipmentHistoryLoaded) {
                        if (state.checks.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.boxes,
                                  size: 56,
                                  color: theme.colors.secondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada riwayat inspeksi peralatan.',
                                  style: theme.typography.body.md.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: state.checks.length,
                          itemBuilder: (context, index) {
                            final check = state.checks[index];
                            return EquipmentCheckCard(
                              check: check,
                              onTap: () => _openDetail(check.id, check),
                              onDelete: () async {
                                final proceed = await confirmDestructiveAction(
                                  context,
                                  message:
                                      'Hapus catatan inspeksi ini? Tindakan tidak dapat dibatalkan.',
                                );
                                if (proceed && context.mounted) {
                                  context.read<EquipmentCheckBloc>().add(
                                    DeleteEquipmentCheckEvent(
                                      checkId: check.id,
                                      siteId: widget.siteId,
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar (Contextual Report + New Check)
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'Buat Laporan Inspeksi Peralatan',
                    button: true,
                    child: SizedBox(
                      height: 48,
                      child: FButton(
                        key: const Key('equipment_report_button'),
                        variant: FButtonVariant.outline,
                        onPress: () => _openReportDialog(context),
                        prefix: const Icon(LucideIcons.fileText, size: 18),
                        child: const Text('Laporan'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    label: 'Inspeksi baru',
                    button: true,
                    child: SizedBox(
                      height: 48,
                      child: FButton(
                        key: const Key('create_new_equipment_check_fab'),
                        variant: FButtonVariant.primary,
                        onPress: _openNewCheck,
                        prefix: const Icon(LucideIcons.plus, size: 18),
                        child: const Text('Inspeksi Baru'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
