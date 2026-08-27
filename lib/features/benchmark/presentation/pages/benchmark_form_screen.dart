// Benchmark Form Screen — create/edit survey control points.
//
// Phase 2 ForUI design system (FThemes.zinc). Automatically computes Lat/Lon
// from user-entered Northing/Easting/CRS via CrsUtils.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/features/benchmark/domain/entities/benchmark.dart';
import 'package:mine_flow/features/benchmark/domain/repositories/benchmark_repository.dart';
import 'package:mine_flow/features/benchmark/presentation/bloc/benchmark_bloc.dart';

/// Form screen for creating or editing a survey control point benchmark.
///
/// When [existingBenchmark] is non-null, the form loads in edit mode with
/// the existing values pre-filled. Latitude and Longitude fields are read-only
/// and auto-computed from Northing/Easting/CRS via [CrsUtils].
class BenchmarkFormScreen extends StatelessWidget {
  final BenchmarkRepository repository;
  final Benchmark? existingBenchmark;

  const BenchmarkFormScreen({
    super.key,
    required this.repository,
    this.existingBenchmark,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BenchmarkBloc(repository: repository)
        ..add(
          existingBenchmark != null
              ? EditBenchmark(existingBenchmark!)
              : const CreateBenchmark(),
        ),
      child: _BenchmarkFormBody(existingBenchmark: existingBenchmark),
    );
  }
}

class _BenchmarkFormBody extends StatefulWidget {
  final Benchmark? existingBenchmark;

  const _BenchmarkFormBody({this.existingBenchmark});

  @override
  State<_BenchmarkFormBody> createState() => _BenchmarkFormBodyState();
}

class _BenchmarkFormBodyState extends State<_BenchmarkFormBody> {
  late final TextEditingController _bmIdController;
  late final TextEditingController _northingController;
  late final TextEditingController _eastingController;
  late final TextEditingController _orthoHeightController;
  late final TextEditingController _codeController;
  late final TextEditingController _ellipsHeightController;

  @override
  void initState() {
    super.initState();
    _bmIdController = TextEditingController();
    _northingController = TextEditingController();
    _eastingController = TextEditingController();
    _orthoHeightController = TextEditingController();
    _codeController = TextEditingController();
    _ellipsHeightController = TextEditingController();

    // Wire up text controllers to BLoC events via listeners
    _bmIdController.addListener(() {
      context.read<BenchmarkBloc>().add(FormBmIdChanged(_bmIdController.text));
    });
    _northingController.addListener(() {
      final parsed = double.tryParse(_northingController.text);
      if (parsed != null) {
        context.read<BenchmarkBloc>().add(FormNorthingChanged(parsed));
      }
    });
    _eastingController.addListener(() {
      final parsed = double.tryParse(_eastingController.text);
      if (parsed != null) {
        context.read<BenchmarkBloc>().add(FormEastingChanged(parsed));
      }
    });
    _orthoHeightController.addListener(() {
      final parsed = double.tryParse(_orthoHeightController.text);
      if (parsed != null) {
        context.read<BenchmarkBloc>().add(FormOrthoHeightChanged(parsed));
      }
    });
    _codeController.addListener(() {
      context.read<BenchmarkBloc>().add(FormCodeChanged(_codeController.text));
    });
    _ellipsHeightController.addListener(() {
      final parsed = double.tryParse(_ellipsHeightController.text);
      if (parsed != null) {
        context.read<BenchmarkBloc>().add(FormEllipsHeightChanged(parsed));
      }
    });
  }

