import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    return BlocConsumer<CutFillBloc, CutFillState>(
      listener: (context, state) {
        if (state is CutFillFormState) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green.shade700,
              ),
            );

            // Pop back after successful save
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
            appBar: AppBar(title: const Text('Pengukuran Volume')),
            body: Center(
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
          final netColor = netVolume >= 0
              ? Colors.orange.shade700
              : Colors.blue.shade700;

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
            appBar: AppBar(title: const Text('Pengukuran Volume')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Measurement Date Selector Tile
                    Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.calendar_month,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text(
                          'Tanggal Pengukuran',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        subtitle: Text(
                          dateFormat.format(record.measurementDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        trailing: IconButton(
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
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Zone display
                    Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text(
                          'Zona',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        subtitle: Text(
                          record.zoneId.isNotEmpty
                              ? record.zoneId
                              : 'Belum dipilih',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: record.zoneId.isNotEmpty
                                ? null
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cut Volume Input
                    VolumeInputField(
                      label: 'Volume Cut (Galian)',
                      icon: Icons.arrow_circle_down_outlined,
                      color: Colors.orange,
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
                      color: Colors.blue,
                      value: record.fillVolumeM3,
                      onChanged: (value) {
                        context.read<CutFillBloc>().add(
                          FillVolumeChangedEvent(value),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Elevation Change Input
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: theme.colorScheme.outline,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
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
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Perubahan Elevasi (opsional)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue:
                                  record.elevationChange?.toStringAsFixed(2) ??
                                  '',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              decoration: const InputDecoration(
                                isDense: true,
                                suffixText: 'meter',
                                hintText: 'Contoh: -2.5',
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: netColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: netColor.withAlpha(76)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Net Volume',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${netVolume.toStringAsFixed(1)} m³',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: netColor,
                            ),
                          ),
                          Text(
                            netVolume >= 0
                                ? 'Net Cut (Galian)'
                                : 'Net Fill (Timbunan)',
                            style: TextStyle(fontSize: 13, color: netColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes Field
                    Text(
                      'Catatan',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
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
                      height: 48,
                      child: ElevatedButton.icon(
                        key: const Key('save_cut_fill_button'),
                        icon: state.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          state.isSaving ? 'Menyimpan...' : 'Simpan Pengukuran',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        onPressed: state.isSaving
                            ? null
                            : () {
                                context.read<CutFillBloc>().add(
                                  const SaveCutFillRecordEvent(),
                                );
                              },
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
