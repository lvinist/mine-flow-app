// Benchmark List Screen — displays survey control points in ForUI aesthetic.
//
// Phase 2 ForUI design system (FThemes.zinc). Follows shadcn-admin conventions
// with card-based list items, search/filter, and FAB for creating new benchmarks.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/benchmark/domain/entities/benchmark.dart';
import 'package:mine_flow/features/benchmark/domain/repositories/benchmark_repository.dart';
import 'package:mine_flow/features/benchmark/presentation/bloc/benchmark_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';

/// Main screen for browsing and managing survey control point benchmarks.
class BenchmarkListScreen extends StatelessWidget {
  final BenchmarkRepository repository;

  const BenchmarkListScreen({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BenchmarkBloc(repository: repository)..add(const LoadBenchmarks()),
      child: _BenchmarkListView(repository: repository),
    );
  }
}

class _BenchmarkListView extends StatefulWidget {
  final BenchmarkRepository repository;

  const _BenchmarkListView({required this.repository});

  @override
  State<_BenchmarkListView> createState() => _BenchmarkListViewState();
}

class _BenchmarkListViewState extends State<_BenchmarkListView> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: MediaQuery.of(context).size.width > 800
          ? null
          : AppBar(
              title: Semantics(
                header: true,
                child: Text(
                  'Benchmark DB',
                  style: theme.typography.display.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              elevation: 0,
            ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Buat Laporan Benchmark',
            button: true,
            child: FloatingActionButton(
              heroTag: 'report_benchmark_btn',
              backgroundColor: theme.colors.secondary,
              foregroundColor: theme.colors.secondaryForeground,
              elevation: 2,
              onPressed: () => context.pushNamed(
                'report-config',
                extra: ReportType
                    .benchmark,
              ),
              child: const Icon(Icons.picture_as_pdf_outlined),
            ),
          ),
          const SizedBox(width: 16),
          FloatingActionButton.extended(
            heroTag: 'add_benchmark_btn',
            backgroundColor: theme.colors.primary,
            foregroundColor: theme.colors.primaryForeground,
            elevation: 2,
            onPressed: () => _navigateToForm(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Benchmark'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(theme),
          const SizedBox(height: 4),
          // Main content
          Expanded(
            child: BlocBuilder<BenchmarkBloc, BenchmarkState>(
              builder: (context, state) {
                if (state is BenchmarkLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is BenchmarkError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colors.destructive.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.error_outline,
                              size: 48,
                              color: theme.colors.destructive,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: theme.typography.body.md.copyWith(
                              color: theme.colors.destructive,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Muat Ulang'),
                            onPressed: () {
                              context.read<BenchmarkBloc>().add(
                                const RefreshBenchmarks(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is BenchmarkListLoaded) {
                  final allBenchmarks = state.benchmarks;
                  final query = _searchQuery.toLowerCase().trim();
                  final displayBenchmarks = query.isEmpty
                      ? allBenchmarks
                      : allBenchmarks
                            .where(
                              (b) =>
                                  b.bmId.toLowerCase().contains(query) ||
                                  b.code.toLowerCase().contains(query) ||
                                  b.orde.toLowerCase().contains(query) ||
                                  // CF-070: search by coordinate substring too.
                                  b.northing
                                      .toStringAsFixed(2)
                                      .contains(query) ||
                                  b.easting.toStringAsFixed(2).contains(query),
                            )
                            .toList();

                  if (state.benchmarks.isEmpty) {
                    return _emptyState(context, theme);
                  }

                  if (displayBenchmarks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: theme.colors.mutedForeground,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada benchmark yang cocok dengan pencarian.',
                            style: theme.typography.body.md.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<BenchmarkBloc>().add(
                        const RefreshBenchmarks(),
                      );
                      await context.read<BenchmarkBloc>().stream.firstWhere(
                        (s) => s is BenchmarkListLoaded || s is BenchmarkError,
                      );
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 80),
                      itemCount: displayBenchmarks.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Text(
                              '${displayBenchmarks.length} benchmark',
                              style: theme.typography.body.xs.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          );
                        }

                        final benchmark = displayBenchmarks[index - 1];
                        return _BenchmarkCard(
                          benchmark: benchmark,
                          onTap: () => _navigateToForm(context, benchmark),
                          onDelete: () => _confirmDelete(context, benchmark),
                        );
                      },
                    ),
                  );
                }

                if (state is BenchmarkSuccess) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      context.read<BenchmarkBloc>().add(const LoadBenchmarks());
                    }
                  });
                  // CF-047: show a loading indicator, not the empty state —
                  // the list flashing "Belum ada benchmark" after a save is
                  // jarring and reads as data loss.
                  return const Center(child: CircularProgressIndicator());
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(FThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // CF-070: no hand-built frame — let the ForUI field frame itself.
      child: Row(
        children: [
          Icon(Icons.search, size: 16, color: theme.colors.mutedForeground),
          const SizedBox(width: 6),
          Expanded(
            child: FTextField(
              control: FTextFieldControl.managed(
                controller: _searchController,
              ),
              hint: 'Cari benchmark...',
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Icon(
                Icons.close,
                size: 16,
                color: theme.colors.mutedForeground,
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, FThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colors.mutedForeground.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.trip_origin,
                size: 48,
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada benchmark',
              style: theme.typography.body.md.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gunakan tombol di bawah untuk menambah data.',
              style: theme.typography.body.md.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext context, Benchmark? benchmark) {
    // CF-097: navigate via the registered route so the form is deep-linkable
    // and stays in the shell.
    context.pushNamed('benchmark-form', extra: benchmark);
  }

  void _confirmDelete(BuildContext context, Benchmark benchmark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Benchmark'),
        content: Text('Yakin ingin menghapus ${benchmark.bmId}?'),
        actions: [
          FButton(
            variant: FButtonVariant.outline,
            onPress: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FButton(
            variant: FButtonVariant.destructive,
            onPress: () {
              Navigator.of(ctx).pop();
              context.read<BenchmarkBloc>().add(DeleteBenchmark(benchmark.id));
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

/// Card widget displaying a single benchmark's summary.
class _BenchmarkCard extends StatelessWidget {
  final Benchmark benchmark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BenchmarkCard({
    required this.benchmark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: FCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        benchmark.bmId,
                        style: theme.typography.body.md.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'N: ${benchmark.northing.toStringAsFixed(2)}  '
                        'E: ${benchmark.easting.toStringAsFixed(2)}',
                        style: theme.typography.body.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      // CF-069: surface elevation on the card so reading it
                      // doesn't require opening the editable form.
                      const SizedBox(height: 2),
                      Text(
                        'Elevasi: ${benchmark.orthoHeight.toStringAsFixed(2)} m',
                        style: theme.typography.body.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      if (benchmark.code.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Kode: ${benchmark.code}  Orde: ${benchmark.orde}',
                          style: theme.typography.body.sm.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusChip(status: benchmark.status),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: theme.colors.destructive,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small chip displaying benchmark status.
class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  // CF-091: localised status label (no raw English).
  String get _label {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Aktif';
      case 'destroyed':
        return 'Dihancurkan';
      case 'replaced':
        return 'Diganti';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final Color chipColor;
    switch (status.toLowerCase()) {
      case 'active':
        chipColor = theme.colors.primary;
        break;
      case 'destroyed':
        chipColor = theme.colors.destructive;
        break;
      case 'replaced':
        chipColor = theme.colors.secondary;
        break;
      default:
        chipColor = theme.colors.mutedForeground;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label,
        style: theme.typography.body.xs.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
