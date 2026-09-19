// Material: this file uses a Material primitive with no ForUI equivalent.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/core/presentation/widgets/form_max_width.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/core/presentation/widgets/creatable_combobox.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';
import 'package:mine_flow/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_bloc.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_event.dart';
import 'package:mine_flow/features/tracking/presentation/bloc/land_clearing/land_clearing_state.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/area_input_field.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/features/zone/presentation/bloc/zone_cubit.dart';
import 'package:mine_flow/main.dart';
import 'package:mine_flow/app/router.dart';

/// Responsive modal sheet allowing foremen to create or edit a land clearing area record
/// with cleared area (m²), clearing method, zone selection, and terrain notes.
class LandClearingEntryScreen extends StatelessWidget {
  final TrackingRepository repository;
  final ZoneRepository? zoneRepository;
  final String siteId;
  final String foremanId;
  final String? recordId;
  final LandClearingRecord? existingRecord;
  final String? dailyLogId;
  final String? initialZoneId;
  final Uri? routeUri;
  final VoidCallback? onClose;

  const LandClearingEntryScreen({
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
          create: (context) => LandClearingBloc(repository: repository)
            ..add(
              InitializeLandClearingFormEvent(
                siteId: siteId,
                zoneId: effectiveZoneId,
                foremanId: foremanId,
                existingRecord: existingRecord,
                dailyLogId: dailyLogId,
                recordId: recordId,
              ),
            ),
        ),
        if (zRepo != null)
          BlocProvider<ZoneCubit>(
            create: (_) => ZoneCubit(repository: zRepo)..loadZones(),
          ),
      ],
      child: _LandClearingFormView(
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

class _LandClearingFormView extends StatefulWidget {
  final String siteId;
  final String foremanId;
  final String? recordId;
  final String? initialZoneId;
  final LandClearingRecord? existingRecord;
  final String? dailyLogId;
  final Uri? routeUri;
  final VoidCallback? onClose;

  const _LandClearingFormView({
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
  State<_LandClearingFormView> createState() => _LandClearingFormViewState();
}

class _LandClearingFormViewState extends State<_LandClearingFormView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  late TabController _tabController;

  bool get _isEdit =>
      widget.existingRecord != null ||
      (widget.recordId != null && widget.recordId!.isNotEmpty);

  static const List<String> _clearingMethods = [
    'Excavator',
    'Bulldozer',
    'Chainsaw',
  ];

  /// STEP-55.11: one-shot guard — the success close and the sheet's
  /// `PopScope` re-entry can both reach `_handleClose` for one save.
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
        path: AppRoutes.landClearing,
        queryParameters: query != null && query.isNotEmpty
            ? Map.fromEntries(query.entries.where((e) => e.key != 'tab'))
            : null,
      );
      context.go(uri.toString());
    }
  }

  void _validateAndSave(BuildContext context, LandClearingFormState state) {
    final record = state.record;
    String? error;
    if (record.zoneId.isEmpty) {
      error = 'Pilih zona terlebih dahulu.';
    } else if (record.method == null || record.method!.isEmpty) {
      error = 'Pilih metode clearing.';
    } else if (!_clearingMethods.contains(record.method)) {
      error = 'Metode clearing tidak valid. Pilih dari daftar yang tersedia.';
    } else if (record.planArea <= 0 && record.actualArea <= 0) {
      error = 'Isi minimal salah satu luas (Plan atau Actual).';
    }

    if (error != null) {
      showFToast(
        context: context,
        variant: FToastVariant.destructive,
        title: Text(error),
      );
      return;
    }

    context.read<LandClearingBloc>().add(const SaveLandClearingRecordEvent());
  }

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();

