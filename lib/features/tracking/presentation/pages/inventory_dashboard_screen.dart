import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_state.dart';
import 'package:mine_flow/features/tracking/presentation/pages/inventory_item_entry_screen.dart';
import 'package:mine_flow/features/tracking/presentation/pages/stock_adjustment_dialog.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/inventory_card.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/inventory_summary_card.dart';

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

/// Screen showing the inventory dashboard with category filter tabs,
/// low-stock warning banners, and the full item list.
class InventoryDashboardScreen extends StatelessWidget {
  final TrackingRepository repository;
  final String siteId;

  const InventoryDashboardScreen({
    super.key,
    required this.repository,
    required this.siteId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          InventoryBloc(repository: repository)
            ..add(LoadInventoryItemsEvent(siteId: siteId)),
      child: _InventoryDashboardView(repository: repository, siteId: siteId),
    );
  }
}

class _InventoryDashboardView extends StatefulWidget {
  final TrackingRepository repository;
  final String siteId;

  const _InventoryDashboardView({
    required this.repository,
    required this.siteId,
  });

  @override
  State<_InventoryDashboardView> createState() =>
      _InventoryDashboardViewState();
}

class _InventoryDashboardViewState extends State<_InventoryDashboardView> {
  String? _selectedCategory;

  /// Category filter options: "All" plus predefined categories.
  List<String> get _filterTabs => ['Semua', ...InventoryBloc.categories];

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
            'Inventori',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.4,
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
            label: 'Tambah item inventori baru',
            hint: 'Membuka formulir entri item inventori',
            button: true,
            child: isExtended
                ? FloatingActionButton.extended(
                    key: const Key('create_new_inventory_fab'),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Item'),
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
                              builder: (_) => InventoryItemEntryScreen(
                                repository: widget.repository,
                                siteId: widget.siteId,
                              ),
                            ),
                          )
                          .then((_) {
                            if (context.mounted) {
                              context.read<InventoryBloc>().add(
                                LoadInventoryItemsEvent(
                                  siteId: widget.siteId,
                                  category: _selectedCategory,
                                ),
                              );
                            }
                          });
                    },
                  )
                : FloatingActionButton(
                    key: const Key('create_new_inventory_fab'),
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
                              builder: (_) => InventoryItemEntryScreen(
                                repository: widget.repository,
                                siteId: widget.siteId,
                              ),
                            ),
                          )
                          .then((_) {
                            if (context.mounted) {
                              context.read<InventoryBloc>().add(
                                LoadInventoryItemsEvent(
                                  siteId: widget.siteId,
                                  category: _selectedCategory,
                                ),
                              );
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
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return Semantics(
            label: 'Memuat data inventori',
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

        if (state is InventoryError) {
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
                        onPressed: () {
                          context.read<InventoryBloc>().add(
                            LoadInventoryItemsEvent(siteId: widget.siteId),
                          );
                        },
                        child: const Text('Muat Ulang'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is InventoryItemsLoaded) {
          final items = state.items;

          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= _kBreakTablet;
              final bool isMobile = constraints.maxWidth < _kBreakMobile;
              // Narrow layout: single-column list. Wide layout: 2-column grid.
              final int crossAxisCount = isWide ? 2 : 1;

              // Use the shared side-padding constants from DESIGN.md §29 spacing scale.
              final double sidePad = isWide ? 32.0 : _kPagePadding.toDouble();

              // Wider content area needs tighter visual padding; narrow stays at page padding.
              final EdgeInsets contentPadding = EdgeInsets.only(
                left: sidePad,
                right: sidePad,
                bottom: 96,
              );
              final double horizontalPadding = isWide
                  ? _kSidePaddingWide.horizontal / 2
                  : sidePad;

              // Compute unique categories count for summary
              final uniqueCategories = items
                  .map((i) => i.category)
                  .where((c) => c != null && c.isNotEmpty)
                  .toSet()
                  .length;

              return CustomScrollView(
                slivers: [
                  // --- Category Filter Chips Row ---
                  SliverToBoxAdapter(
                    child: Semantics(
                      label: 'Filter kategori',
                      sortKey: const OrdinalSortKey(0),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          _kPagePadding,
                          horizontalPadding,
                          0,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _filterTabs.map((tab) {
                              final isSelected = tab == 'Semua'
                                  ? _selectedCategory == null
                                  : _selectedCategory == tab;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildFilterChip(
                                  label: tab,
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory =
                                          selected && tab != 'Semua'
                                          ? tab
                                          : null;
                                    });
                                    context.read<InventoryBloc>().add(
                                      FilterByCategoryEvent(_selectedCategory),
                                    );
                                  },
                                  colorScheme: colorScheme,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- Summary card ---
                  if (items.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          16,
                          horizontalPadding,
                          0,
                        ),
                        child: InventorySummaryCard(
                          totalItems: items.length,
                          lowStockCount: state.lowStockCount,
                          categoryCount: uniqueCategories,
                        ),
                      ),
                    ),

                  // --- Low stock warning banner (if any) ---
                  if (state.lowStockCount > 0)
                    SliverToBoxAdapter(
                      child: Semantics(
                        label: '${state.lowStockCount} item dengan stok rendah',
                        sortKey: const OrdinalSortKey(1),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            12,
                            horizontalPadding,
                            0,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer.withValues(
                                alpha: 0.35,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colorScheme.error.withValues(
                                  alpha: 0.35,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Semantics(
                                  excludeSemantics: true,
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    color: colorScheme.error,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${state.lowStockCount} item dengan stok rendah perlu perhatian.',
                                    style: TextStyle(
                                      color: colorScheme.onErrorContainer,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // --- Item count label ---
                  SliverToBoxAdapter(
                    child: Semantics(
                      label: '${items.length} item',
                      sortKey: const OrdinalSortKey(2),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: horizontalPadding,
                          right: horizontalPadding,
                          top: 16,
                        ),
                        child: Text(
                          '${items.length} item',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- Item cards or Empty state ---
                  if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Semantics(
                        label: _selectedCategory != null
                            ? 'Tidak ada item di kategori ini'
                            : 'Belum ada item inventori',
                        sortKey: const OrdinalSortKey(3),
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
                              _selectedCategory != null
                                  ? 'Tidak ada item di kategori ini.'
                                  : 'Belum ada item inventori.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedCategory != null
                                  ? 'Pilih kategori lain atau tambah item baru.'
                                  : 'Tekan "Tambah Item" untuk memulai.',
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
                      padding: contentPadding,
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 12,
                          childAspectRatio: isMobile ? 3.0 : 2.4,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = items[index];
                          return InventoryCard(
                            item: item,
                            onTap: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => InventoryItemEntryScreen(
                                        repository: widget.repository,
                                        siteId: widget.siteId,
                                        existingItem: item,
                                      ),
                                    ),
                                  )
                                  .then((_) {
                                    if (context.mounted) {
                                      context.read<InventoryBloc>().add(
                                        LoadInventoryItemsEvent(
                                          siteId: widget.siteId,
                                          category: _selectedCategory,
                                        ),
                                      );
                                    }
                                  });
                            },
                            onAdjustStock: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => StockAdjustmentDialog(
                                  item: item,
                                  onAdjust: (deltaQuantity, reason) {
                                    context.read<InventoryBloc>().add(
                                      AdjustStockEvent(
                                        itemId: item.id,
                                        deltaQuantity: deltaQuantity,
                                        reason: reason,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            onDelete: () {
                              context.read<InventoryBloc>().add(
                                DeleteInventoryItemEvent(item.id),
                              );
                            },
                          );
                        }, childCount: items.length),
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
