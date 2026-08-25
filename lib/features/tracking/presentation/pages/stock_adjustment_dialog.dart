import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';

/// Quick modal dialog to increment/decrement item stock with a transaction reason.
/// Returns a tuple of (deltaQuantity, reason) via [onAdjust] callback.
class StockAdjustmentDialog extends StatefulWidget {
  final InventoryItem item;
  final void Function(double deltaQuantity, String? reason) onAdjust;

  const StockAdjustmentDialog({
    super.key,
    required this.item,
    required this.onAdjust,
  });

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _reasonController;
  bool _isIncrement = true;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final item = widget.item;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.add_shopping_cart_outlined,
            color: theme.colors.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sesuaikan Stok',
              style: theme.typography.body.md.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current stock display
              FCard(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: theme.typography.body.sm.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Stok saat ini: ',
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          Text(
                            '${item.quantityOnHand.toStringAsFixed(item.quantityOnHand == item.quantityOnHand.roundToDouble() ? 0 : 1)} ${item.unit}',
                            style: theme.typography.body.sm.copyWith(
                              fontWeight: FontWeight.bold,
                              color: item.isLowStock
                                  ? theme.colors.destructive
                                  : theme.colors.primary,
                            ),
                          ),
                        ],
                      ),
                      if (item.minThreshold != null && item.minThreshold! > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Min. threshold: ${item.minThreshold!.toStringAsFixed(item.minThreshold! == item.minThreshold!.roundToDouble() ? 0 : 1)} ${item.unit}',
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Increment / Decrement toggle
              Row(
                children: [
                  Expanded(
                    child: FButton(
                      onPress: () {
                        setState(() {
                          _isIncrement = true;
                          _quantityController.clear();
                        });
                      },
                      child: const Text('Tambah'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FButton(
                      onPress: () {
                        setState(() {
                          _isIncrement = false;
                          _quantityController.clear();
                        });
                      },
                      child: const Text('Kurang'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quantity input
              TextFormField(
                key: const ValueKey<String>('adjust_quantity_input'),
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: theme.typography.body.md,
                decoration: InputDecoration(
                  hintText: _isIncrement
                      ? 'Jumlah yang ditambahkan (${item.unit})'
                      : 'Jumlah yang dikurangi (${item.unit})',
                  hintStyle: theme.typography.body.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Reason / notes (optional)
              TextFormField(
                controller: _reasonController,
                style: theme.typography.body.md,
                decoration: InputDecoration(
                  hintText: 'Alasan / catatan transaksi (opsional)',
                  hintStyle: theme.typography.body.xs.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),

              // Preview
              if (_quantityController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                FutureBuilder<double>(
                  future: _parseQuantity(_quantityController.text),
                  builder: (context, snapshot) {
                    final parsed = snapshot.data;
                    if (parsed == null || parsed <= 0) {
                      return const SizedBox.shrink();
                    }
                    final newQuantity = _isIncrement
                        ? item.quantityOnHand + parsed
                        : (item.quantityOnHand - parsed).clamp(
                            0.0,
                            double.infinity,
                          );
                    return FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Stok baru:', style: theme.typography.body.xs),
                            Text(
                              '${newQuantity.toStringAsFixed(newQuantity == newQuantity.roundToDouble() ? 0 : 1)} ${item.unit}',
                              style: theme.typography.body.sm.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FButton(
          onPress: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FButton(
          key: const ValueKey<String>('confirm_adjust_stock_button'),
          onPress: () {
            final delta = double.tryParse(_quantityController.text.trim());
            if (delta != null && delta > 0) {
              final finalDelta = _isIncrement ? delta : -delta;
              final reason = _reasonController.text.trim().isNotEmpty
                  ? _reasonController.text.trim()
                  : null;

              widget.onAdjust(finalDelta, reason);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Konfirmasi'),
        ),
      ],
    );
  }

  /// Helper to parse quantity text to double in a Future for FutureBuilder.
  Future<double> _parseQuantity(String text) async {
    return double.tryParse(text) ?? 0.0;
  }
}