    // Sync tab with route query params if provided
    final initialTab = widget.routeUri?.queryParameters['tab'] == 'plan'
        ? 0
        : 1;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTab,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      // Optional: push replacement to keep URL synced with tab
      final tabName = _tabController.index == 1 ? 'actual' : 'plan';
      final currentParams = Map<String, String>.from(
        widget.routeUri?.queryParameters ?? {},
      );
      if (currentParams['tab'] != tabName) {
        currentParams['tab'] = tabName;
        // In a real app we might update the route to match,
        // but here it's purely UI state unless we need bookmarkable tabs mid-edit.
      }
    });

    _notesController.addListener(() {
      final text = _notesController.text;
      final currentState = context.read<LandClearingBloc>().state;
      if (currentState is LandClearingFormState &&
          (currentState.record.notes ?? '') != text) {
        context.read<LandClearingBloc>().add(
          LandClearingNotesChangedEvent(text),
        );
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tabController.dispose();
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
            showFToast(
              context: context,
              variant: FToastVariant.destructive,
              title: Text(state.errorMessage!),
            );
          }
          if (state.successMessage != null && state.isSaved) {
            showFToast(context: context, title: Text(state.successMessage!));

            Future.delayed(const Duration(milliseconds: 300), () {
              if (context.mounted) {
                _handleClose();
              }
            });
          }
        }
      },
      builder: (context, state) {
        final routeId = widget.routeUri?.toString() ?? 'land-clearing-form';

        if (state is LandClearingLoading || state is LandClearingInitial) {
          return AppResponsiveSheet(
            routeIdentity: routeId,
            title: _isEdit ? 'Edit Land Clearing' : 'Land Clearing Baru',
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

        if (state is LandClearingError) {
          return AppResponsiveSheet(
            routeIdentity: routeId,
            title: 'Land Clearing',
            mode: AppResponsiveSheetMode.form,
            onDismissApproved: _handleClose,
            body: AppStatePanel(
              title: 'Data Tidak Ditemukan',
              message: state.message,
              actionLabel: 'Kembali',
              onAction: _handleClose,
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

          return AppResponsiveSheet(
            routeIdentity: routeId,
            title: _isEdit ? 'Edit Land Clearing' : 'Land Clearing Baru',
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
                key: const Key('save_land_clearing_button'),
                onPress: state.isSaving
                    ? null
                    : () => _validateAndSave(context, state),
                child: Text(
                  state.isSaving ? 'Menyimpan...' : 'Simpan Land Clearing',
                ),
              ),
            ),
            body: FormMaxWidth(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Shared fields
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tanggal Clearing',
                                          style: theme.typography.body.xs
                                              .copyWith(
                                                color: theme
                                                    .colors
                                                    .mutedForeground,
                                              ),
                                        ),
                                        Text(
                                          dateFormat.format(
                                            record.clearingDate,
                                          ),
                                          style: theme.typography.body.sm
                                              .copyWith(
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
                                            initialDate: record.clearingDate,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime(2030),
                                          );
                                      if (pickedDate != null &&
                                          context.mounted) {
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
                          ZonePicker(
                            selectedZoneId: record.zoneId,
                            onZoneSelected: (zoneId) {
                              if (zoneId != null) {
                                context.read<LandClearingBloc>().add(
                                  ZoneChangedEvent(zoneId),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          CreatableCombobox<String>(
                            items: _clearingMethods,
                            labelBuilder: (method) => method,
                            label: 'Metode Clearing',
                            hint: 'Pilih metode clearing...',
                            initialValue: record.method ?? '',
                            selectedItem: record.method,
                            prefix: const Icon(
                              LucideIcons.construction,
                              size: 20,
                            ),
                            onChanged: (value) {
                              context.read<LandClearingBloc>().add(
                                MethodChangedEvent(value),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    Container(
                      color: theme.colors.background,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: theme.colors.primary,
                        labelColor: theme.colors.primary,
                        unselectedLabelColor: theme.colors.mutedForeground,
                        dividerColor: theme.colors.border,
                        tabs: const [
                          Tab(
                            text: 'Rencana (Plan)',
                            icon: Icon(LucideIcons.ruler, size: 20),
                          ),
                          Tab(
                            text: 'Realisasi (Actual)',
                            icon: Icon(LucideIcons.checkCircle, size: 20),
                          ),
                        ],
                      ),
                    ),

                    // We use an AnimatedBuilder to switch the view instead of TabBarView
                    // because we are in a scrollable view (body of AppResponsiveSheet)
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _tabController.index == 0
                              ? _buildPlanTab(context, theme, record)
                              : _buildActualTab(context, theme, record),
                        );
                      },
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

  Widget _buildPlanTab(
    BuildContext context,
    FThemeData theme,
    LandClearingRecord record,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AreaInputField(
          label: 'Luas Rencana (Plan)',
          icon: LucideIcons.ruler,
          value: record.planArea,
          onChanged: (value) {
            context.read<LandClearingBloc>().add(PlanAreaChangedEvent(value));
          },
        ),
        const SizedBox(height: 16),
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
                      'Plan (m²)',
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    Text(
                      record.planArea.toStringAsFixed(1),
                      style: theme.typography.display.sm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  LucideIcons.arrowRight,
                  color: theme.colors.mutedForeground,
                  size: 20,
                ),
                Column(
                  children: [
                    Text(
                      'Plan (Ha)',
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    Text(
                      (record.planArea / 10000.0).toStringAsFixed(4),
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
      ],
    );
  }

  Widget _buildActualTab(
    BuildContext context,
    FThemeData theme,
    LandClearingRecord record,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AreaInputField(
          label: 'Luas Aktual (Actual)',
          icon: LucideIcons.checkCircle,
          value: record.actualArea,
          onChanged: (value) {
            context.read<LandClearingBloc>().add(ActualAreaChangedEvent(value));
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Catatan Terrain',
          style: theme.typography.body.sm.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        FTextField.multiline(
          key: const Key('land_clearing_notes_input'),
          control: FTextFieldControl.managed(controller: _notesController),
          hint: 'Kondisi lahan, vegetasi, hambatan, dll...',
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 16),
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
                      'Actual (m²)',
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    Text(
                      record.actualArea.toStringAsFixed(1),
                      style: theme.typography.display.sm.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  LucideIcons.arrowRight,
                  color: theme.colors.mutedForeground,
                  size: 20,
                ),
                Column(
                  children: [
                    Text(
                      'Actual (Ha)',
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    Text(
                      (record.actualArea / 10000.0).toStringAsFixed(4),
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
      ],
    );
  }
}
