import 'dart:async';

// Material: this file uses a Material primitive with no ForUI equivalent.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/core/presentation/widgets/form_max_width.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/inventory/inventory_state.dart';
import 'package:go_router/go_router.dart';

/// Screen allowing foremen to create or edit an inventory item
/// with name, category, unit, quantity on hand, minimum threshold, SKU, and notes.
class InventoryItemEntryScreen extends StatelessWidget {
  final TrackingRepository repository;
  final String siteId;
  final InventoryItem? existingItem;
  final String? itemId;
  final String? initialZoneId;
  final Uri? routeUri;
  final dynamic zoneRepository;

  const InventoryItemEntryScreen({
    super.key,
    required this.repository,
    required this.siteId,
    this.existingItem,
    this.itemId,
    this.initialZoneId,
    this.routeUri,
    this.zoneRepository,
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
      child: _InventoryItemFormView(routeUri: routeUri),
    );
  }
}

class _InventoryItemFormView extends StatefulWidget {
  final Uri? routeUri;
  const _InventoryItemFormView({this.routeUri});

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
  Timer? _popTimer;

  /// STEP-55.11: one-shot guard — the timer's pop and the sheet's
  /// `PopScope` re-entry can both fire for one save (the programmatic
  /// `context.pop()` is intercepted by the sheet's `canPop: false`).
  bool _hasClosed = false;

  void _handleClose() {
    if (_hasClosed) return;
    _hasClosed = true;
    _popTimer?.cancel();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.inventory);
    }
  }

  /// CF-038: validate required fields before saving (name + category required,
  /// non-negative quantity).
  void _validateAndSave(BuildContext context, InventoryFormState state) {
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
      showFToast(
        context: context,
        variant: FToastVariant.destructive,
        title: Text(error),
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
      // CF-054: dispatch on every change — null clears instead of retaining.
      context.read<InventoryBloc>().add(
        QuantityOnHandChangedEvent(double.tryParse(_quantityController.text)),
      );
    });
    _thresholdController.addListener(() {
      context.read<InventoryBloc>().add(
        MinThresholdChangedEvent(double.tryParse(_thresholdController.text)),
      );
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

  @override
  void dispose() {
    _popTimer?.cancel();
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
    final theme = FTheme.of(context);
    final routeIdentity = widget.routeUri?.toString() ?? 'inventory-form';

    return BlocConsumer<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventoryFormState) {
          if (state.errorMessage != null) {
            showFToast(
              context: context,
              variant: FToastVariant.destructive,
              title: Text(state.errorMessage!),
            );
          }
          if (state.successMessage != null) {
            showFToast(context: context, title: Text(state.successMessage!));

            _popTimer?.cancel();
            // STEP-55.11: this delayed pop races the sheet's PopScope
            // dismissal — a back press during the window pops while the
            // navigator is still locked (`!_debugLocked` on both paths).
            // Cancel any in-flight timer and only pop when the route is
            // still mounted and able to pop.
            _popTimer = Timer(const Duration(milliseconds: 600), () {
              if (!mounted) return;
              _handleClose();
            });
          }
        }
      },
      builder: (context, state) {
        if (state is InventoryLoading || state is InventoryInitial) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: 'Item Inventori',
            mode: AppResponsiveSheetMode.form,
            onDismissApproved: _handleClose,
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
            title: 'Item Inventori',
            mode: AppResponsiveSheetMode.form,
            onDismissApproved: _handleClose,
            body: AppStatePanel(
              title: 'Gagal Memuat',
              message: state.message,
              actionLabel: 'Coba Lagi',
              onAction: () {
                context.read<InventoryBloc>().add(
                  const SaveInventoryItemEvent(),
                );
              },
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

          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: item.id.isEmpty ? 'Tambah Item' : 'Ubah Item',
            mode: AppResponsiveSheetMode.form,
            isDirty: state.hasUnsavedChanges,
            isBusy: state.isSaving,
            onDismissApproved: _handleClose,
            footer: SizedBox(
              width: double.infinity,
              child: FButton(
                key: const ValueKey<String>('save_inventory_item_button'),
                size: FButtonSizeVariant.lg,
                onPress: state.isSaving
                    ? null
                    : () => _validateAndSave(context, state),
                child: Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      state.isSaving ? 'Menyimpan...' : 'Simpan Item Inventori',
                    ),
                  ),
                ),
              ),
            ),
            body: FormMaxWidth(
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
                    FTextField(
                      control: FTextFieldControl.managed(
                        controller: _nameController,
                      ),
                      hint: 'Contoh: Solar, Batu Bara, Safety Helmet',
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
                          isExpanded: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Pilih kategori',
                            prefixIcon: Icon(LucideIcons.shapes),
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
                        child: Localizations(
                          locale:
                              Localizations.maybeLocaleOf(context) ??
                              const Locale('id'),
                          delegates: GlobalMaterialLocalizations.delegates,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: theme.colors.muted,
                              borderRadius: BorderRadius.circular(8),
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
