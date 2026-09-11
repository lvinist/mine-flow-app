import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/core/presentation/widgets/confirm_destructive_action.dart';
import 'package:mine_flow/features/benchmark/domain/entities/benchmark.dart';
import 'package:mine_flow/features/benchmark/domain/repositories/benchmark_repository.dart';
import 'package:mine_flow/features/benchmark/presentation/bloc/benchmark_bloc.dart';

/// Responsive modal sheet displaying details of a benchmark record.
class BenchmarkInspectorScreen extends StatelessWidget {
  final BenchmarkRepository repository;
  final String benchmarkId;
  final Benchmark? existingBenchmark;
  final Uri? routeUri;
  final VoidCallback? onClose;

  const BenchmarkInspectorScreen({
    super.key,
    required this.repository,
    required this.benchmarkId,
    this.existingBenchmark,
    this.routeUri,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = BenchmarkBloc(repository: repository);
        if (existingBenchmark != null) {
          bloc.add(EditBenchmark(existingBenchmark!));
        } else {
          bloc.add(LoadBenchmarkById(benchmarkId));
        }
        return bloc;
      },
      child: _BenchmarkInspectorView(
        benchmarkId: benchmarkId,
        routeUri: routeUri,
        onClose: onClose,
      ),
    );
  }
}

class _BenchmarkInspectorView extends StatelessWidget {
  final String benchmarkId;
  final Uri? routeUri;
  final VoidCallback? onClose;

  const _BenchmarkInspectorView({
    required this.benchmarkId,
    this.routeUri,
    this.onClose,
  });

  void _handleClose(BuildContext context) {
    if (onClose != null) {
      onClose!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.benchmarkDb);
    }
  }

  void _openEdit(BuildContext context, Benchmark benchmark) {
    context.pushNamed(
      'benchmark-edit',
      pathParameters: {'id': benchmark.id},
      extra: benchmark,
    ).then((_) {
      if (context.mounted) {
        context.read<BenchmarkBloc>().add(LoadBenchmarkById(benchmark.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return BlocConsumer<BenchmarkBloc, BenchmarkState>(
      listener: (context, state) {
        if (state is BenchmarkSuccess) {
          showFToast(context: context, title: Text(state.message));
          _handleClose(context);
        }
      },
      builder: (context, state) {
        final routeIdentity = routeUri?.toString() ?? 'benchmark-inspector';

        if (state is BenchmarkLoading || state is BenchmarkInitial) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: 'Detail Benchmark',
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

        if (state is BenchmarkError) {
          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: 'Detail Benchmark',
            mode: AppResponsiveSheetMode.readOnlyInspector,
            onDismissApproved: () => _handleClose(context),
            body: AppStatePanel(
              title: 'Data Tidak Ditemukan',
              message: state.message,
              actionLabel: 'Kembali',
              onAction: () => _handleClose(context),
            ),
          );
        }

        if (state is BenchmarkFormState) {
          final benchmark = state.editingBenchmark;
          if (benchmark == null) {
            return AppResponsiveSheet(
              routeIdentity: routeIdentity,
              title: 'Detail Benchmark',
              mode: AppResponsiveSheetMode.readOnlyInspector,
              onDismissApproved: () => _handleClose(context),
              body: AppStatePanel(
                title: 'Data Tidak Ditemukan',
                message: 'Benchmark tidak valid.',
                actionLabel: 'Kembali',
                onAction: () => _handleClose(context),
              ),
            );
          }

          return AppResponsiveSheet(
            routeIdentity: routeIdentity,
            title: 'Detail Benchmark',
            subtitle: 'ID: ${benchmark.bmId}',
            mode: AppResponsiveSheetMode.readOnlyInspector,
            onDismissApproved: () => _handleClose(context),
            footer: SizedBox(
              width: double.infinity,
              child: FButton(
                variant: FButtonVariant.destructive,
                onPress: () async {
                  final confirmed = await confirmDestructiveAction(
                    context,
                    message: 'Anda yakin ingin menghapus benchmark ${benchmark.bmId}?',
                  );
                  if (confirmed == true && context.mounted) {
                    context.read<BenchmarkBloc>().add(DeleteBenchmark(benchmark.id));
                  }
                },
                child: const Text('Hapus Benchmark'),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Informasi Utama',
                                style: theme.typography.body.lg.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              FButton.icon(
                                variant: FButtonVariant.outline,
                                child: const Icon(LucideIcons.pencil),
                                onPress: () => _openEdit(context, benchmark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _DetailRow(
                            label: 'Kode',
                            value: benchmark.code,
                            theme: theme,
                          ),
                          const SizedBox(height: 8),
                          _DetailRow(
                            label: 'Orde',
                            value: benchmark.orde,
                            theme: theme,
                          ),
                          const SizedBox(height: 8),
                          _DetailRow(
                            label: 'Status',
                            value: benchmark.status,
                            theme: theme,
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
                            'Sistem Koordinat (CRS)',
                            style: theme.typography.body.lg.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DetailRow(
                            label: 'CRS / Datum',
                            value: benchmark.crsIdentifier,
                            theme: theme,
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
                          _DetailRow(
                            label: 'Easting',
                            value: '${benchmark.easting.toStringAsFixed(3)} m',
                            theme: theme,
                          ),
                          const SizedBox(height: 8),
                          _DetailRow(
                            label: 'Northing',
                            value: '${benchmark.northing.toStringAsFixed(3)} m',
                            theme: theme,
                          ),
                          const SizedBox(height: 8),
                          _DetailRow(
                            label: 'Tinggi Orthometrik',
                            value: '${benchmark.orthoHeight.toStringAsFixed(3)} m',
                            theme: theme,
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
                            'Koordinat Geografis (Terkalkulasi)',
                            style: theme.typography.body.lg.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _DetailRow(
                            label: 'Latitude',
                            value: benchmark.latitude.toStringAsFixed(8),
                            theme: theme,
                          ),
                          const SizedBox(height: 8),
                          _DetailRow(
                            label: 'Longitude',
                            value: benchmark.longitude.toStringAsFixed(8),
                            theme: theme,
                          ),
                          const SizedBox(height: 8),
                          _DetailRow(
                            label: 'Tinggi Elipsoid',
                            value: '${benchmark.ellipsHeight.toStringAsFixed(3)} m',
                            theme: theme,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final FThemeData theme;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colors.foreground,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
