import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_bloc.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_event.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_state.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/auto_save_indicator.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/weather_selector.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';

/// Screen allowing foremen to create, edit, auto-save drafts, and submit daily operational logs.
///
/// Phase 2 Tier 2 rebuild (STEP-30.5 final purge): Replaced lingering Theme.of(context).colorScheme,
/// Colors.white, and TextStyle references with FTheme semantic tokens.
class DailyLogFormScreen extends StatelessWidget {
  final DailyLogRepository repository;
  final String foremanId;
  final String siteId;
  final DateTime? initialDate;
  final DailyLog? existingLog;

  const DailyLogFormScreen({
    super.key,
    required this.repository,
    required this.foremanId,
    required this.siteId,
    this.initialDate,
    this.existingLog,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DailyLogBloc(repository: repository)
        ..add(
          InitializeDailyLogFormEvent(
            foremanId: foremanId,
            siteId: siteId,
            logDate: initialDate ?? DateTime.now(),
            existingLog: existingLog,
          ),
        ),
      child: const DailyLogFormView(),
    );
  }
}

class DailyLogFormView extends StatefulWidget {
  const DailyLogFormView({super.key});

  @override
  State<DailyLogFormView> createState() => _DailyLogFormViewState();
}

class _DailyLogFormViewState extends State<DailyLogFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _summaryController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _summaryController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    return BlocConsumer<DailyLogBloc, DailyLogState>(
      listener: (context, state) {
        if (state is DailyLogFormState) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colors.destructive,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: theme.colors.primary,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        if (state is DailyLogLoading || state is DailyLogInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is DailyLogError) {
          return Scaffold(
            appBar: MediaQuery.of(context).size.width > 800 ? null : AppBar(title: const Text('Log Operasional Harian')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    style: theme.typography.body.md.copyWith(
                      color: theme.colors.destructive,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.read<DailyLogBloc>().add(
                        const AutoSaveDraftEvent(),
                      );
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is DailyLogFormState) {
          final log = state.log;
          final isDraft = log.status == LogStatus.draft;

          // Update text controllers if text differs from state
          if (_summaryController.text != (log.summary ?? '')) {
            _summaryController.value = TextEditingValue(
              text: log.summary ?? '',
              selection: TextSelection.collapsed(
                offset: (log.summary ?? '').length,
              ),
            );
          }
          if (_notesController.text != (log.notes ?? '')) {
            _notesController.value = TextEditingValue(
              text: log.notes ?? '',
              selection: TextSelection.collapsed(
                offset: (log.notes ?? '').length,
              ),
            );
          }

          return Scaffold(
            appBar: MediaQuery.of(context).size.width > 800 ? null : AppBar(
              title: const Text('Log Operasional Harian'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: AutoSaveIndicator(
                      isSaving: state.isSavingDraft,
                      hasUnsavedChanges: state.hasUnsavedChanges,
                      statusText: state.autoSaveStatusText ?? 'Draft',
                    ),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Log Date Selector Tile
                    Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.calendar_month,
                          color: theme.colors.primary,
                        ),
                        title: Text(
                          'Tanggal Operasional',
                          style: theme.typography.body.xs.copyWith(
                            color: theme.colors.mutedForeground,
                          ),
                        ),
                        subtitle: Text(
                          dateFormat.format(log.logDate),
                          style: theme.typography.body.md.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: isDraft
                            ? IconButton(
                                icon: const Icon(Icons.edit_calendar),
                                onPressed: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: log.logDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (pickedDate != null && context.mounted) {
                                    context.read<DailyLogBloc>().add(
                                      LogDateChangedEvent(pickedDate),
                                    );
                                  }
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Operational Zone Picker
                    ZonePicker(
                      selectedZoneId: log.zoneId,
                      onZoneSelected: isDraft
                          ? (zoneId) {
                              context.read<DailyLogBloc>().add(
                                ZoneChangedEvent(zoneId),
                              );
                              context.read<DailyLogBloc>().add(
                                const AutoSaveDraftEvent(),
                              );
                            }
                          : (_) {},
                    ),
                    const SizedBox(height: 16),

                    // Weather Selector Chips
                    WeatherSelector(
                      selectedWeather: log.weather,
                      onWeatherSelected: isDraft
                          ? (weather) {
                              context.read<DailyLogBloc>().add(
                                WeatherChangedEvent(weather),
                              );
                              context.read<DailyLogBloc>().add(
                                const AutoSaveDraftEvent(),
                              );
                            }
                          : (_) {},
                    ),
                    const SizedBox(height: 16),

                    // Work Summary Text Field
                    Text(
                      'Ringkasan Pekerjaan *',
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _summaryController,
                      enabled: isDraft,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText:
                            'Jelaskan pencapaian pekerjaan harian, volume tambang, kendala unit, dll.',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ringkasan pekerjaan harian wajib diisi';
                        }
                        return null;
                      },
                      onChanged: (text) {
                        context.read<DailyLogBloc>().add(
                          SummaryChangedEvent(text),
                        );
                        context.read<DailyLogBloc>().add(
                          const AutoSaveDraftEvent(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Operational Notes Field
                    Text(
                      'Catatan Tambahan & K3 (Safety)',
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      enabled: isDraft,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Insiden K3, perbaikan alat, atau instruksi shift berikutnya...',
                      ),
                      onChanged: (text) {
                        context.read<DailyLogBloc>().add(
                          NotesChangedEvent(text),
                        );
                        context.read<DailyLogBloc>().add(
                          const AutoSaveDraftEvent(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submission / Save Buttons
                    if (isDraft) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          key: const Key('submit_daily_log_button'),
                          icon: state.isSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colors.primaryForeground,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            state.isSubmitting
                                ? 'Mengirim Log...'
                                : 'Kirim Log Harian',
                            style: theme.typography.body.md.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colors.primary,
                            foregroundColor: theme.colors.primaryForeground,
                          ),
                          onPressed: state.isSubmitting
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<DailyLogBloc>().add(
                                      const SubmitDailyLogEvent(),
                                    );
                                  }
                                },
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: theme.colors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: theme.colors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                log.status == LogStatus.approved
                                    ? 'Log ini telah disetujui oleh Supervisor.'
                                    : 'Log ini telah dikirim dan menunggu persetujuan.',
                                style: theme.typography.body.md.copyWith(
                                  color: theme.colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