  @override
  void dispose() {
    _bmIdController.dispose();
    _northingController.dispose();
    _eastingController.dispose();
    _orthoHeightController.dispose();
    _codeController.dispose();
    _ellipsHeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return BlocConsumer<BenchmarkBloc, BenchmarkState>(
      listener: (context, state) {
        if (state is BenchmarkSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          Navigator.of(context).pop();
        }
        if (state is BenchmarkError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colors.destructive,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is! BenchmarkFormState) {
          return Scaffold(
            appBar: isDesktop
                ? null
                : AppBar(title: const Text('Form Benchmark')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final form = state;
        final isEditing = form.isEditing;

        // Sync controllers from BLoC state (only when state changes externally)
        // We only sync on first load or when editing benchmark changes
        _syncControllers(form);

        return Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
                  title: Text(
                    isEditing ? 'Edit Benchmark' : 'Tambah Benchmark',
                  ),
                  actions: [
                    FButton(
                      variant: FButtonVariant.ghost,
                      onPress: () =>
                          context.read<BenchmarkBloc>().add(const CancelForm()),
                      child: const Text('Batal'),
                    ),
                  ],
                ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Identitas Benchmark
                FCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.badgeCheck,
                              size: 18,
                              color: theme.colors.mutedForeground,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Identitas',
                              style: theme.typography.body.sm.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FTextField(
                          control: FTextFieldControl.managed(
                            controller: _bmIdController,
                          ),
                          label: const Text('BM ID'),
                          hint: 'Contoh: BM-001',
                        ),
                        const SizedBox(height: 12),
                        FTextField(
                          control: FTextFieldControl.managed(
                            controller: _codeController,
                          ),
                          label: const Text('Kode'),
                          hint: 'Contoh: PK, BM',
                        ),
                        const SizedBox(height: 12),
                        _StatusCombobox(
                          selectedStatus: form.status,
                          onChanged: (status) => context
                              .read<BenchmarkBloc>()
                              .add(FormStatusChanged(status)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Kordinat & Proyeksi
                FCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.compass,
                              size: 18,
                              color: theme.colors.mutedForeground,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Koordinat Proyeksi (UTM)',
                              style: theme.typography.body.sm.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _CrsCombobox(
                          selectedCrs: form.crsIdentifier,
                          onChanged: (crs) => context.read<BenchmarkBloc>().add(
                            FormCrsChanged(crs),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FTextField(
                                control: FTextFieldControl.managed(
                                  controller: _northingController,
                                ),
                                label: const Text('Northing (m)'),
                                hint: '0.00',
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FTextField(
                                control: FTextFieldControl.managed(
                                  controller: _eastingController,
                                ),
                                label: const Text('Easting (m)'),
                                hint: '0.00',
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const FDivider(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.globe,
                              size: 18,
                              color: theme.colors.mutedForeground,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Koordinat Geografis (Otomatis)',
                              style: theme.typography.body.sm.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              // CF-068: computed coords as selectable content,
                              // not a muted hint; explicit failure state.
                              child: _computedCoordinateField(
                                context,
                                'Latitude',
                                form.computedLatitude,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _computedCoordinateField(
                                context,
                                'Longitude',
                                form.computedLongitude,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Data Elevasi & Orde
                FCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.moveVertical,
                              size: 18,
                              color: theme.colors.mutedForeground,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Data Elevasi & Kualitas',
                              style: theme.typography.body.sm.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FTextField(
                                control: FTextFieldControl.managed(
                                  controller: _orthoHeightController,
                                ),
                                label: const Text('Ortho Height (m)'),
                                hint: '0.00',
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FTextField(
                                control: FTextFieldControl.managed(
                                  controller: _ellipsHeightController,
                                ),
                                label: const Text('Ellips Height (m)'),
                                hint: '0.00',
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _OrdeCombobox(
                          selectedOrde: form.orde,
                          onChanged: (orde) => context
                              .read<BenchmarkBloc>()
                              .add(FormOrdeChanged(orde)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    onPress: () => _validateAndSubmit(context),
                    child: Text(isEditing ? 'Simpan' : 'Tambah Benchmark'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Syncs text controllers from BLoC form state on first load or editing change.
  ///
  /// Uses a dirty flag to avoid infinite loops from the listener.
  bool _initialSyncDone = false;

  /// CF-034: validate required fields before dispatching submit. Blocks save on
  /// empty/invalid input (the bloc holds 0.0 defaults, so we check the raw text
  /// here to distinguish "blank" from a legitimate zero).
  /// CF-068: renders a computed coordinate as selectable content (or an
  /// explicit "could not compute" state), not as a muted hint.
  Widget _computedCoordinateField(
    BuildContext context,
    String label,
    double? value,
  ) {
    final theme = FTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.typography.body.xs.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: value == null
              ? Text(
                  'Tidak dapat dihitung',
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.mutedForeground,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : SelectableText(
                  value.toStringAsFixed(6),
                  style: theme.typography.body.sm,
                ),
        ),
      ],
    );
  }

  void _validateAndSubmit(BuildContext context) {
    final theme = FTheme.of(context);
    String? error;
    if (_bmIdController.text.trim().isEmpty) {
      error = 'BM ID tidak boleh kosong.';
    } else if (!_isValidNumber(_northingController.text)) {
      error = 'Northing harus berupa angka yang valid.';
    } else if (!_isValidNumber(_eastingController.text)) {
      error = 'Easting harus berupa angka yang valid.';
    } else if (!_isValidNumber(_orthoHeightController.text)) {
      error = 'Ortho Height harus berupa angka yang valid.';
    } else if (!_isValidNumber(_ellipsHeightController.text)) {
      error = 'Ellips Height harus berupa angka yang valid.';
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

    context.read<BenchmarkBloc>().add(const SubmitBenchmark());
  }

  bool _isValidNumber(String text) {
    if (text.trim().isEmpty) return false;
    return double.tryParse(text.trim()) != null;
  }

  void _syncControllers(BenchmarkFormState form) {
    if (!_initialSyncDone && mounted) {
      _initialSyncDone = true;
      _bmIdController.text = form.bmId;
      _codeController.text = form.code;
      if (form.isEditing) {
        // CF-035: populate the actual values regardless of sign — zero and
        // negative elevations (and coords) are legitimate. Only blank when the
        // form is genuinely unset (create mode).
        _northingController.text = form.northing.toString();
        _eastingController.text = form.easting.toString();
        _orthoHeightController.text = form.orthoHeight.toString();
        _ellipsHeightController.text = form.ellipsHeight.toString();
      } else {
        _northingController.text = '';
        _eastingController.text = '';
        _orthoHeightController.text = '';
        _ellipsHeightController.text = '';
      }
    }
  }
}

/// CRS selection combobox with common UTM zone options.
class _CrsCombobox extends StatelessWidget {
  final String selectedCrs;
  final ValueChanged<String> onChanged;

  const _CrsCombobox({required this.selectedCrs, required this.onChanged});

  static const _crsOptions = [
    'UTM Zone 50S',
    'UTM Zone 51S',
    'UTM Zone 52S',
    'UTM Zone 50N',
    'UTM Zone 51N',
    'UTM Zone 52N',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CRS',
          style: theme.typography.body.sm.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: _crsOptions.contains(selectedCrs) ? selectedCrs : null,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: _crsOptions.map((crs) {
            return DropdownMenuItem(value: crs, child: Text(crs));
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

/// Orde (order/grade) selection combobox.
class _OrdeCombobox extends StatelessWidget {
  final String selectedOrde;
  final ValueChanged<String> onChanged;

  const _OrdeCombobox({required this.selectedOrde, required this.onChanged});

  static const _ordeOptions = [
    '',
    '1st Order',
    '2nd Order',
    '3rd Order',
    '4th Order',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Orde',
          style: theme.typography.body.sm.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: _ordeOptions.contains(selectedOrde)
              ? selectedOrde
              : null,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: _ordeOptions.map((orde) {
            return DropdownMenuItem(
              value: orde,
              child: Text(orde.isEmpty ? 'Pilih Orde...' : orde),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

/// Status selection combobox.
class _StatusCombobox extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onChanged;

  const _StatusCombobox({
    required this.selectedStatus,
    required this.onChanged,
  });

  static const _statusOptions = ['active', 'destroyed', 'replaced'];

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: theme.typography.body.sm.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: _statusOptions.contains(selectedStatus)
              ? selectedStatus
              : null,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: _statusOptions.map((status) {
            return DropdownMenuItem(value: status, child: Text(status));
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}
