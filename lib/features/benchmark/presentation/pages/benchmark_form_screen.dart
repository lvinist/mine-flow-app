import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/core/presentation/widgets/form_max_width.dart';
import 'package:mine_flow/core/presentation/widgets/creatable_combobox.dart';
import 'package:mine_flow/features/benchmark/domain/entities/benchmark.dart';
import 'package:mine_flow/features/benchmark/domain/repositories/benchmark_repository.dart';
import 'package:mine_flow/features/benchmark/presentation/bloc/benchmark_bloc.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

/// Form screen for creating or editing a survey control point benchmark.
///
/// When [existingBenchmark] is non-null, or [benchmarkId] is provided, the form loads
/// in edit mode. Latitude and Longitude fields are read-only and auto-computed
/// from Northing/Easting/CRS via [CrsUtils].
class BenchmarkFormScreen extends StatelessWidget {
  final BenchmarkRepository repository;
  final String? benchmarkId;
  final Benchmark? existingBenchmark;
  final Uri? routeUri;
  final VoidCallback? onClose;

  const BenchmarkFormScreen({
    super.key,
    required this.repository,
    this.benchmarkId,
    this.existingBenchmark,
    this.routeUri,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = BenchmarkBloc(repository: repository);
        if (existingBenchmark != null) {
          bloc.add(EditBenchmark(existingBenchmark!));
        } else if (benchmarkId != null) {
          bloc.add(LoadBenchmarkById(benchmarkId!));
        } else {
          bloc.add(const CreateBenchmark());
        }
        return bloc;
      },
      child: _BenchmarkFormBody(
        benchmarkId: benchmarkId,
        existingBenchmark: existingBenchmark,
        routeUri: routeUri,
        onClose: onClose,
      ),
    );
  }
}

class _BenchmarkFormBody extends StatefulWidget {
  final String? benchmarkId;
  final Benchmark? existingBenchmark;
  final Uri? routeUri;
  final VoidCallback? onClose;

  const _BenchmarkFormBody({
    this.benchmarkId,
    this.existingBenchmark,
    this.routeUri,
    this.onClose,
  });

  @override
  State<_BenchmarkFormBody> createState() => _BenchmarkFormBodyState();
}

