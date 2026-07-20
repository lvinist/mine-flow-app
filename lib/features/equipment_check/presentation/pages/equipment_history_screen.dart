import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';
import 'package:mine_flow/features/equipment_check/domain/repositories/equipment_check_repository.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_bloc.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_event.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_state.dart';
import 'package:mine_flow/features/equipment_check/presentation/pages/equipment_check_form_screen.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/equipment_check_card.dart';

// Phase 2 — shadcn-admin design language constants (DESIGN.md §29).
const double _kPagePadding = 24;

/// Accent — Cyan / Teal, used sparingly for interactive elements.
const Color _kAccent = Color(0xFF0891B2);

/// Micro-interaction duration for state transitions.
const Duration _kTransitionDuration = Duration(milliseconds: 200);

/// Slightly longer duration for entrance / emphasis animations.
const Duration _kEmphasisDuration = Duration(milliseconds: 350);

// --- Responsive breakpoints (DESIGN.md §28) ---
const double _kBreakMobile = 600;
const double _kBreakTablet = 900;

/// Spacing scale derived from DESIGN.md §29 (4, 8, 12, 16, 20, 24, 32 dp).
/// Using a helper avoids stray hardcoded values and keeps the rhythm consistent.
const EdgeInsets _kSidePaddingWide = EdgeInsets.symmetric(horizontal: 32);

