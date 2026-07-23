import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_state.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/volume_input_field.dart';

/// Screen allowing foremen/surveyors to create or edit a cut/fill volume
/// measurement record with cut volume, fill volume, elevation change, and notes.
class CutFillFormScreen extends StatelessWidget {
  final TrackingRepository repository;
  final String siteId;
  final String foremanId;
  final CutFillRecord? existingRecord;
  final String? dailyLogId;
  final String? initialZoneId;

  const CutFillFormScreen({
    super.key,
    required this.repository,
    required this.siteId,
    required this.foremanId,
    this.existingRecord,
    this.dailyLogId,
    this.initialZoneId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CutFillBloc(repository: repository)
        ..add(
          InitializeCutFillFormEvent(
            siteId: siteId,
            zoneId: initialZoneId ?? existingRecord?.zoneId ?? '',
            foremanId: foremanId,
            existingRecord: existingRecord,
            dailyLogId: dailyLogId,
          ),
        ),
      child: const CutFillFormView(),
    );
  }
}

class CutFillFormView extends StatefulWidget {
  const CutFillFormView({super.key});

  @override
  State<CutFillFormView> createState() => _CutFillFormViewState();
}

class _CutFillFormViewState extends State<CutFillFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    return BlocConsumer<CutFillBloc, CutFillState>(
      listener: (context, state) {
        if (state is CutFillFormState) {
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

            Future.delayed(const Duration(milliseconds: 600), () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            });
          }
        }
      },
      builder: (context, state) {
        if (state is CutFillLoading || state is CutFillInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CutFillError) {
          return Scaffold(
            appBar: MediaQuery.of(context).size.width > 800 ? null : AppBar(title: const Text('Pengukuran Volume')),
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
                  FButton(
                    onPress: () {
                      context.read<CutFillBloc>().add(
                        const SaveCutFillRecordEvent(),
                      );
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is CutFillFormState) {
          final record = state.record;
          final netVolume = record.netVolumeM3;

          // Sync notes controller
          if (_notesController.text != (record.notes ?? '')) {
            _notesController.value = TextEditingValue(
              text: record.notes ?? '',
              selection: TextSelection.collapsed(
                offset: (record.notes ?? '').length,
              ),
            );
          }

          return Scaffold(
            appBar: MediaQuery.of(context).size.width > 800 ? null : AppBar(title: const Text('Pengukuran Volume')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Measurement Date Selector Tile
                    FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: theme.colors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tanggal Pengukuran',
                                    style: theme.typography.body.xs.copyWith(
                                      color: theme.colors.mutedForeground,
                                    ),
                                  ),
                                  Text(
                                    dateFormat.format(record.measurementDate),
                                    style: theme.typography.body.sm.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_calendar),
                              onPressed: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: record.measurementDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (pickedDate != null && context.mounted) {
                                  context.read<CutFillBloc>().add(
                                    MeasurementDateChangedEvent(pickedDate),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Zone display
                    FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: theme.colors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Zona',
                                    style: theme.typography.body.xs.copyWith(
                                      color: theme.colors.mutedForeground,
                                    ),
                                  ),
                                  Text(
                                    record.zoneId.isNotEmpty
                                        ? record.zoneId
                                        : 'Belum dipilih',
                                    style: theme.typography.body.sm.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: record.zoneId.isNotEmpty
                                          ? theme.colors.foreground
                                          : theme.colors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cut Volume Input
                    VolumeInputField(
                      label: 'Volume Cut (Galian)',
                      icon: Icons.arrow_circle_down_outlined,
                      value: record.cutVolumeM3,
                      onChanged: (value) {
                        context.read<CutFillBloc>().add(
                          CutVolumeChangedEvent(value),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Fill Volume Input
                    VolumeInputField(
                      label: 'Volume Fill (Timbunan)',
                      icon: Icons.arrow_circle_up_outlined,
                      value: record.fillVolumeM3,
                      onChanged: (value) {
                        context.read<CutFillBloc>().add(
                          FillVolumeChangedEvent(value),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Elevation Change Input
                    FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 18,
                                  color: theme.colors.mutedForeground,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Perubahan Elevasi (opsional)',
                                  style: theme.typography.body.sm.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'Contoh: -2.5 (meter)',
                              ),
                              onChanged: (text) {
                                final parsed = double.tryParse(text);
                                context.read<CutFillBloc>().add(
                                  ElevationChangeChangedEvent(parsed),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Net Volume Display
                    FCard(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Net Volume',
                              style: theme.typography.body.xs.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${netVolume.toStringAsFixed(1)} m³',
                              style: theme.typography.display.md.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              netVolume >= 0
                                  ? 'Net Cut (Galian)'
                                  : 'Net Fill (Timbunan)',
                              style: theme.typography.body.xs.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes Field
                    Text(
                      'Catatan',
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText:
                            'Catatan pengukuran, kondisi lapangan, dll...',
                      ),
                      onChanged: (text) {
                        context.read<CutFillBloc>().add(
                          CutFillNotesChangedEvent(text),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: FButton(
                        key: const Key('save_cut_fill_button'),
                        onPress: state.isSaving
                            ? null
                            : () {
                                context.read<CutFillBloc>().add(
                                  const SaveCutFillRecordEvent(),
                                );
                              },
                        child: Text(
                          state.isSaving ? 'Menyimpan...' : 'Simpan Pengukuran',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
