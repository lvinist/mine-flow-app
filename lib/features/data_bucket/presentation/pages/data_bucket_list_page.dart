// Data Bucket List — geospatial file browser in ForUI aesthetic.
//
// Phase 2 Tier 2 rebuild (STEP-30.4): Replaced hand-rolled Material layouts and
// hardcoded raw Colors with FTheme colors/typography tokens. No logic, state, or
// data-fetching changes.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/bloc/data_bucket_bloc.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/file_detail_page.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/upload_file_page.dart';
import 'package:mine_flow/features/data_bucket/presentation/widgets/file_card.dart';
import 'package:mine_flow/features/data_bucket/presentation/widgets/filter_chips.dart';
import 'package:mine_flow/features/data_bucket/presentation/widgets/search_bar_widget.dart';

/// Main screen for browsing and managing geospatial files in the Data Bucket.
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

class _DataBucketListViewState extends State<_DataBucketListView> {
  // CF-055: filters are derived from state during build — no mutable fields
  // or post-frame setState.

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: isDesktop
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: FHeader(
                title: Semantics(
                  header: true,
                  child: Text(
                    'Data Bucket',
                    style: theme.typography.display.sm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // CF-029: the "Data Bucket report" FAB was removed — data-bucket has
          // no meaningful report type; the upload FAB remains the primary action.
          FloatingActionButton.extended(
            heroTag: 'upload_data_bucket_btn',
            backgroundColor: theme.colors.primary,
            foregroundColor: theme.colors.primaryForeground,
            elevation: 2,
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
            icon: const Icon(LucideIcons.fileUp),
            label: const Text('Upload File'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          BlocBuilder<DataBucketBloc, DataBucketState>(
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
          // Filter chips (CF-055: derived from state during build)
          BlocBuilder<DataBucketBloc, DataBucketState>(
            buildWhen: (previous, current) =>
                current is DataBucketLoaded && previous is DataBucketLoaded
                ? previous.filterZoneId != current.filterZoneId ||
                      previous.filterFileType != current.filterFileType ||
                      previous.files != current.files
                : current is DataBucketLoaded,
            builder: (context, state) {
              if (state is! DataBucketLoaded) return const SizedBox.shrink();
              final zones =
                  state.files
                      .map((f) => f.zoneId)
                      .whereType<String>()
                      .toSet()
                      .toList()
                    ..sort();
              final types = state.files.map((f) => f.fileType).toSet().toList()
                ..sort();
              if (zones.isEmpty && types.isEmpty) {
                return const SizedBox.shrink();
              }
              return FilterChips(
                selectedType: state.filterFileType,
                selectedZone: state.filterZoneId,
                availableTypes: types,
                availableZones: zones,
                onTypeChanged: (type) {
                  context.read<DataBucketBloc>().add(FilterByType(type));
                },
                onZoneChanged: (zone) {
                  context.read<DataBucketBloc>().add(FilterByZone(zone));
                },
              );
            },
          ),
          const SizedBox(height: 4),
          // Main content
          Expanded(
            child: BlocBuilder<DataBucketBloc, DataBucketState>(
              builder: (context, state) {
                if (state is DataBucketLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is DataBucketError) {
                  return Center(
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
                            LucideIcons.alertCircle,
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
                        FButton(
                          onPress: () {
                            context.read<DataBucketBloc>().add(
                              const RefreshFiles(),
                            );
                          },
                          prefix: Icon(
                            LucideIcons.refreshCw,
                            color: theme.colors.primaryForeground,
                          ),
                          child: Text(
                            'Muat Ulang',
                            style: TextStyle(
                              color: theme.colors.primaryForeground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is DataBucketLoaded) {
                  final displayFiles = state.filteredFiles;

                  if (state.files.isEmpty) {
                    // Empty state
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colors.mutedForeground.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                LucideIcons.folderOpen,
                                size: 48,
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada file yang diunggah',
                              style: theme.typography.body.md.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Upload file geospasial untuk memulai.',
                              style: theme.typography.body.md.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (displayFiles.isEmpty) {
                    // No results matching filters
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.searchX,
                            size: 48,
                            color: theme.colors.mutedForeground,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada file yang cocok dengan filter.',
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
                      context.read<DataBucketBloc>().add(const RefreshFiles());
                      // Wait for loading to complete
                      await context.read<DataBucketBloc>().stream.firstWhere(
                        (s) => s is DataBucketLoaded || s is DataBucketError,
                      );
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 80),
                      itemCount: displayFiles.length + 1, // +1 for count row
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Text(
                              '${displayFiles.length} file',
                              style: theme.typography.body.xs.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          );
                        }

                        final file = displayFiles[index - 1];
                        return FileCard(
                          key: ValueKey(file.id),
                          file: file,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => FileDetailPage(
                                  file: file,
                                  repository: widget.repository,
                                ),
                              ),
                            );
                            if (context.mounted) {
                              context.read<DataBucketBloc>().add(
                                const RefreshFiles(),
                              );
                            }
                          },
                          onDelete: () {
                            context.read<DataBucketBloc>().add(
                              DeleteFile(file.id),
                            );
                          },
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