/// Main screen displaying history log of completed equipment SOP condition checks.
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          excludeSemantics: true,
          child: Text(
            'Riwayat Inspeksi Peralatan',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutQuart,
        switchOutCurve: Curves.easeInQuart,
        child: _buildBody(context, colorScheme, theme),
      ),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          final bool isExtended = constraints.maxWidth >= _kBreakMobile;
          return Semantics(
            label: 'Buat inspeksi peralatan baru',
            hint: 'Membuka formulir inspeksi peralatan',
            button: true,
            child: isExtended
                ? FloatingActionButton.extended(
                    key: const Key('create_new_equipment_check_fab_extended'),
                    icon: const Icon(Icons.add),
                    label: const Text('Inspeksi Baru'),
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    highlightElevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => EquipmentCheckFormScreen(
                                repository: widget.repository,
                                siteId: widget.siteId,
                                foremanId: widget.foremanId,
                              ),
                            ),
                          )
                          .then((_) {
                            if (context.mounted) {
                              _onFilterChanged(context);
                            }
                          });
                    },
                  )
                : FloatingActionButton(
                    key: const Key('create_new_equipment_check_fab_compact'),
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    highlightElevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => EquipmentCheckFormScreen(
                                repository: widget.repository,
                                siteId: widget.siteId,
                                foremanId: widget.foremanId,
                              ),
                            ),
                          )
                          .then((_) {
                            if (context.mounted) {
                              _onFilterChanged(context);
                            }
                          });
                    },
                    child: const Icon(Icons.add),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return BlocBuilder<EquipmentCheckBloc, EquipmentCheckState>(
      builder: (context, state) {
        if (state is EquipmentCheckLoading) {
          return Semantics(
            label: 'Memuat riwayat inspeksi',
            liveRegion: true,
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: _kEmphasisDuration,
                curve: Curves.easeOutQuart,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
          );
        }

        if (state is EquipmentCheckError) {
          return Semantics(
            label: 'Terjadi kesalahan: ${state.message}',
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(_kPagePadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      excludeSemantics: true,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.5, end: 1.0),
                        duration: _kEmphasisDuration,
                        curve: Curves.easeOutBack,
                        builder: (context, opacity, child) {
                          return Opacity(opacity: opacity, child: child);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 48,
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedContainer(
                      duration: _kTransitionDuration,
                      curve: Curves.easeOutQuart,
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => _onFilterChanged(context),
                        child: const Text('Muat Ulang'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is EquipmentHistoryLoaded) {
          final checks = state.checks;

          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= _kBreakTablet;
              final bool isMobile = constraints.maxWidth < _kBreakMobile;
              final double sidePad = isWide ? 32.0 : _kPagePadding.toDouble();
              final double horizontalPadding = isWide
                  ? _kSidePaddingWide.horizontal / 2
                  : sidePad;

              return CustomScrollView(
                slivers: [
                  // --- Search & Filter Section ---
                  SliverToBoxAdapter(
                    child: Semantics(
                      label: 'Filter dan pencarian',
                      sortKey: const OrdinalSortKey(0),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          _kPagePadding,
                          horizontalPadding,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search Bar
                            Semantics(
                              sortKey: const OrdinalSortKey(0),
                              label: 'Cari inspeksi peralatan',
                              child: TextField(
                                key: const Key('equipment_search_field'),
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText:
                                      'Cari S/N, tipe alat, atau catatan...',
                                  prefixIcon: ExcludeSemantics(
                                    child: Icon(
                                      Icons.search,
                                      size: 20,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? ExcludeSemantics(
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              _searchController.clear();
                                              _onFilterChanged(context);
                                            },
                                          ),
                                        )
                                      : null,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.outline.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: colorScheme.outline.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: _kAccent,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onChanged: (_) => _onFilterChanged(context),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Equipment Type Filter Chips Row
                            Semantics(
                              label: 'Filter tipe peralatan',
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip(
                                      key: const Key('filter_equipment_all'),
                                      label: 'Semua Tipe',
                                      selected: _selectedEquipmentType == null,
                                      onSelected: (selected) {
                                        setState(
                                          () => _selectedEquipmentType = null,
                                        );
                                        _onFilterChanged(context);
                                      },
                                      colorScheme: colorScheme,
                                    ),
                                    const SizedBox(width: 6),
                                    _buildFilterChip(
                                      key: const Key('filter_equipment_gnss'),
                                      label: 'GNSS Receiver',
                                      selected:
                                          _selectedEquipmentType ==
                                          EquipmentType.gnss,
                                      onSelected: (selected) {
                                        setState(
                                          () =>
                                              _selectedEquipmentType = selected
                                              ? EquipmentType.gnss
                                              : null,
                                        );
                                        _onFilterChanged(context);
                                      },
                                      colorScheme: colorScheme,
                                    ),
                                    const SizedBox(width: 6),
                                    _buildFilterChip(
                                      key: const Key('filter_equipment_ts'),
                                      label: 'Total Station',
                                      selected:
                                          _selectedEquipmentType ==
                                          EquipmentType.totalStation,
                                      onSelected: (selected) {
                                        setState(
                                          () =>
                                              _selectedEquipmentType = selected
                                              ? EquipmentType.totalStation
                                              : null,
                                        );
                                        _onFilterChanged(context);
                                      },
                                      colorScheme: colorScheme,
                                    ),
                                    const SizedBox(width: 6),
                                    _buildFilterChip(
                                      key: const Key('filter_equipment_drone'),
                                      label: 'Drone / UAV',
                                      selected:
                                          _selectedEquipmentType ==
                                          EquipmentType.drone,
                                      onSelected: (selected) {
                                        setState(
                                          () =>
                                              _selectedEquipmentType = selected
                                              ? EquipmentType.drone
                                              : null,
                                        );
                                        _onFilterChanged(context);
                                      },
                                      colorScheme: colorScheme,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Status Filter Chips Row
                            Semantics(
                              label: 'Filter status inspeksi',
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip(
                                      key: const Key('filter_status_all'),
                                      label: 'Semua Status',
                                      selected: _selectedStatus == null,
                                      onSelected: (selected) {
                                        setState(() => _selectedStatus = null);
                                        _onFilterChanged(context);
                                      },
                                      colorScheme: colorScheme,
                                    ),
                                    const SizedBox(width: 6),
                                    _buildFilterChip(
                                      key: const Key('filter_status_passed'),
                                      label: 'Passed / Operasional',
                                      selected:
                                          _selectedStatus == CheckStatus.passed,
                                      onSelected: (selected) {
                                        setState(
                                          () => _selectedStatus = selected
                                              ? CheckStatus.passed
                                              : null,
                                        );
                                        _onFilterChanged(context);
                                      },
                                      colorScheme: colorScheme,
                                    ),
                                    const SizedBox(width: 6),
                                    _buildFilterChip(
                                      key: const Key('filter_status_flagged'),
                                      label: 'Flagged / Perbaikan',
                                      selected:
                                          _selectedStatus ==
                                          CheckStatus.flagged,
                                      onSelected: (selected) {
                                        setState(
                                          () => _selectedStatus = selected
                                              ? CheckStatus.flagged
                                              : null,
                                        );
                                        _onFilterChanged(context);
                                      },
                                      colorScheme: colorScheme,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- Separator ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: horizontalPadding,
                        right: horizontalPadding,
                        top: 16,
                      ),
                      child: Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // --- Count label ---
                  if (checks.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Semantics(
                        label: '${checks.length} inspeksi',
                        sortKey: const OrdinalSortKey(1),
                        liveRegion: true,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: _kTransitionDuration,
                          curve: Curves.easeOutQuart,
                          builder: (context, opacity, child) {
                            return Opacity(opacity: opacity, child: child);
                          },
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              12,
                              horizontalPadding,
                              0,
                            ),
                            child: Text(
                              '${checks.length} inspeksi',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // --- Empty state or History List ---
                  if (checks.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Semantics(
                        label: 'Belum ada riwayat inspeksi peralatan',
                        sortKey: const OrdinalSortKey(2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Semantics(
                              excludeSemantics: true,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Belum ada riwayat inspeksi peralatan.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tekan "Inspeksi Baru" untuk memulai.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.only(
                        left: horizontalPadding,
                        right: horizontalPadding,
                        top: 8,
                        bottom: isMobile ? 80 : 96,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final check = checks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: EquipmentCheckCard(
                              check: check,
                              onDelete: () async {
                                await widget.repository.deleteEquipmentCheck(
                                  check.id,
                                );
                                if (context.mounted) {
                                  _onFilterChanged(context);
                                }
                              },
                            ),
                          );
                        }, childCount: checks.length),
                      ),
                    ),
                ],
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFilterChip({
    required Key key,
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    required ColorScheme colorScheme,
  }) {
    return AnimatedContainer(
      duration: _kTransitionDuration,
      curve: Curves.easeOutQuart,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: FilterChip(
        key: key,
        label: Semantics(
          label: 'Filter: $label${selected ? ', aktif' : ''}',
          excludeSemantics: true,
          child: Text(label),
        ),
        selected: selected,
        onSelected: onSelected,
        showCheckmark: false,
        selectedColor: _kAccent.withValues(alpha: 0.12),
        checkmarkColor: _kAccent,
        side: BorderSide(
          color: selected
              ? _kAccent
              : colorScheme.outline.withValues(alpha: 0.4),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        pressElevation: 1,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant,
          letterSpacing: 0.2,
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
