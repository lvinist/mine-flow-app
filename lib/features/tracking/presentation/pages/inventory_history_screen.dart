import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/core/presentation/widgets/confirm_destructive_action.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_state.dart';
import 'package:mine_flow/features/tracking/presentation/pages/stock_adjustment_dialog.dart';
import 'package:mine_flow/app/router.dart';

class InventoryHistoryScreen extends StatelessWidget {
  final TrackingRepository repository;
  final String itemId;
  final Uri? routeUri;

  const InventoryHistoryScreen({
    super.key,
    required this.repository,
    required this.itemId,
    this.routeUri,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          InventoryBloc(repository: repository)
            ..add(LoadInventoryHistoryEvent(itemId)),
      child: _InventoryHistoryView(itemId: itemId, routeUri: routeUri),
    );
  }
}

class _InventoryHistoryView extends StatelessWidget {
  final String itemId;
  final Uri? routeUri;

  const _InventoryHistoryView({required this.itemId, this.routeUri});

  void _handleClose(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.inventory);
    }
  }

  void _openEdit(BuildContext context, dynamic item) {
    final query = routeUri?.queryParameters ?? {};
    context
        .pushNamed(
          'inventory-edit',
          pathParameters: {'id': itemId},
          queryParameters: query,
          extra: item,
        )
        .then((_) {
          if (context.mounted) {
            context.read<InventoryBloc>().add(
              LoadInventoryHistoryEvent(itemId),
            );
          }
        });
  }

  void _openAdjust(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StockAdjustmentDialog(
          item: item,
          onAdjust: (deltaQuantity, reason) {
            context.read<InventoryBloc>().add(
              AdjustStockEvent(
                itemId: item.id,
                deltaQuantity: deltaQuantity,
                reason: reason,
              ),
            );
            // wait a little then reload
            Future.delayed(const Duration(milliseconds: 300), () {
              if (context.mounted) {
                context.read<InventoryBloc>().add(
                  LoadInventoryHistoryEvent(itemId),
                );
              }
            });
          },
        );
      },
    );
  }

  Future<void> _handleDelete(BuildContext context, dynamic item) async {
    final proceed = await confirmDestructiveAction(
      context,
      message: 'Hapus item inventaris ini? Tindakan tidak dapat dibatalkan.',
    );
    if (proceed && context.mounted) {
      context.read<InventoryBloc>().add(DeleteInventoryItemEvent(item.id));
      _handleClose(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        final routeIdentity = routeUri?.toString() ?? 'inventory-history';

        if (state is InventoryLoading || state is InventoryInitial) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: 'Riwayat Stok',
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

        if (state is InventoryError) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: 'Riwayat Stok',
            mode: AppResponsiveSheetMode.readOnlyInspector,
            onDismissApproved: () => _handleClose(context),
            body: AppStatePanel(
              title: 'Gagal Memuat',
              message: state.message,
              actionLabel: 'Kembali',
              onAction: () => _handleClose(context),
            ),
          );
        }

        if (state is InventoryHistoryLoaded) {
          final item = state.item;
          final transactions = state.transactions;

          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: 'Detail & Riwayat',
            subtitle: item.itemName,
            mode: AppResponsiveSheetMode.readOnlyInspector,
            onDismissApproved: () => _handleClose(context),
            footer: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      variant: FButtonVariant.outline,
                      onPress: () => _openEdit(context, item),
                      child: const Text('Ubah Data'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      onPress: () => _openAdjust(context, item),
                      child: const Text('Penyesuaian Stok'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      variant: FButtonVariant.destructive,
                      onPress: () => _handleDelete(context, item),
                      child: const Text('Hapus Item'),
                    ),
                  ),
                ],
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Info Card
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            style: theme.typography.body.lg.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            theme,
                            'Kategori',
                            item.category ?? '-',
                          ),
                          _buildInfoRow(theme, 'SKU', item.sku ?? '-'),
                          _buildInfoRow(
                            theme,
                            'Stok Minimum',
                            '${item.minThreshold?.toStringAsFixed(item.minThreshold! == item.minThreshold!.roundToDouble() ? 0 : 1) ?? "-"} ${item.unit}',
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Stok Saat Ini',
                                style: theme.typography.body.sm.copyWith(
                                  color: theme.colors.mutedForeground,
                                ),
                              ),
                              Text(
                                '${item.quantityOnHand.toStringAsFixed(item.quantityOnHand == item.quantityOnHand.roundToDouble() ? 0 : 1)} ${item.unit}',
                                style: theme.typography.display.sm.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: item.isOutOfStock
                                      ? theme.colors.destructive
                                      : item.isLowStock
                                      ? Colors.orange
                                      : theme.colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Riwayat Penyesuaian',
                    style: theme.typography.body.md.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('Belum ada riwayat transaksi.'),
                      ),
                    )
                  else
                    ...transactions.map((tx) {
                      final isPositive = tx.delta > 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FCard(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isPositive
                                        ? theme.colors.primary.withValues(
                                            alpha: 0.1,
                                          )
                                        : theme.colors.destructive.withValues(
                                            alpha: 0.1,
                                          ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPositive
                                        ? LucideIcons.arrowUpRight
                                        : LucideIcons.arrowDownRight,
                                    color: isPositive
                                        ? theme.colors.primary
                                        : theme.colors.destructive,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.reason.isNotEmpty
                                            ? tx.reason
                                            : (isPositive
                                                  ? 'Penambahan Stok'
                                                  : 'Pengurangan Stok'),
                                        style: theme.typography.body.sm
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dateFormat.format(tx.createdAt),
                                        style: theme.typography.body.xs
                                            .copyWith(
                                              color:
                                                  theme.colors.mutedForeground,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isPositive ? "+" : ""}${tx.delta.toStringAsFixed(tx.delta == tx.delta.roundToDouble() ? 0 : 1)}',
                                  style: theme.typography.body.md.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isPositive
                                        ? theme.colors.primary
                                        : theme.colors.destructive,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildInfoRow(FThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.typography.body.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          Text(
            value,
            style: theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
