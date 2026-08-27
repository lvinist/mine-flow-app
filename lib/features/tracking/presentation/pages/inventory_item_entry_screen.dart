import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';
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
  final _nameFocusNode = FocusNode();
  Timer? _popTimer;

  /// CF-038: validate required fields before saving (name + category required,
  /// non-negative quantity).
  void _validateAndSave(BuildContext context, InventoryFormState state) {
    final theme = FTheme.of(context);
    final item = state.item;
    String? error;
    if (item.itemName.trim().isEmpty) {
      error = 'Nama item tidak boleh kosong.';
    } else if (item.category == null || item.category!.isEmpty) {
      error = 'Pilih kategori terlebih dahulu.';
    } else if (item.quantityOnHand < 0) {
      error = 'Jumlah tidak boleh negatif.';
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: theme.colors.destructive,
        ),
      );
      return;
    }

    context.read<InventoryBloc>().add(const SaveInventoryItemEvent());
  }

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
    _nameFocusNode.addListener(_onNameFocusChanged);

    _nameController.addListener(
      () => context.read<InventoryBloc>().add(
        ItemNameChangedEvent(_nameController.text),
      ),
    );
    _unitController.addListener(
      () => context.read<InventoryBloc>().add(
        UnitChangedEvent(_unitController.text),
      ),
    );
    _quantityController.addListener(() {
      final parsed = double.tryParse(_quantityController.text);
      if (parsed != null) {
        context.read<InventoryBloc>().add(QuantityOnHandChangedEvent(parsed));
      }
    });
    _thresholdController.addListener(() {
      final parsed = double.tryParse(_thresholdController.text);
      if (parsed != null) {
        context.read<InventoryBloc>().add(MinThresholdChangedEvent(parsed));
      }
    });
    _skuController.addListener(() {
      final text = _skuController.text;
      context.read<InventoryBloc>().add(
        SkuChangedEvent(text.isNotEmpty ? text : null),
      );
    });
    _notesController.addListener(
      () => context.read<InventoryBloc>().add(
        InventoryNotesChangedEvent(_notesController.text),
      ),
    );
  }

  void _onNameFocusChanged() {}

  @override
  void dispose() {
    _popTimer?.cancel();
    _nameController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    _skuController.dispose();
    _notesController.dispose();
    _unitController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return BlocConsumer<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventoryFormState) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colors.destructive,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: theme.colors.primary,
              ),
            );

            // CF-051: use a cancellable timer tied to this State's lifetime so
            // a timed pop can't fire on the now-current route after dispose.
            _popTimer?.cancel();
            _popTimer = Timer(const Duration(milliseconds: 600), () {
              if (mounted) {
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
            appBar: MediaQuery.of(context).size.width > 800
                ? null
                : AppBar(title: const Text('Item Inventori')),
            body: Center(
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
                    onPress: () {
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
            appBar: MediaQuery.of(context).size.width > 800
                ? null
                : AppBar(title: const Text('Item Inventori')),
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
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Focus(
                      focusNode: _nameFocusNode,
                      child: FTextField(
                        control: FTextFieldControl.managed(
                          controller: _nameController,
                        ),
                        hint: 'Contoh: Solar, Batu Bara, Safety Helmet',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    Text(
                      'Kategori',
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FCard(
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

                    // Merged Jumlah & Satuan
                    Text(
                      'Jumlah & Satuan Stok',
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FTextField(
                      control: FTextFieldControl.managed(
                        controller: _quantityController,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hint: 'Jumlah (0)',
                      suffixBuilder: (context, style, variants) => Padding(
                        padding: const EdgeInsetsDirectional.only(end: 4),
                        // forui 0.26 wraps FTextField in its own Localizations
                        // scope (material_ui's MaterialLocalizations is a
                        // distinct type from flutter/material's), which
                        // transiently starves any Material widget below it.
                        // Re-inject the app's material localizations here so
                        // DropdownButton always finds a valid ancestor.
                        child: Localizations(
                          locale:
                              Localizations.maybeLocaleOf(context) ??
                              const Locale('id'),
                          delegates: GlobalMaterialLocalizations.delegates,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: theme.colors.muted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _unitOptions.contains(item.unit)
                                    ? item.unit
                                    : null,
                                hint: Text(
                                  'Satuan',
                                  style: theme.typography.body.xs.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                                isDense: true,
                                dropdownColor: theme.colors.background,
                                style: theme.typography.body.sm.copyWith(
                                  color: theme.colors.foreground,
                                ),
                                items: _unitOptions
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(u),
                                      ),
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
                        ),
                      ),
                    ),
                    if (!_unitOptions.contains(item.unit) &&
                        item.unit.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      FTextField(
                        control: FTextFieldControl.managed(
                          controller: _unitController,
                        ),
                        hint: 'Satuan kustom',
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Minimum Threshold
                    Text(
                      'Level Minimum (Peringatan Stok Rendah)',
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FTextField(
                      control: FTextFieldControl.managed(
                        controller: _thresholdController,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hint: '0',
                    ),
                    const SizedBox(height: 16),

                    // SKU (optional)
                    Text(
                      'SKU (opsional)',
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FTextField(
                      control: FTextFieldControl.managed(
                        controller: _skuController,
                      ),
                      hint: 'Kode SKU / barcode',
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    Text(
                      'Catatan',
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FTextField(
                      control: FTextFieldControl.managed(
                        controller: _notesController,
                      ),
                      maxLines: 3,
                      hint: 'Catatan tambahan tentang item ini...',
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: FButton(
                        key: const ValueKey<String>(
                          'save_inventory_item_button',
                        ),
                        onPress: state.isSaving
                            ? null
                            : () => _validateAndSave(context, state),
                        child: Text(
                          state.isSaving
                              ? 'Menyimpan...'
                              : 'Simpan Item Inventori',
                        ),
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
