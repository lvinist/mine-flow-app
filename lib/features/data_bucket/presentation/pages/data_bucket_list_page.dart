import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/bloc/data_bucket_bloc.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/file_detail_page.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/upload_file_page.dart';
import 'package:mine_flow/features/data_bucket/presentation/widgets/file_card.dart';
import 'package:mine_flow/features/data_bucket/presentation/widgets/filter_chips.dart';
import 'package:mine_flow/features/data_bucket/presentation/widgets/search_bar_widget.dart';

/// Main screen for browsing and managing geospatial files in the Data Bucket.
///
/// Phase 2 polish: AnimatedSwitcher with easeOutQuart curves per DESIGN.md,
/// staggered slide+fade entrance for file cards, refined spacing and
/// typography across all states.
///
/// Provides search, filter, list view, pull-to-refresh, and navigation to
/// the upload form and file detail views.
class DataBucketListPage extends StatelessWidget {
  final DataBucketRepository repository;
  final String siteId;

  const DataBucketListPage({
    super.key,
    required this.repository,
    required this.siteId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DataBucketBloc(repository: repository, siteId: siteId)
            ..add(const LoadFiles()),
      child: _DataBucketListView(repository: repository, siteId: siteId),
    );
  }
}

class _DataBucketListView extends StatefulWidget {
  final DataBucketRepository repository;
  final String siteId;

  const _DataBucketListView({required this.repository, required this.siteId});

  @override
  State<_DataBucketListView> createState() => _DataBucketListViewState();
}

class _DataBucketListViewState extends State<_DataBucketListView>
    with TickerProviderStateMixin {
  // Computed from loaded files — zones and types available across all files.
  final Map<int, AnimationController> _cardAnimControllers = {};
  List<String> _availableZones = [];
  List<String> _availableTypes = [];

  @override
  void dispose() {
    for (final controller in _cardAnimControllers.values) {
      controller.dispose();
    }
    _cardAnimControllers.clear();
    super.dispose();
  }

  void _computeFilters(List<GeospatialFile> files) {
    final zones = files
        .map((f) => f.zoneId)
        .whereType<String>()
        .toSet()
        .toList();
    zones.sort();
    final types = files.map((f) => f.fileType).toSet().toList();
    types.sort();
    setState(() {
      _availableZones = zones;
      _availableTypes = types;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DataBucketBloc, DataBucketState>(
        builder: (context, state) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutQuart,
            switchOutCurve: Curves.easeInQuart,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, DataBucketState state) {
    if (state is DataBucketLoading) {
      return const _LoadingView(key: ValueKey('loading'));
    }

    if (state is DataBucketError) {
      return _ErrorView(
        key: const ValueKey('error'),
        message: state.message,
        onRetry: () {
          context.read<DataBucketBloc>().add(const RefreshFiles());
        },
      );
    }

    if (state is DataBucketLoaded) {
      // Compute filters on first load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _computeFilters(state.files);
      });

      return CustomScrollView(
        key: const ValueKey('loaded'),
        slivers: [
          // App bar
          SliverAppBar(
            title: const Text('Data Bucket'),
            floating: true,
            snap: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Upload File',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UploadFilePage(
                        repository: widget.repository,
                        siteId: widget.siteId,
                      ),
                    ),
                  );
                  if (context.mounted) {
                    context.read<DataBucketBloc>().add(const RefreshFiles());
                  }
                },
              ),
            ],
          ),

          // Search bar
          SliverToBoxAdapter(
            child: BlocBuilder<DataBucketBloc, DataBucketState>(
              buildWhen: (previous, current) =>
                  current is DataBucketLoaded && previous is DataBucketLoaded
                  ? previous.searchQuery != current.searchQuery
                  : current is DataBucketLoaded,
              builder: (context, state) {
                final query = state is DataBucketLoaded
                    ? state.searchQuery
                    : null;
                return SearchBarWidget(
                  initialValue: query,
                  onSearch: (q) {
                    context.read<DataBucketBloc>().add(SearchFiles(q));
                  },
                );
              },
            ),
          ),

          // Filter chips
          if (_availableTypes.isNotEmpty || _availableZones.isNotEmpty)
            SliverToBoxAdapter(
              child: BlocBuilder<DataBucketBloc, DataBucketState>(
                buildWhen: (previous, current) =>
                    current is DataBucketLoaded && previous is DataBucketLoaded
                    ? previous.filterZoneId != current.filterZoneId ||
                          previous.filterFileType != current.filterFileType
                    : current is DataBucketLoaded,
                builder: (context, state) {
                  if (state is! DataBucketLoaded) {
                    return const SizedBox.shrink();
                  }
                  return FilterChips(
                    selectedType: state.filterFileType,
                    selectedZone: state.filterZoneId,
                    availableTypes: _availableTypes,
                    availableZones: _availableZones,
                    onTypeChanged: (type) {
                      context.read<DataBucketBloc>().add(FilterByType(type));
                    },
                    onZoneChanged: (zone) {
                      context.read<DataBucketBloc>().add(FilterByZone(zone));
                    },
                  );
                },
              ),
            ),

          // File list
          _buildFileList(context, state),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFileList(BuildContext context, DataBucketLoaded state) {
    final theme = Theme.of(context);
    final displayFiles = state.filteredFiles;

    if (state.files.isEmpty) {
      return SliverFillRemaining(
        child: _EmptyView(
          icon: Icons.folder_open,
          title: 'Belum ada file yang diunggah',
          subtitle: 'Upload file geospasial untuk memulai.',
          actionLabel: 'Upload File',
          actionIcon: Icons.upload_file,
          onAction: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UploadFilePage(
                  repository: widget.repository,
                  siteId: widget.siteId,
                ),
              ),
            );
            if (context.mounted) {
              context.read<DataBucketBloc>().add(const RefreshFiles());
            }
          },
        ),
      );
    }

    if (displayFiles.isEmpty) {
      return const SliverFillRemaining(
        child: _EmptyView(
          icon: Icons.search_off,
          title: 'Tidak ada file yang cocok dengan filter.',
          subtitle: null,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '${displayFiles.length} file',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final file = displayFiles[index - 1];
          final cardIndex = index - 1;
          return _buildAnimatedFileCard(context, file, cardIndex);
        }, childCount: displayFiles.length + 1),
      ),
    );
  }

  Widget _buildAnimatedFileCard(
    BuildContext context,
    GeospatialFile file,
    int index,
  ) {
    final controller = _cardAnimControllers.putIfAbsent(
      index,
      () => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );

    if (!controller.isAnimating && !controller.isCompleted) {
      Future.delayed(Duration(milliseconds: 40 * index), () {
        if (mounted) controller.forward();
      });
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOutQuart),
              ),
          child: FadeTransition(opacity: controller, child: child),
        );
      },
      child: FileCard(
        key: ValueKey(file.id),
        file: file,
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  FileDetailPage(file: file, repository: widget.repository),
            ),
          );
          if (context.mounted) {
            context.read<DataBucketBloc>().add(const RefreshFiles());
          }
        },
        onDelete: () {
          context.read<DataBucketBloc>().add(DeleteFile(file.id));
        },
      ),
    );
  }
}

/// Animated loading placeholder.
class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat file...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error state with retry action — shadcn-admin style.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.error_outline,
                size: 28,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state view — shadcn-admin style.
class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const _EmptyView({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(36),
              ),
              child: Icon(
                icon,
                size: 36,
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onAction,
                child: actionIcon != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(actionIcon, size: 18),
                          const SizedBox(width: 8),
                          Text(actionLabel!),
                        ],
                      )
                    : Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
