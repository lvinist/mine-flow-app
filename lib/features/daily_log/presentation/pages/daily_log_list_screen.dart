import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_bloc.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_event.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_state.dart';
import 'package:mine_flow/features/daily_log/presentation/pages/daily_log_form_screen.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/daily_log_card.dart';

/// Screen listing daily log history with status filtering and option to create new log entries.
class DailyLogListScreen extends StatelessWidget {
  final DailyLogRepository repository;
  final String foremanId;
  final String siteId;

  const DailyLogListScreen({
    super.key,
    required this.repository,
    required this.foremanId,
    required this.siteId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DailyLogBloc(repository: repository)
        ..add(LoadDailyLogsListEvent(
          siteId: siteId,
          foremanId: foremanId,
        )),
      child: DailyLogListView(
        repository: repository,
        foremanId: foremanId,
        siteId: siteId,
      ),
    );
  }
}

class DailyLogListView extends StatefulWidget {
  final DailyLogRepository repository;
  final String foremanId;
  final String siteId;

  const DailyLogListView({
    super.key,
    required this.repository,
    required this.foremanId,
    required this.siteId,
  });

  @override
  State<DailyLogListView> createState() => _DailyLogListViewState();
}

class _DailyLogListViewState extends State<DailyLogListView> {
  LogStatus? _selectedStatusFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Log Harian'),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Semua Status'),
                    selected: _selectedStatusFilter == null,
                    onSelected: (selected) {
                      setState(() => _selectedStatusFilter = null);
                      context.read<DailyLogBloc>().add(LoadDailyLogsListEvent(
                            siteId: widget.siteId,
                            foremanId: widget.foremanId,
                            statusFilter: null,
                          ));
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Draft'),
                    selected: _selectedStatusFilter == LogStatus.draft,
                    onSelected: (selected) {
                      final filter = selected ? LogStatus.draft : null;
                      setState(() => _selectedStatusFilter = filter);
                      context.read<DailyLogBloc>().add(LoadDailyLogsListEvent(
                            siteId: widget.siteId,
                            foremanId: widget.foremanId,
                            statusFilter: filter,
                          ));
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Terkirim'),
                    selected: _selectedStatusFilter == LogStatus.submitted,
                    onSelected: (selected) {
                      final filter = selected ? LogStatus.submitted : null;
                      setState(() => _selectedStatusFilter = filter);
                      context.read<DailyLogBloc>().add(LoadDailyLogsListEvent(
                            siteId: widget.siteId,
                            foremanId: widget.foremanId,
                            statusFilter: filter,
                          ));
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Disetujui'),
                    selected: _selectedStatusFilter == LogStatus.approved,
                    onSelected: (selected) {
                      final filter = selected ? LogStatus.approved : null;
                      setState(() => _selectedStatusFilter = filter);
                      context.read<DailyLogBloc>().add(LoadDailyLogsListEvent(
                            siteId: widget.siteId,
                            foremanId: widget.foremanId,
                            statusFilter: filter,
                          ));
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Logs List View
          Expanded(
            child: BlocBuilder<DailyLogBloc, DailyLogState>(
              builder: (context, state) {
                if (state is DailyLogLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is DailyLogError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            context.read<DailyLogBloc>().add(LoadDailyLogsListEvent(
                                  siteId: widget.siteId,
                                  foremanId: widget.foremanId,
                                  statusFilter: _selectedStatusFilter,
                                ));
                          },
                          child: const Text('Muat Ulang'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is DailyLogsLoaded) {
                  if (state.logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined,
                              size: 48, color: theme.colorScheme.secondary),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada data log harian.',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.logs.length,
                    itemBuilder: (context, index) {
                      final log = state.logs[index];
                      return DailyLogCard(
                        log: log,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DailyLogFormScreen(
                                repository: widget.repository,
                                foremanId: widget.foremanId,
                                siteId: widget.siteId,
                                existingLog: log,
                              ),
                            ),
                          ).then((_) {
                            if (context.mounted) {
                              context.read<DailyLogBloc>().add(LoadDailyLogsListEvent(
                                    siteId: widget.siteId,
                                    foremanId: widget.foremanId,
                                    statusFilter: _selectedStatusFilter,
                                  ));
                            }
                          });
                        },
                        onDelete: () {
                          context.read<DailyLogBloc>().add(DeleteDailyLogEvent(log.id));
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create_new_daily_log_fab'),
        icon: const Icon(Icons.add),
        label: const Text('Log Baru'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DailyLogFormScreen(
                repository: widget.repository,
                foremanId: widget.foremanId,
                siteId: widget.siteId,
              ),
            ),
          ).then((_) {
            if (context.mounted) {
              context.read<DailyLogBloc>().add(LoadDailyLogsListEvent(
                    siteId: widget.siteId,
                    foremanId: widget.foremanId,
                    statusFilter: _selectedStatusFilter,
                  ));
            }
          });
        },
      ),
    );
  }
}
