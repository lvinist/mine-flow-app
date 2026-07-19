import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_state.dart';
import 'package:mine_flow/features/tracking/presentation/pages/inventory_item_entry_screen.dart';
import 'package:mine_flow/features/tracking/presentation/pages/stock_adjustment_dialog.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/inventory_card.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/inventory_summary_card.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Inventori')),
      body: Column(
        children: [
          // Category filter tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterTabs.map((tab) {
                  final isSelected = tab == 'Semua'
                      ? _selectedCategory == null
                      : _selectedCategory == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        tab,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected && tab != 'Semua'
                              ? tab
                              : null;
                        });
                        context.read<InventoryBloc>().add(
                          FilterByCategoryEvent(_selectedCategory),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Main content
          Expanded(
            child: BlocBuilder<InventoryBloc, InventoryState>(
              builder: (context, state) {
                if (state is InventoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is InventoryError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            context.read<InventoryBloc>().add(
                              LoadInventoryItemsEvent(siteId: widget.siteId),
                            );
                          },
                          child: const Text('Muat Ulang'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is InventoryItemsLoaded) {
                  final items = state.items;

                  // Empty state
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedCategory != null
                                ? 'Tidak ada item di kategori ini.'
                                : 'Belum ada item inventori.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Compute unique categories count for summary
                  final uniqueCategories = items
                      .map((i) => i.category)
                      .where((c) => c != null && c.isNotEmpty)
                      .toSet()
                      .length;

                  return ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    children: [
                      // Summary card
                      InventorySummaryCard(
                        totalItems: items.length,
                        lowStockCount: state.lowStockCount,
                        categoryCount: uniqueCategories,
                      ),
                      const SizedBox(height: 4),

                      // Low stock warning banner (if any)
                      if (state.lowStockCount > 0)
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.red.withAlpha(76)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${state.lowStockCount} item dengan stok rendah perlu perhatian.',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Item count label
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${items.length} item',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                      // Item cards
                      ...items.map(
                        (item) => InventoryCard(
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
                        ),
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create_new_inventory_fab'),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Item'),
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
      ),
    );
  }
}
