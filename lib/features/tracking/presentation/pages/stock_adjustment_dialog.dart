import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    final item = widget.item;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.add_shopping_cart_outlined,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sesuaikan Stok',
              style: theme.textTheme.titleMedium?.copyWith(
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Stok saat ini: ',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        Text(
                          '${item.quantityOnHand.toStringAsFixed(item.quantityOnHand == item.quantityOnHand.roundToDouble() ? 0 : 1)} ${item.unit}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: item.isLowStock
                                ? Colors.red
                                : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (item.minThreshold != null && item.minThreshold! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Min. threshold: ${item.minThreshold!.toStringAsFixed(item.minThreshold! == item.minThreshold!.roundToDouble() ? 0 : 1)} ${item.unit}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Increment / Decrement toggle
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Tambah'),
                    icon: Icon(Icons.add_circle_outline, size: 18),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Kurang'),
                    icon: Icon(Icons.remove_circle_outline, size: 18),
                  ),
                ],
                selected: {_isIncrement},
                onSelectionChanged: (selected) {
                  setState(() {
                    _isIncrement = selected.first;
                    _quantityController.clear();
                  });
                },
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
              const SizedBox(height: 16),

              // Quantity input
              TextFormField(
                key: const ValueKey<String>('adjust_quantity_input'),
                controller: _quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: _isIncrement
                      ? 'Jumlah yang ditambahkan'
                      : 'Jumlah yang dikurangi',
                  prefixIcon: Icon(
                    _isIncrement
                        ? Icons.add_circle_outline
                        : Icons.remove_circle_outline,
                    size: 20,
                  ),
                  suffixText: item.unit,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Masukkan jumlah';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Masukkan angka positif yang valid';
                  }
                  if (!_isIncrement && parsed > item.quantityOnHand) {
                    return 'Stok tidak mencukupi (hanya ${item.quantityOnHand.toStringAsFixed(1)} ${item.unit})';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // Reason / notes (optional)
              TextFormField(
                controller: _reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Alasan / catatan transaksi (opsional)',
                  prefixIcon: Icon(Icons.description_outlined, size: 20),
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
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withAlpha(15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.teal.withAlpha(76)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Stok baru:',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${newQuantity.toStringAsFixed(newQuantity == newQuantity.roundToDouble() ? 0 : 1)} ${item.unit}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.teal,
                            ),
                          ),
                        ],
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          key: const ValueKey<String>('confirm_adjust_stock_button'),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Konfirmasi'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final delta = double.parse(_quantityController.text.trim());
              final finalDelta = _isIncrement ? delta : -delta;
              final reason = _reasonController.text.trim().isNotEmpty
                  ? _reasonController.text.trim()
                  : null;

              widget.onAdjust(finalDelta, reason);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }

  /// Helper to parse quantity text to double in a Future for FutureBuilder.
  Future<double> _parseQuantity(String text) async {
    return double.tryParse(text) ?? 0.0;
  }
}
