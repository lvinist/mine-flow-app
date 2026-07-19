import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_state.dart';

/// Screen allowing foremen to create or edit an inventory item
/// with name, category, unit, quantity on hand, minimum threshold, SKU, and notes.
class InventoryItemEntryScreen extends StatelessWidget {
  final TrackingRepository repository;
  final String siteId;
  final InventoryItem? existingItem;
  final String? initialZoneId;

  const InventoryItemEntryScreen({
    super.key,
    required this.repository,
    required this.siteId,
    this.existingItem,
    this.initialZoneId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InventoryBloc(repository: repository)
        ..add(
          InitializeInventoryItemFormEvent(
            siteId: siteId,
            zoneId: initialZoneId ?? existingItem?.zoneId,
            existingItem: existingItem,
          ),
        ),
      child: const _InventoryItemFormView(),
    );
  }
}

class _InventoryItemFormView extends StatefulWidget {
  const _InventoryItemFormView();

  @override
  State<_InventoryItemFormView> createState() => _InventoryItemFormViewState();
}

class _InventoryItemFormViewState extends State<_InventoryItemFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _thresholdController;
  late TextEditingController _skuController;
  late TextEditingController _notesController;
  late TextEditingController _unitController;

  /// Custom unit option if not in predefined list.
  static const List<String> _unitOptions = [
    'pcs',
    'Liter',
    'Kg',
    'Ton',
    'Meter',
    'Drum',
    'Box',
    'Roll',
    'Pasang',
    'Set',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _quantityController = TextEditingController();
    _thresholdController = TextEditingController();
    _skuController = TextEditingController();
    _notesController = TextEditingController();
    _unitController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    _skuController.dispose();
    _notesController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventoryFormState) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green.shade700,
              ),
            );

            // Pop back after successful save
            Future.delayed(const Duration(milliseconds: 600), () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
          }
        }
      },
      builder: (context, state) {
        if (state is InventoryLoading || state is InventoryInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is InventoryError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Item Inventori')),
            body: Center(
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
                        const SaveInventoryItemEvent(),
                      );
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is InventoryFormState) {
          final item = state.item;

          // Sync controllers with BLoC state
          if (_nameController.text != item.itemName) {
            _nameController.value = TextEditingValue(
              text: item.itemName,
              selection: TextSelection.collapsed(offset: item.itemName.length),
            );
          }
          final qtyText = item.quantityOnHand.toStringAsFixed(
            item.quantityOnHand == item.quantityOnHand.roundToDouble() ? 0 : 1,
          );
          if (_quantityController.text != qtyText) {
            _quantityController.value = TextEditingValue(
              text: qtyText,
              selection: TextSelection.collapsed(offset: qtyText.length),
            );
          }
          final thresholdValue = item.minThreshold ?? 0.0;
          final threshText = thresholdValue.toStringAsFixed(
            thresholdValue == thresholdValue.roundToDouble() ? 0 : 1,
          );
          if (_thresholdController.text != threshText) {
            _thresholdController.value = TextEditingValue(
              text: threshText,
              selection: TextSelection.collapsed(offset: threshText.length),
            );
          }
          if (_skuController.text != (item.sku ?? '')) {
            _skuController.value = TextEditingValue(
              text: item.sku ?? '',
              selection: TextSelection.collapsed(
                offset: (item.sku ?? '').length,
              ),
            );
          }
          if (_notesController.text != (item.notes ?? '')) {
            _notesController.value = TextEditingValue(
              text: item.notes ?? '',
              selection: TextSelection.collapsed(
                offset: (item.notes ?? '').length,
              ),
            );
          }
          if (_unitController.text != item.unit) {
            _unitController.value = TextEditingValue(
              text: item.unit,
              selection: TextSelection.collapsed(offset: item.unit.length),
            );
          }

          return Scaffold(
            appBar: AppBar(title: const Text('Item Inventori')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Name
                    Text(
                      'Nama Item',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Solar, Batu Bara, Safety Helmet',
                        prefixIcon: Icon(Icons.inventory_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama item tidak boleh kosong';
                        }
                        return null;
                      },
                      onChanged: (text) {
                        context.read<InventoryBloc>().add(
                          ItemNameChangedEvent(text),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    Text(
                      'Kategori',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: theme.colorScheme.outline,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: DropdownButtonFormField<String>(
                          initialValue: item.category,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Pilih kategori',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: InventoryBloc.categories
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            context.read<InventoryBloc>().add(
                              InventoryCategoryChangedEvent(value),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Unit of Measure
                    Text(
                      'Satuan',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: theme.colorScheme.outline,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: DropdownButtonFormField<String>(
                          initialValue: _unitOptions.contains(item.unit)
                              ? item.unit
                              : null,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Pilih satuan',
                            prefixIcon: Icon(Icons.scale_outlined),
                          ),
                          items: _unitOptions
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _unitController.text = value;
                              context.read<InventoryBloc>().add(
                                UnitChangedEvent(value),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    if (!_unitOptions.contains(item.unit)) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          hintText: 'Satuan kustom',
                          prefixIcon: Icon(Icons.edit_outlined),
                        ),
                        onChanged: (text) {
                          context.read<InventoryBloc>().add(
                            UnitChangedEvent(text),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Quantity on Hand
                    Text(
                      'Jumlah Stok',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixIcon: const Icon(Icons.numbers_outlined),
                        suffixText: item.unit,
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final parsed = double.tryParse(value);
                          if (parsed == null || parsed < 0) {
                            return 'Masukkan angka positif yang valid';
                          }
                        }
                        return null;
                      },
                      onChanged: (text) {
                        final parsed = double.tryParse(text);
                        if (parsed != null) {
                          context.read<InventoryBloc>().add(
                            QuantityOnHandChangedEvent(parsed),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Minimum Threshold
                    Text(
                      'Level Minimum (Peringatan Stok Rendah)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _thresholdController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixIcon: const Icon(Icons.warning_amber_outlined),
                        suffixText: item.unit,
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final parsed = double.tryParse(value);
                          if (parsed == null || parsed < 0) {
                            return 'Masukkan angka positif yang valid';
                          }
                        }
                        return null;
                      },
                      onChanged: (text) {
                        final parsed = double.tryParse(text);
                        if (parsed != null) {
                          context.read<InventoryBloc>().add(
                            MinThresholdChangedEvent(parsed),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // SKU (optional)
                    Text(
                      'SKU (opsional)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(
                        hintText: 'Kode SKU / barcode',
                        prefixIcon: Icon(Icons.qr_code_outlined),
                      ),
                      onChanged: (text) {
                        context.read<InventoryBloc>().add(
                          SkuChangedEvent(text.isNotEmpty ? text : null),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    Text(
                      'Catatan',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Catatan tambahan tentang item ini...',
                      ),
                      onChanged: (text) {
                        context.read<InventoryBloc>().add(
                          InventoryNotesChangedEvent(text),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        key: const ValueKey<String>(
                          'save_inventory_item_button',
                        ),
                        icon: state.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          state.isSaving
                              ? 'Menyimpan...'
                              : 'Simpan Item Inventori',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        onPressed: state.isSaving
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<InventoryBloc>().add(
                                    const SaveInventoryItemEvent(),
                                  );
                                }
                              },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
