import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_state.dart';
import 'package:mine_flow/features/tracking/presentation/pages/inventory_item_entry_screen.dart';
import 'package:mine_flow/features/tracking/presentation/pages/stock_adjustment_dialog.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/inventory_card.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/inventory_summary_card.dart';

const double _kPagePadding = 24;
const double _kBreakMobile = 600;
const double _kBreakTablet = 900;
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

  List<String> get _filterTabs => ['Semua', ...InventoryBloc.categories];

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: isDesktop 
          ? null 
          : PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: FHeader(
                title: Semantics(
                  header: true,
                  child: Text(
                    'Inventori',
                    style: theme.typography.display.sm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutQuart,
        switchOutCurve: Curves.easeOutQuart,
        child: _buildBody(context, theme),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Buat Laporan Inventaris',
            button: true,
            child: FloatingActionButton(
              heroTag: 'report_inventory_btn',
              backgroundColor: theme.colors.secondary,
              foregroundColor: theme.colors.secondaryForeground,
              elevation: 2,
              onPressed: () => context.pushNamed(
                'report-config',
                extra: ReportType.inventory,
              ),
              child: const Icon(Icons.picture_as_pdf_outlined),
            ),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: 'add_inventory_btn',
            backgroundColor: theme.colors.primary,
            foregroundColor: theme.colors.primaryForeground,
            elevation: 2,
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
            icon: const Icon(Icons.add),
            label: const Text('Tambah Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, FThemeData theme) {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }

        if (state is InventoryError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(_kPagePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colors.destructive,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: theme.typography.body.md.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FButton(
                    onPress: () {
                      context.read<InventoryBloc>().add(
                        LoadInventoryItemsEvent(siteId: widget.siteId),
                      );
                    },
                    child: const Text('Muat Ulang'),
                  ),
                ],
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
              final int crossAxisCount = isWide ? 2 : 1;

              final double sidePad = isWide ? 32.0 : _kPagePadding.toDouble();
              final EdgeInsets contentPadding = EdgeInsets.only(
                left: sidePad,
                right: sidePad,
                bottom: 96,
              );
              final double horizontalPadding = isWide
                  ? _kSidePaddingWide.horizontal / 2
                  : sidePad;

              final uniqueCategories = items
                  .map((i) => i.category)
                  .where((c) => c != null && c.isNotEmpty)
                  .toSet()
                  .length;

              return CustomScrollView(
                slivers: [
                  // --- Category Filter Chips Row ---
                  SliverToBoxAdapter(
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
                                onSelected: () {
                                  setState(() {
                                    _selectedCategory =
                                        !isSelected && tab != 'Semua'
                                        ? tab
                                        : null;
                                  });
                                  context.read<InventoryBloc>().add(
                                    FilterByCategoryEvent(_selectedCategory),
                                  );
                                },
                                theme: theme,
                              ),
                            );
                          }).toList(),
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
                            color: theme.colors.destructive.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colors.destructive.withAlpha(76),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: theme.colors.destructive,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${state.lowStockCount} item dengan stok rendah perlu perhatian.',
                                  style: theme.typography.body.xs.copyWith(
                                    color: theme.colors.destructive,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // --- Item count label ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: horizontalPadding,
                        right: horizontalPadding,
                        top: 16,
                      ),
                      child: Text(
                        '${items.length} item',
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.mutedForeground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // --- Item cards or Empty state ---
                  if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: theme.colors.mutedForeground,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _selectedCategory != null
                                ? 'Tidak ada item di kategori ini.'
                                : 'Belum ada item inventori.',
                            style: theme.typography.body.md.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedCategory != null
                                ? 'Pilih kategori lain atau tambah item baru.'
                                : 'Tekan "Tambah Item" untuk memulai.',
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
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
    required VoidCallback onSelected,
    required FThemeData theme,
  }) {
    return FButton(onPress: onSelected, child: Text(label));
  }
}
