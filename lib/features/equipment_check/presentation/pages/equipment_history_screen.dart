import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mine_flow/core/presentation/widgets/confirm_destructive_action.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // CF-053: rebuild so the clear button tracks the text as it changes.
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  /// CF-053: debounce the repo re-query while typing.
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
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
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
                    prefixIcon: const Icon(LucideIcons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x),
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
                  onChanged: (_) => _debouncedSearch(),
                ),
                const SizedBox(height: 8),

                // Equipment Type Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FButton(
                        key: const Key('filter_equipment_all'),
                        variant: _selectedEquipmentType == null ? FButtonVariant.primary : FButtonVariant.outline,
                        onPress: () {
                          setState(() => _selectedEquipmentType = null);
                          _onFilterChanged(context);
                        },
                        child: const Text('Semua Tipe'),
                      ),
                      const SizedBox(width: 8),
                      FButton(
                        key: const Key('filter_equipment_gnss'),
                        variant: _selectedEquipmentType == EquipmentType.gnss ? FButtonVariant.primary : FButtonVariant.outline,
                        onPress: () {
                          setState(
                            () => _selectedEquipmentType =
                                _selectedEquipmentType == EquipmentType.gnss
                                    ? null
                                    : EquipmentType.gnss,
                          );
                          _onFilterChanged(context);
                        },
                        child: const Text('GNSS Receiver'),
                      ),
                      const SizedBox(width: 8),
                      FButton(
                        key: const Key('filter_equipment_ts'),
                        variant: _selectedEquipmentType ==
                            EquipmentType.totalStation ? FButtonVariant.primary : FButtonVariant.outline,
                        onPress: () {
                          setState(
                            () => _selectedEquipmentType =
                                _selectedEquipmentType == EquipmentType.totalStation
                                    ? null
                                    : EquipmentType.totalStation,
                          );
                          _onFilterChanged(context);
                        },
                        child: const Text('Total Station'),
                      ),
                      const SizedBox(width: 8),
                      FButton(
                        key: const Key('filter_equipment_drone'),
                        variant: _selectedEquipmentType == EquipmentType.drone ? FButtonVariant.primary : FButtonVariant.outline,
                        onPress: () {
                          setState(
                            () => _selectedEquipmentType =
                                _selectedEquipmentType == EquipmentType.drone
                                    ? null
                                    : EquipmentType.drone,
                          );
                          _onFilterChanged(context);
                        },
                        child: const Text('Drone / UAV'),
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
                      FButton(
                        key: const Key('filter_status_all'),
                        variant: _selectedStatus == null ? FButtonVariant.primary : FButtonVariant.outline,
                        onPress: () {
                          setState(() => _selectedStatus = null);
                          _onFilterChanged(context);
                        },
                        child: const Text('Semua Status'),
                      ),
                      const SizedBox(width: 8),
                      FButton(
                        key: const Key('filter_status_passed'),
                        variant: _selectedStatus == CheckStatus.passed ? FButtonVariant.primary : FButtonVariant.outline,
                        onPress: () {
                          setState(
                            () => _selectedStatus =
                                _selectedStatus == CheckStatus.passed
                                    ? null
                                    : CheckStatus.passed,
                          );
                          _onFilterChanged(context);
                        },
                        child: const Text('Passed / Operasional'),
                      ),
                      const SizedBox(width: 8),
                      FButton(
                        key: const Key('filter_status_flagged'),
                        variant: _selectedStatus == CheckStatus.flagged ? FButtonVariant.primary : FButtonVariant.outline,
                        onPress: () {
                          setState(
                            () => _selectedStatus =
                                _selectedStatus == CheckStatus.flagged
                                    ? null
                                    : CheckStatus.flagged,
                          );
                          _onFilterChanged(context);
                        },
                        child: const Text('Flagged / Perbaikan'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const FDivider(),

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
              child: const Icon(LucideIcons.fileText),
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
                    child: const Icon(LucideIcons.plus),
                  )
                : FloatingActionButton.extended(
                    key: const Key('create_new_equipment_check_fab'),
                    heroTag: 'add_equipment_btn',
                    icon: const Icon(LucideIcons.plus),
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
