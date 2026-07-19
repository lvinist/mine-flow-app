import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_state.dart';
import 'package:mine_flow/features/tracking/presentation/pages/land_clearing_entry_screen.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/land_clearing_card.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/clearing_summary_card.dart';

/// Screen listing land clearing area records with aggregated summary
/// and filter controls for site/zone/date range.
class LandClearingSummaryScreen extends StatelessWidget {
  final TrackingRepository repository;
  final String siteId;
  final String foremanId;

  const LandClearingSummaryScreen({
    super.key,
    required this.repository,
    required this.siteId,
    required this.foremanId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LandClearingBloc(repository: repository)
            ..add(LoadLandClearingRecordsEvent(siteId: siteId)),
      child: _LandClearingListView(
        repository: repository,
        siteId: siteId,
        foremanId: foremanId,
      ),
    );
  }
}

class _LandClearingListView extends StatefulWidget {
  final TrackingRepository repository;
  final String siteId;
  final String foremanId;

  const _LandClearingListView({
    required this.repository,
    required this.siteId,
    required this.foremanId,
  });

  @override
  State<_LandClearingListView> createState() => _LandClearingListViewState();
}

class _LandClearingListViewState extends State<_LandClearingListView> {
  String? _selectedZoneId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Land Clearing')),
      body: Column(
        children: [
          // Filter row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Zone filter chip
                  FilterChip(
                    label: Text(
                      _selectedZoneId ?? 'Semua Zona',
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: _selectedZoneId != null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedZoneId = selected ? 'Zona A' : null;
                      });
                      context.read<LandClearingBloc>().add(
                        LoadLandClearingRecordsEvent(
                          siteId: widget.siteId,
                          zoneId: _selectedZoneId,
                          startDate: _startDate,
                          endDate: _endDate,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Date range filter chip
                  FilterChip(
                    label: Text(
                      _startDate != null && _endDate != null
                          ? 'Filter Tanggal'
                          : 'Pilih Tanggal',
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: _startDate != null,
                    onSelected: (selected) async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDateRange: _startDate != null && _endDate != null
                            ? DateTimeRange(start: _startDate!, end: _endDate!)
                            : null,
                      );
                      if (picked != null && context.mounted) {
                        setState(() {
                          _startDate = picked.start;
                          _endDate = picked.end;
                        });
                        context.read<LandClearingBloc>().add(
                          LoadLandClearingRecordsEvent(
                            siteId: widget.siteId,
                            zoneId: _selectedZoneId,
                            startDate: _startDate,
                            endDate: _endDate,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),

                  // Clear filter button
                  if (_selectedZoneId != null || _startDate != null)
                    ActionChip(
                      label: const Text(
                        'Hapus Filter',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedZoneId = null;
                          _startDate = null;
                          _endDate = null;
                        });
                        context.read<LandClearingBloc>().add(
                          LoadLandClearingRecordsEvent(siteId: widget.siteId),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Main content
          Expanded(
            child: BlocBuilder<LandClearingBloc, LandClearingState>(
              builder: (context, state) {
                if (state is LandClearingLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is LandClearingError) {
                  return Center(
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
                            context.read<LandClearingBloc>().add(
                              LoadLandClearingRecordsEvent(
                                siteId: widget.siteId,
                                zoneId: _selectedZoneId,
                                startDate: _startDate,
                                endDate: _endDate,
                              ),
                            );
                          },
                          child: const Text('Muat Ulang'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is LandClearingRecordsLoaded) {
                  if (state.records.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forest,
                            size: 48,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada data land clearing.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    children: [
                      // Summary card at the top
                      ClearingSummaryCard(
                        totalAreaClearedM2: state.totalAreaClearedM2,
                      ),
                      const SizedBox(height: 4),

                      // Record count
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${state.records.length} pencatatan',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                      // Record cards
                      ...state.records.map(
                        (record) => LandClearingCard(
                          record: record,
                          onTap: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => LandClearingEntryScreen(
                                      repository: widget.repository,
                                      siteId: widget.siteId,
                                      foremanId: widget.foremanId,
                                      existingRecord: record,
                                    ),
                                  ),
                                )
                                .then((_) {
                                  if (context.mounted) {
                                    context.read<LandClearingBloc>().add(
                                      LoadLandClearingRecordsEvent(
                                        siteId: widget.siteId,
                                        zoneId: _selectedZoneId,
                                        startDate: _startDate,
                                        endDate: _endDate,
                                      ),
                                    );
                                  }
                                });
                          },
                          onDelete: () {
                            context.read<LandClearingBloc>().add(
                              DeleteLandClearingRecordEvent(record.id),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create_new_land_clearing_fab'),
        icon: const Icon(Icons.add),
        label: const Text('Clearing Baru'),
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => LandClearingEntryScreen(
                    repository: widget.repository,
                    siteId: widget.siteId,
                    foremanId: widget.foremanId,
                  ),
                ),
              )
              .then((_) {
                if (context.mounted) {
                  context.read<LandClearingBloc>().add(
                    LoadLandClearingRecordsEvent(
                      siteId: widget.siteId,
                      zoneId: _selectedZoneId,
                      startDate: _startDate,
                      endDate: _endDate,
                    ),
                  );
                }
              });
        },
      ),
    );
  }
}
