import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
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
    final theme = FTheme.of(context);
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    return BlocConsumer<LandClearingBloc, LandClearingState>(
      listener: (context, state) {
        if (state is LandClearingFormState) {
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
        if (state is LandClearingLoading || state is LandClearingInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is LandClearingError) {
          return Scaffold(
            appBar: MediaQuery.of(context).size.width > 800 ? null : AppBar(title: const Text('Land Clearing')),
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
            appBar: MediaQuery.of(context).size.width > 800 ? null : AppBar(title: const Text('Land Clearing')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clearing Date Selector Tile
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
                                    'Tanggal Clearing',
                                    style: theme.typography.body.xs.copyWith(
                                      color: theme.colors.mutedForeground,
                                    ),
                                  ),
                                  Text(
                                    dateFormat.format(record.clearingDate),
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

                    // Cleared Area Input
                    AreaInputField(
                      label: 'Luas Area Dibersihkan',
                      icon: Icons.straighten,
                      value: record.areaClearedM2,
                      onChanged: (value) {
                        context.read<LandClearingBloc>().add(
                          AreaClearedChangedEvent(value),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Area unit conversion display
                    FCard(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'm²',
                                  style: theme.typography.body.xs.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                                Text(
                                  record.areaClearedM2.toStringAsFixed(1),
                                  style: theme.typography.display.sm.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward,
                              color: theme.colors.mutedForeground,
                              size: 20,
                            ),
                            Column(
                              children: [
                                Text(
                                  'Hektar (Ha)',
                                  style: theme.typography.body.xs.copyWith(
                                    color: theme.colors.mutedForeground,
                                  ),
                                ),
                                Text(
                                  record.areaClearedHa.toStringAsFixed(4),
                                  style: theme.typography.display.sm.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Clearing Method Dropdown
                    FCard(
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
                                  color: theme.colors.mutedForeground,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Metode Clearing',
                                  style: theme.typography.body.sm.copyWith(
                                    fontWeight: FontWeight.bold,
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
                      style: theme.typography.body.sm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
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
                      child: FButton(
                        key: const Key('save_land_clearing_button'),
                        onPress: state.isSaving
                            ? null
                            : () {
                                context.read<LandClearingBloc>().add(
                                  const SaveLandClearingRecordEvent(),
                                );
                              },
                        child: Text(
                          state.isSaving
                              ? 'Menyimpan...'
                              : 'Simpan Land Clearing',
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
