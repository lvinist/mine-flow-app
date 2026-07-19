import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_state.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/area_input_field.dart';

/// Screen allowing foremen to create or edit a land clearing area record
/// with cleared area (m²), clearing method, zone selection, and terrain notes.
class LandClearingEntryScreen extends StatelessWidget {
  final TrackingRepository repository;
  final String siteId;
  final String foremanId;
  final LandClearingRecord? existingRecord;
  final String? dailyLogId;
  final String? initialZoneId;

  const LandClearingEntryScreen({
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
      create: (context) => LandClearingBloc(repository: repository)
        ..add(
          InitializeLandClearingFormEvent(
            siteId: siteId,
            zoneId: initialZoneId ?? existingRecord?.zoneId ?? '',
            foremanId: foremanId,
            existingRecord: existingRecord,
            dailyLogId: dailyLogId,
          ),
        ),
      child: const _LandClearingFormView(),
    );
  }
}

class _LandClearingFormView extends StatefulWidget {
  const _LandClearingFormView();

  @override
  State<_LandClearingFormView> createState() => _LandClearingFormViewState();
}

class _LandClearingFormViewState extends State<_LandClearingFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;

  /// Available clearing methods for the dropdown.
  static const List<String> _clearingMethods = [
    'Bulldozer',
    'Excavator',
    'Manual Tree Felling',
    'Chainsaw',
    'Grader',
    'Lainnya',
  ];

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

    return BlocConsumer<LandClearingBloc, LandClearingState>(
      listener: (context, state) {
        if (state is LandClearingFormState) {
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
        if (state is LandClearingLoading || state is LandClearingInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is LandClearingError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Land Clearing')),
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
                      context.read<LandClearingBloc>().add(
                        const SaveLandClearingRecordEvent(),
                      );
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is LandClearingFormState) {
          final record = state.record;

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
            appBar: AppBar(title: const Text('Land Clearing')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clearing Date Selector Tile
                    Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.calendar_month,
                          color: theme.colorScheme.primary,
                        ),
                        title: const Text(
                          'Tanggal Clearing',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        subtitle: Text(
                          dateFormat.format(record.clearingDate),
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
                              initialDate: record.clearingDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (pickedDate != null && context.mounted) {
                              context.read<LandClearingBloc>().add(
                                ClearingDateChangedEvent(pickedDate),
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

                    // Cleared Area Input
                    AreaInputField(
                      label: 'Luas Area Dibersihkan',
                      icon: Icons.straighten,
                      color: Colors.green,
                      value: record.areaClearedM2,
                      onChanged: (value) {
                        context.read<LandClearingBloc>().add(
                          AreaClearedChangedEvent(value),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Area unit conversion display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.withAlpha(15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.teal.withAlpha(76)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'm²',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                record.areaClearedM2.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.teal,
                            size: 20,
                          ),
                          Column(
                            children: [
                              const Text(
                                'Hektar (Ha)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                record.areaClearedHa.toStringAsFixed(4),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Clearing Method Dropdown
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
                                  Icons.construction,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Metode Clearing',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: record.clearingMethod,
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'Pilih metode clearing',
                              ),
                              items: _clearingMethods
                                  .map(
                                    (method) => DropdownMenuItem(
                                      value: method,
                                      child: Text(method),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                context.read<LandClearingBloc>().add(
                                  ClearingMethodChangedEvent(value),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes Field
                    Text(
                      'Catatan Terrain',
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
                        hintText: 'Kondisi lahan, vegetasi, hambatan, dll...',
                      ),
                      onChanged: (text) {
                        context.read<LandClearingBloc>().add(
                          LandClearingNotesChangedEvent(text),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        key: const Key('save_land_clearing_button'),
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
                          state.isSaving
                              ? 'Menyimpan...'
                              : 'Simpan Land Clearing',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        onPressed: state.isSaving
                            ? null
                            : () {
                                context.read<LandClearingBloc>().add(
                                  const SaveLandClearingRecordEvent(),
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