class _BenchmarkFormBodyState extends State<_BenchmarkFormBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bmIdController;
  late final TextEditingController _northingController;
  late final TextEditingController _eastingController;
  late final TextEditingController _orthoHeightController;
  late final TextEditingController _codeController;
  late final TextEditingController _ellipsHeightController;

  bool _initialSyncDone = false;

  bool get _isEdit =>
      widget.existingBenchmark != null ||
      (widget.benchmarkId != null && widget.benchmarkId!.isNotEmpty);

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

  /// STEP-55.11: one-shot guard — the success close and the sheet's
  /// `PopScope` re-entry can both reach `_handleClose` for one save.
  bool _hasClosed = false;

  void _handleClose() {
    if (_hasClosed) return;
    if (widget.onClose != null) {
      _hasClosed = true;
      widget.onClose!();
      return;
    }
    _hasClosed = true;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.benchmarkDb);
    }
  }

  void _validateAndSubmit(BuildContext context) {
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
      showFToast(
        context: context,
        variant: FToastVariant.destructive,
        title: Text(error),
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

  static const _crsOptions = [
    'UTM Zone 50S',
    'UTM Zone 51S',
    'UTM Zone 52S',
    'UTM Zone 50N',
    'UTM Zone 51N',
    'UTM Zone 52N',
  ];

  static const _ordeOptions = [
    '',
    '1st Order',
    '2nd Order',
    '3rd Order',
    '4th Order',
  ];

  static const _statusOptions = ['active', 'destroyed', 'replaced'];

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return BlocConsumer<BenchmarkBloc, BenchmarkState>(
      listener: (context, state) {
        if (state is BenchmarkSuccess) {
          showFToast(context: context, title: Text(state.message));
          // STEP-55.11: the delayed close raced the sheet's PopScope
          // dismissal, so a system/test back press could land during the
          // delay and call pop() again while the navigator was locked
          // (`!_debugLocked` on both pop paths). Guard the second pop: only
          // close when the route is still mounted and can actually pop.
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!context.mounted) return;
            _handleClose();
          });
        }
        if (state is BenchmarkError) {
          final l10n = AppLocalizations.of(context);
          final title = state.message == kBenchmarkProjectionFailureMessage
              ? l10n.crsProjectionFailure
              : state.message;
          showFToast(
            context: context,
            variant: FToastVariant.destructive,
            title: Text(title),
          );
        }
      },
      builder: (context, state) {
        final routeIdentity = widget.routeUri?.toString() ?? 'benchmark-form';

        if (state is! BenchmarkFormState) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: _isEdit ? 'Edit Benchmark' : 'Tambah Benchmark',
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

        final form = state;
        _syncControllers(form);

        return AppResponsiveSheet(
          routeIdentity: routeIdentity,
          title: _isEdit ? 'Edit Benchmark' : 'Tambah Benchmark',
          mode: AppResponsiveSheetMode.form,
          // We can use a simple dirty check if we want, but D4 requires a guard.
          // In the bloc, any typing triggers state changes. For simplicity we assume dirty if text controllers changed.
          // Note: AppResponsiveSheet requires isDirty.
          isDirty: true,
          isBusy: false,
          onDismissApproved: _handleClose,
          footer: SizedBox(
            width: double.infinity,
            child: FButton(
              onPress: () => _validateAndSubmit(context),
              child: const Text('Simpan Benchmark'),
            ),
          ),
          body: FormMaxWidth(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Identitas Benchmark',
                              style: theme.typography.body.lg.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FTextField(
                              control: FTextFieldControl.managed(
                                controller: _bmIdController,
                              ),
                              label: const Text('BM ID'),
                              hint: 'Masukkan BM ID (contoh: BM-01)',
                            ),
                            const SizedBox(height: 16),
                            FTextField(
                              control: FTextFieldControl.managed(
                                controller: _codeController,
                              ),
                              label: const Text('Kode / Deskripsi'),
                              hint: 'Opsional (contoh: Control Point Utama)',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Sistem Koordinat & Status',
                              style: theme.typography.body.lg.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CreatableCombobox<String>(
                              items: _crsOptions,
                              labelBuilder: (crs) => crs,
                              label: 'CRS / Datum',
                              hint: 'Pilih sistem proyeksi...',
                              initialValue: form.crsIdentifier,
                              onChanged: (val) {
                                context.read<BenchmarkBloc>().add(
                                  FormCrsChanged(val),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            CreatableCombobox<String>(
                              items: _ordeOptions,
                              labelBuilder: (orde) =>
                                  orde.isEmpty ? 'Pilih Orde...' : orde,
                              label: 'Orde',
                              hint: 'Pilih Orde...',
                              initialValue: form.orde,
                              onChanged: (val) {
                                context.read<BenchmarkBloc>().add(
                                  FormOrdeChanged(val),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            CreatableCombobox<String>(
                              items: _statusOptions,
                              labelBuilder: (status) => status,
                              label: 'Status',
                              hint: 'Pilih Status...',
                              initialValue: form.status,
                              onChanged: (val) {
                                context.read<BenchmarkBloc>().add(
                                  FormStatusChanged(val),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Koordinat Grid (Proyeksi)',
                              style: theme.typography.body.lg.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FTextField(
                              control: FTextFieldControl.managed(
                                controller: _eastingController,
                              ),
                              label: const Text('Easting (X)'),
                              hint: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            FTextField(
                              control: FTextFieldControl.managed(
                                controller: _northingController,
                              ),
                              label: const Text('Northing (Y)'),
                              hint: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            FTextField(
                              control: FTextFieldControl.managed(
                                controller: _orthoHeightController,
                              ),
                              label: const Text('Tinggi Orthometrik (Z)'),
                              hint: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            FTextField(
                              control: FTextFieldControl.managed(
                                controller: _ellipsHeightController,
                              ),
                              label: const Text('Tinggi Elipsoid (Opsional)'),
                              hint: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Koordinat Geografis (Otomatis)',
                              style: theme.typography.body.lg.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FTextField(
                              control: FTextFieldControl.lifted(
                                value: TextEditingValue(
                                  text:
                                      form.computedLatitude?.toStringAsFixed(
                                        8,
                                      ) ??
                                      'Tidak valid',
                                ),
                                onChange: (_) {},
                              ),
                              label: const Text('Latitude'),
                              enabled: false,
                            ),
                            const SizedBox(height: 16),
                            FTextField(
                              control: FTextFieldControl.lifted(
                                value: TextEditingValue(
                                  text:
                                      form.computedLongitude?.toStringAsFixed(
                                        8,
                                      ) ??
                                      'Tidak valid',
                                ),
                                onChange: (_) {},
                              ),
                              label: const Text('Longitude'),
                              enabled: false,
                            ),
                            if (form.computedLatitude == null ||
                                form.computedLongitude == null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colors.destructive.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: theme.style.borderRadius.sm,
                                  border: Border.all(
                                    color: theme.colors.destructive.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).crsProjectionFailure,
                                  style: theme.typography.body.sm.copyWith(
                                    color: theme.colors.destructive,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
