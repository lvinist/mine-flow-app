// Benchmark Form Screen — create/edit survey control points.
//
// Phase 2 ForUI design system (FThemes.zinc). Automatically computes Lat/Lon
// from user-entered Northing/Easting/CRS via CrsUtils.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
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

        final latText = form.computedLatitude?.toStringAsFixed(6) ?? '-';
        final lonText = form.computedLongitude?.toStringAsFixed(6) ?? '-';

        return Scaffold(
          appBar: isDesktop
              ? null
              : AppBar(
                  title: Text(isEditing ? 'Edit Benchmark' : 'Tambah Benchmark'),
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
                              Icon(Icons.badge_outlined, size: 18, color: theme.colors.mutedForeground),
                              const SizedBox(width: 8),
                              Text('Identitas', style: theme.typography.body.sm.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FTextField(
                            control: FTextFieldControl.managed(controller: _bmIdController),
                            label: const Text('BM ID'),
                            hint: 'Contoh: BM-001',
                          ),
                          const SizedBox(height: 12),
                          FTextField(
                            control: FTextFieldControl.managed(controller: _codeController),
                            label: const Text('Kode'),
                            hint: 'Contoh: PK, BM',
                          ),
                          const SizedBox(height: 12),
                          _StatusCombobox(
                            selectedStatus: form.status,
                            onChanged: (status) => context.read<BenchmarkBloc>().add(FormStatusChanged(status)),
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
                              Icon(Icons.explore_outlined, size: 18, color: theme.colors.mutedForeground),
                              const SizedBox(width: 8),
                              Text('Kordinat Proyeksi (UTM)', style: theme.typography.body.sm.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _CrsCombobox(
                            selectedCrs: form.crsIdentifier,
                            onChanged: (crs) => context.read<BenchmarkBloc>().add(FormCrsChanged(crs)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FTextField(
                                  control: FTextFieldControl.managed(controller: _northingController),
                                  label: const Text('Northing (m)'),
                                  hint: '0.00',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FTextField(
                                  control: FTextFieldControl.managed(controller: _eastingController),
                                  label: const Text('Easting (m)'),
                                  hint: '0.00',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.public, size: 18, color: theme.colors.mutedForeground),
                              const SizedBox(width: 8),
                              Text('Kordinat Geografis (Otomatis)', style: theme.typography.body.sm.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FTextField(
                                  enabled: false,
                                  label: const Text('Latitude'),
                                  hint: latText,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FTextField(
                                  enabled: false,
                                  label: const Text('Longitude'),
                                  hint: lonText,
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
                              Icon(Icons.height, size: 18, color: theme.colors.mutedForeground),
                              const SizedBox(width: 8),
                              Text('Data Elevasi & Kualitas', style: theme.typography.body.sm.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FTextField(
                                  control: FTextFieldControl.managed(controller: _orthoHeightController),
                                  label: const Text('Ortho Height (m)'),
                                  hint: '0.00',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FTextField(
                                  control: FTextFieldControl.managed(controller: _ellipsHeightController),
                                  label: const Text('Ellips Height (m)'),
                                  hint: '0.00',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _OrdeCombobox(
                            selectedOrde: form.orde,
                            onChanged: (orde) => context.read<BenchmarkBloc>().add(FormOrdeChanged(orde)),
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
                      onPress: () => context.read<BenchmarkBloc>().add(const SubmitBenchmark()),
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

  void _syncControllers(BenchmarkFormState form) {
    if (!_initialSyncDone && mounted) {
      _initialSyncDone = true;
      _bmIdController.text = form.bmId;
      _northingController.text = form.northing > 0
          ? form.northing.toString()
          : '';
      _eastingController.text = form.easting > 0 ? form.easting.toString() : '';
      _orthoHeightController.text = form.orthoHeight > 0
          ? form.orthoHeight.toString()
          : '';
      _codeController.text = form.code;
      _ellipsHeightController.text = form.ellipsHeight > 0
          ? form.ellipsHeight.toString()
          : '';
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
          initialValue: _ordeOptions.contains(selectedOrde) ? selectedOrde : null,
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
