import 'package:flutter/material.dart';
import 'package:mine_flow/core/presentation/widgets/confirm_destructive_action.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';
import 'package:mine_flow/features/equipment_check/domain/repositories/equipment_check_repository.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_bloc.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_event.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_state.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/equipment_check_card.dart';

/// Main screen displaying history log of completed equipment SOP condition checks.
///
/// Migrated to ForUI in Substep 30.3: Material colors/tokens replaced with
/// FTheme semantic tokens, FilledButton replaced with FIconButton.
class EquipmentHistoryScreen extends StatelessWidget {
  final EquipmentCheckRepository repository;
  final String siteId;
  final String foremanId;

  const EquipmentHistoryScreen({
    super.key,
    required this.repository,
    required this.siteId,
    required this.foremanId,
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
      ),
    );
  }
}

class EquipmentHistoryView extends StatefulWidget {
  final EquipmentCheckRepository repository;
  final String siteId;
  final String foremanId;

  const EquipmentHistoryView({
    super.key,
    required this.repository,
    required this.siteId,
    required this.foremanId,
  });

  @override
  State<EquipmentHistoryView> createState() => _EquipmentHistoryViewState();
}

class _EquipmentHistoryViewState extends State<EquipmentHistoryView> {
  EquipmentType? _selectedEquipmentType;
  CheckStatus? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();

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
      extra: {
        'siteId': widget.siteId,
        'foremanId': widget.foremanId,
      },
    );
    if (mounted) {
      _onFilterChanged(context);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: MediaQuery.of(context).size.width > 800
          ? null
          : AppBar(
              title: Text(
                'Riwayat Inspeksi Peralatan',
                style: theme.typography.display.sm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      body: Column(
        children: [
          // Search & Filter Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colors.background,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  key: const Key('equipment_search_field'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari S/N, tipe alat, atau catatan...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onFilterChanged(context);
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (_) => _onFilterChanged(context),
                ),
                const SizedBox(height: 8),

                // Equipment Type Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        key: const Key('filter_equipment_all'),
                        label: const Text('Semua Tipe'),
                        selected: _selectedEquipmentType == null,
                        onSelected: (selected) {
                          setState(() => _selectedEquipmentType = null);
                          _onFilterChanged(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        key: const Key('filter_equipment_gnss'),
                        label: const Text('GNSS Receiver'),
                        selected: _selectedEquipmentType == EquipmentType.gnss,
                        onSelected: (selected) {
                          setState(
                            () => _selectedEquipmentType = selected
                                ? EquipmentType.gnss
                                : null,
                          );
                          _onFilterChanged(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        key: const Key('filter_equipment_ts'),
                        label: const Text('Total Station'),
                        selected:
                            _selectedEquipmentType ==
                            EquipmentType.totalStation,
                        onSelected: (selected) {
                          setState(
                            () => _selectedEquipmentType = selected
                                ? EquipmentType.totalStation
                                : null,
                          );
                          _onFilterChanged(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        key: const Key('filter_equipment_drone'),
                        label: const Text('Drone / UAV'),
                        selected: _selectedEquipmentType == EquipmentType.drone,
                        onSelected: (selected) {
                          setState(
                            () => _selectedEquipmentType = selected
                                ? EquipmentType.drone
                                : null,
                          );
                          _onFilterChanged(context);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Status Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        key: const Key('filter_status_all'),
                        label: const Text('Semua Status'),
                        selected: _selectedStatus == null,
                        onSelected: (selected) {
                          setState(() => _selectedStatus = null);
                          _onFilterChanged(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        key: const Key('filter_status_passed'),
                        label: const Text('Passed / Operasional'),
                        selected: _selectedStatus == CheckStatus.passed,
                        onSelected: (selected) {
                          setState(
                            () => _selectedStatus = selected
                                ? CheckStatus.passed
                                : null,
                          );
                          _onFilterChanged(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        key: const Key('filter_status_flagged'),
                        label: const Text('Flagged / Perbaikan'),
                        selected: _selectedStatus == CheckStatus.flagged,
                        onSelected: (selected) {
                          setState(
                            () => _selectedStatus = selected
                                ? CheckStatus.flagged
                                : null,
                          );
                          _onFilterChanged(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // History List View
          Expanded(
            child: BlocBuilder<EquipmentCheckBloc, EquipmentCheckState>(
              builder: (context, state) {
                if (state is EquipmentCheckLoading) {
                  return const Center(child: CircularProgressIndicator());
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
                        FilledButton(
                          onPressed: () => _onFilterChanged(context),
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
                            Icons.inventory_2_outlined,
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
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.checks.length,
                    itemBuilder: (context, index) {
                      final check = state.checks[index];
                      return EquipmentCheckCard(
                        check: check,
                        onDelete: () async {
                          // CF-020: route delete through the bloc, with a
                          // supervisor role gate + confirmation.
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
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Buat Laporan Inspeksi Peralatan',
            button: true,
            child: FloatingActionButton(
              heroTag: 'report_equipment_btn',
              backgroundColor: theme.colors.secondary,
              foregroundColor: theme.colors.secondaryForeground,
              elevation: 2,
              onPressed: () => context.pushNamed(
                'report-config',
                extra: ReportType.equipmentCheck,
              ),
              child: const Icon(Icons.picture_as_pdf_outlined),
            ),
          ),
          const SizedBox(width: 16),
          Semantics(
            label: 'Inspeksi baru',
            button: true,
            child: MediaQuery.of(context).size.width < 480
                ? FloatingActionButton(
                    key: const Key('create_new_equipment_check_fab'),
                    heroTag: 'add_equipment_btn',
                    backgroundColor: theme.colors.primary,
                    foregroundColor: theme.colors.primaryForeground,
                    onPressed: _openNewCheck,
                    child: const Icon(Icons.add),
                  )
                : FloatingActionButton.extended(
                    key: const Key('create_new_equipment_check_fab'),
                    heroTag: 'add_equipment_btn',
                    icon: const Icon(Icons.add),
                    label: const Text('Inspeksi Baru'),
                    backgroundColor: theme.colors.primary,
                    foregroundColor: theme.colors.primaryForeground,
                    onPressed: _openNewCheck,
                  ),
          ),
        ],
      ),
    );
  }
}
