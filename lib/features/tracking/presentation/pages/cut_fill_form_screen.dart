// Material: this file uses a Material primitive with no ForUI equivalent.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/core/presentation/widgets/creatable_combobox.dart';
import 'package:mine_flow/core/presentation/widgets/form_max_width.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/cut_fill_state.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/volume_input_field.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/features/zone/presentation/bloc/zone_cubit.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:mine_flow/main.dart';

/// Responsive modal sheet allowing foremen/surveyors to create or edit a cut/fill
/// volume measurement record with cut/fill volumes, elevation change, and notes.
///
/// Hosted via [AppResponsiveSheet] matching D1 (Web right sheet >=800dp) and
/// D2 (Android modal bottom sheet <800dp) conventions with D4 dirty guard.
class CutFillFormScreen extends StatelessWidget {
  final TrackingRepository repository;
  final ZoneRepository? zoneRepository;
  final String siteId;
  final String foremanId;
  final String? recordId;
  final CutFillRecord? existingRecord;
  final String? dailyLogId;
  final String? initialZoneId;
  final Uri? routeUri;
  final VoidCallback? onClose;

  const CutFillFormScreen({
    super.key,
    required this.repository,
    this.zoneRepository,
    required this.siteId,
    required this.foremanId,
    this.recordId,
    this.existingRecord,
    this.dailyLogId,
    this.initialZoneId,
    this.routeUri,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final zRepo = zoneRepository ?? appServices?.zoneRepository;
    final effectiveZoneId =
        initialZoneId ??
        routeUri?.queryParameters['zoneId'] ??
        existingRecord?.zoneId ??
        '';

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => CutFillBloc(repository: repository)
            ..add(
              InitializeCutFillFormEvent(
                siteId: siteId,
                zoneId: effectiveZoneId,
                foremanId: foremanId,
                recordId: recordId,
                existingRecord: existingRecord,
                dailyLogId: dailyLogId,
              ),
            ),
        ),
        if (zRepo != null)
          BlocProvider<ZoneCubit>(
            create: (_) => ZoneCubit(repository: zRepo)..loadZones(),
          ),
      ],
      child: CutFillFormView(
        siteId: siteId,
        foremanId: foremanId,
        recordId: recordId,
        initialZoneId: effectiveZoneId.isNotEmpty ? effectiveZoneId : null,
        existingRecord: existingRecord,
        dailyLogId: dailyLogId,
        routeUri: routeUri,
        onClose: onClose,
      ),
    );
  }
}

class CutFillFormView extends StatefulWidget {
  final String siteId;
  final String foremanId;
  final String? recordId;
  final String? initialZoneId;
  final CutFillRecord? existingRecord;
  final String? dailyLogId;
  final Uri? routeUri;
  final VoidCallback? onClose;

  const CutFillFormView({
    super.key,
    required this.siteId,
    required this.foremanId,
    this.recordId,
    this.initialZoneId,
    this.existingRecord,
    this.dailyLogId,
    this.routeUri,
    this.onClose,
  });

  @override
  State<CutFillFormView> createState() => _CutFillFormViewState();
}

