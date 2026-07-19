import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_state.dart';
import 'package:mine_flow/features/tracking/presentation/pages/cut_fill_form_screen.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/cut_fill_card.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/volume_summary_card.dart';

/// Screen listing cut/fill volume measurement records with aggregated summary
/// and filter controls for site/zone/date range.
class CutFillListScreen extends StatelessWidget {
  final TrackingRepository repository;
  final String siteId;
  final String foremanId;

  const CutFillListScreen({
    super.key,
    required this.repository,
    required this.siteId,
    required this.foremanId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CutFillBloc(repository: repository)
            ..add(LoadCutFillRecordsEvent(siteId: siteId)),
      child: CutFillListView(
        repository: repository,
        siteId: siteId,
        foremanId: foremanId,
      ),
    );
  }
}

class CutFillListView extends StatefulWidget {
  final TrackingRepository repository;
  final String siteId;
  final String foremanId;

  const CutFillListView({
    super.key,
    required this.repository,
    required this.siteId,
    required this.foremanId,
  });

  @override
  State<CutFillListView> createState() => _CutFillListViewState();
}

class _CutFillListViewState extends State<CutFillListView> {
  String? _selectedZoneId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Volume Cut / Fill')),
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
                      // For now, toggle a simple zone filter
                      setState(() {
                        _selectedZoneId = selected ? 'Zona A' : null;
                      });
                      context.read<CutFillBloc>().add(
                        LoadCutFillRecordsEvent(
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
                        context.read<CutFillBloc>().add(
                          LoadCutFillRecordsEvent(
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
                        context.read<CutFillBloc>().add(
                          LoadCutFillRecordsEvent(siteId: widget.siteId),
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
            child: BlocBuilder<CutFillBloc, CutFillState>(
              builder: (context, state) {
                if (state is CutFillLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CutFillError) {
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
                            context.read<CutFillBloc>().add(
                              LoadCutFillRecordsEvent(
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

                if (state is CutFillRecordsLoaded) {
                  if (state.records.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_graph_outlined,
                            size: 48,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada data volume cut/fill.',
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
                      VolumeSummaryCard(
                        totalCutM3: state.totalCutM3,
                        totalFillM3: state.totalFillM3,
                        totalNetM3: state.totalNetM3,
                      ),
                      const SizedBox(height: 4),

                      // Record count
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${state.records.length} pengukuran',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                      // Record cards
                      ...state.records.map(
                        (record) => CutFillCard(
                          record: record,
                          onTap: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => CutFillFormScreen(
                                      repository: widget.repository,
                                      siteId: widget.siteId,
                                      foremanId: widget.foremanId,
                                      existingRecord: record,
                                    ),
                                  ),
                                )
                                .then((_) {
                                  if (context.mounted) {
                                    context.read<CutFillBloc>().add(
                                      LoadCutFillRecordsEvent(
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
                            context.read<CutFillBloc>().add(
                              DeleteCutFillRecordEvent(record.id),
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
        key: const Key('create_new_cut_fill_fab'),
        icon: const Icon(Icons.add),
        label: const Text('Pengukuran Baru'),
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => CutFillFormScreen(
                    repository: widget.repository,
                    siteId: widget.siteId,
                    foremanId: widget.foremanId,
                  ),
                ),
              )
              .then((_) {
                if (context.mounted) {
                  context.read<CutFillBloc>().add(
                    LoadCutFillRecordsEvent(
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