class _CutFillFormViewState extends State<CutFillFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  late TextEditingController _elevationController;
  bool _elevationSynced = false;

  bool get _isEdit =>
      widget.existingRecord != null ||
      (widget.recordId != null && widget.recordId!.isNotEmpty);

  /// STEP-55.11: one-shot guard. The success listener's close and the
  /// `AppResponsiveSheet` `PopScope` re-entry can both reach `_handleClose`
  /// for a single save (the programmatic `context.pop()` is intercepted by
  /// the sheet's `canPop: false` and routed back here), which popped the
  /// route twice and left the journey on the parent page. Only the first
  /// call may close.
  bool _hasClosed = false;

  void _handleClose() {
    if (_hasClosed) return;
    if (widget.onClose != null) {
      _hasClosed = true;
      widget.onClose!();
      return;
    }
    _hasClosed = true;
    if (context.canPop()) {
      context.pop();
    } else {
      final query = widget.routeUri?.queryParameters;
      final uri = Uri(
        path: AppRoutes.cutFill,
        queryParameters: query != null && query.isNotEmpty ? query : null,
      );
      context.go(uri.toString());
    }
  }

  void _validateAndSave(BuildContext context, CutFillFormState state) {
    final record = state.record;
    final l10n = AppLocalizations.of(context);
    String? error;
    if (record.zoneId.isEmpty) {
      error = l10n.selectZoneValidation;
    } else if (record.materialType == null || record.materialType!.isEmpty) {
      error = l10n.selectMaterialValidation;
    } else if (record.bcmVolume <= 0 && record.lcmVolume <= 0) {
      error = l10n.volumeValidation;
    }

    if (error != null) {
      showFToast(
        context: context,
        variant: FToastVariant.destructive,
        title: Text(error),
      );
      return;
    }

    context.read<CutFillBloc>().add(const SaveCutFillRecordEvent());
  }

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _elevationController = TextEditingController();

    _elevationController.addListener(() {
      final parsed = double.tryParse(_elevationController.text);
      final currentState = context.read<CutFillBloc>().state;
      if (currentState is CutFillFormState &&
          currentState.record.elevationChange != parsed) {
        context.read<CutFillBloc>().add(ElevationChangeChangedEvent(parsed));
      }
    });

    _notesController.addListener(() {
      final text = _notesController.text;
      final currentState = context.read<CutFillBloc>().state;
      if (currentState is CutFillFormState &&
          (currentState.record.notes ?? '') != text) {
        context.read<CutFillBloc>().add(CutFillNotesChangedEvent(text));
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _elevationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    return BlocConsumer<CutFillBloc, CutFillState>(
      listener: (context, state) {
        if (state is CutFillFormState) {
          if (state.errorMessage != null) {
            showFToast(
              context: context,
              variant: FToastVariant.destructive,
              title: Text(state.errorMessage!),
            );
          }
          if (state.successMessage != null && state.isSaved) {
            showFToast(context: context, title: Text(state.successMessage!));

            // STEP-55.11: the delayed close raced the sheet's PopScope
            // dismissal, so a back press inside the 300ms window popped a
            // second time while the navigator was locked (`!_debugLocked`).
            // Only close when the route is still mounted and able to pop.
            // STEP-55.11: route through the one-shot `_handleClose` so the
            // success close and the sheet's `PopScope` re-entry cannot both
            // pop (the programmatic `context.pop()` is intercepted by the
            // sheet's `canPop: false` and routed back to `_handleClose`).
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!context.mounted) return;
              _handleClose();
            });
          }
        }
      },
      builder: (context, state) {
        final routeId = widget.routeUri?.toString() ?? 'cut-fill-form';

        if (state is CutFillLoading || state is CutFillInitial) {
          return AppResponsiveSheet(
            routeIdentity: routeId,
            title: _isEdit ? l10n.editMeasurement : l10n.newMeasurement,
            mode: AppResponsiveSheetMode.form,
            onDismissApproved: _handleClose,
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: FCircularProgress(),
              ),
            ),
          );
        }

        if (state is CutFillError) {
          return AppResponsiveSheet(
            routeIdentity: routeId,
            title: l10n.cutFillTitle,
            mode: AppResponsiveSheetMode.form,
            onDismissApproved: _handleClose,
            body: AppStatePanel(
              title: l10n.dataNotFound,
              message: state.message,
              actionLabel: l10n.backToList,
              onAction: _handleClose,
            ),
          );
        }

        if (state is CutFillFormState) {
          final record = state.record;
          final netVolume = record.netVolume;

          // Sync notes controller
          if (_notesController.text != (record.notes ?? '')) {
            _notesController.value = TextEditingValue(
              text: record.notes ?? '',
              selection: TextSelection.collapsed(
                offset: (record.notes ?? '').length,
              ),
            );
          }

          // CF-040: seed the elevation controller once from the record value.
          if (!_elevationSynced) {
            _elevationSynced = true;
            _elevationController.text =
                record.elevationChange?.toString() ?? '';
          }

          return AppResponsiveSheet(
            routeIdentity: routeId,
            title: _isEdit ? l10n.editMeasurement : l10n.newMeasurement,
            subtitle: record.zoneId.isNotEmpty
                ? 'Zona: ${record.zoneId}'
                : null,
            mode: AppResponsiveSheetMode.form,
            isDirty: state.hasUnsavedChanges,
            isBusy: state.isSaving,
            onDismissApproved: _handleClose,
            footer: SizedBox(
              width: double.infinity,
              child: FButton(
                key: const Key('save_cut_fill_button'),
                onPress: state.isSaving
                    ? null
                    : () => _validateAndSave(context, state),
                child: Text(
                  state.isSaving ? l10n.saving : l10n.saveMeasurement,
                ),
              ),
            ),
            body: FormMaxWidth(
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
                              LucideIcons.calendarDays,
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
                            AppAccessibleIconButton(
                              tooltip: 'Ubah tanggal',
                              icon: LucideIcons.calendarDays,
                              onPressed: () async {
                                final pickedDate =
                                    await AppCalendarDialog.showSingle(
                                      context,
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

                    // Zone Picker
                    ZonePicker(
                      selectedZoneId: record.zoneId,
                      onZoneSelected: (zoneId) {
                        if (zoneId != null) {
                          context.read<CutFillBloc>().add(
                            ZoneChangedEvent(zoneId),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Cut/Fill Volume Inputs in 2-column layout
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: VolumeInputField(
                            label: 'Volume (BCM)',
                            unit: 'm³ (BCM)',
                            icon: LucideIcons.arrowDownCircle,
                            value: record.bcmVolume,
                            onChanged: (value) {
                              context.read<CutFillBloc>().add(
                                BcmVolumeChangedEvent(value),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: VolumeInputField(
                            label: 'Volume (LCM)',
                            unit: 'm³ (LCM)',
                            icon: LucideIcons.arrowUpCircle,
                            value: record.lcmVolume,
                            onChanged: (value) {
                              context.read<CutFillBloc>().add(
                                LcmVolumeChangedEvent(value),
                              );
                            },
                          ),
                        ),
                      ],
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
                                  LucideIcons.trendingUp,
                                  size: 18,
                                  color: theme.colors.mutedForeground,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Perubahan Elevasi (opsional)',
                                    style: theme.typography.body.sm.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            FTextField(
                              key: const Key('cut_fill_elevation_input'),
                              control: FTextFieldControl.managed(
                                controller: _elevationController,
                              ),
                              hint: 'Contoh: -2.5 (meter)',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Material Type Dropdown
                    FCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.boxes,
                                  size: 18,
                                  color: theme.colors.mutedForeground,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tipe Material',
                                    style: theme.typography.body.sm.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                final options = [
                                  'OB / Waste',
                                  'Soil',
                                  'Limonite',
                                  'Saprolite',
                                  'Quarry',
                                ];
                                if (record.materialType != null &&
                                    !options.contains(record.materialType)) {
                                  options.add(record.materialType!);
                                }
                                return CreatableCombobox<String>(
                                  items: options,
                                  labelBuilder: (mat) => mat,
                                  initialValue: record.materialType ?? '',
                                  selectedItem: record.materialType,
                                  hint: 'Pilih tipe material',
                                  onChanged: (value) {
                                    context.read<CutFillBloc>().add(
                                      MaterialTypeChangedEvent(value),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Net Volume Display (bank-equivalent)
                    FCard(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Volume Setara Bank',
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
                              'BCM + LCM ÷ (1 + swell)',
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
                    FTextField.multiline(
                      key: const Key('cut_fill_notes_input'),
                      control: FTextFieldControl.managed(
                        controller: _notesController,
                      ),
                      hint: 'Catatan pengukuran, kondisi lapangan, dll...',
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
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
