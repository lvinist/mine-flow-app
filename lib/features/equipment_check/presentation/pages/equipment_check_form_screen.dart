import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';
import 'package:mine_flow/features/equipment_check/domain/repositories/equipment_check_repository.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_bloc.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_event.dart';
import 'package:mine_flow/features/equipment_check/presentation/bloc/equipment_check_state.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/check_type_toggle.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/condition_summary_badge.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/equipment_type_tabs.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/sop_checklist_item_card.dart';

/// Screen for completing digital SOP pre-work and post-work equipment condition checks.
///
/// Phase 2 Tier 2 rebuild (STEP-30.5 final purge): Replaced lingering Material
/// Colors.*, kColor*, and TextStyle references with FTheme semantic tokens.
class EquipmentCheckFormScreen extends StatelessWidget {
  final EquipmentCheckRepository repository;
  final String siteId;
  final String foremanId;
  final EquipmentType initialEquipmentType;
  final CheckType initialCheckType;
  final VoidCallback? onSubmitSuccess;

  const EquipmentCheckFormScreen({
    super.key,
    required this.repository,
    required this.siteId,
    required this.foremanId,
    this.initialEquipmentType = EquipmentType.gnss,
    this.initialCheckType = CheckType.preWork,
    this.onSubmitSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EquipmentCheckBloc(repository: repository)
        ..add(
          LoadEquipmentCheckEvent(
            siteId: siteId,
            foremanId: foremanId,
            equipmentType: initialEquipmentType,
            checkType: initialCheckType,
          ),
        ),
      child: EquipmentCheckFormView(onSubmitSuccess: onSubmitSuccess),
    );
  }
}

class EquipmentCheckFormView extends StatefulWidget {
  final VoidCallback? onSubmitSuccess;

  const EquipmentCheckFormView({super.key, this.onSubmitSuccess});

  @override
  State<EquipmentCheckFormView> createState() => _EquipmentCheckFormViewState();
}

class _EquipmentCheckFormViewState extends State<EquipmentCheckFormView> {
  late final TextEditingController _serialNumberController;
  late final TextEditingController _remarksController;

  @override
  void initState() {
    super.initState();
    _serialNumberController = TextEditingController();
    _remarksController = TextEditingController();
    // CF-039: rebuild on serial changes so the submit button reflects the
    // required-serial gate.
    _serialNumberController.addListener(_onSerialChanged);
  }

  void _onSerialChanged() => setState(() {});

  @override
  void dispose() {
    _serialNumberController.removeListener(_onSerialChanged);
    _serialNumberController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: MediaQuery.of(context).size.width > 800
          ? null
          : AppBar(
              title: Text(
                'Inspeksi SOP Peralatan',
                style: theme.typography.display.xs.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              elevation: 0,
              backgroundColor: theme.colors.primary,
              foregroundColor: theme.colors.primaryForeground,
            ),
      body: BlocConsumer<EquipmentCheckBloc, EquipmentCheckState>(
        listener: (context, state) {
          if (state is EquipmentCheckSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colors.secondary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            if (widget.onSubmitSuccess != null) {
              widget.onSubmitSuccess!();
            }
          } else if (state is EquipmentCheckError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colors.destructive,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is EquipmentCheckLoading ||
              state is EquipmentCheckInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final loadedState = state is EquipmentCheckLoaded
              ? state
              : (state is EquipmentCheckSubmitted
                    ? EquipmentCheckLoaded(
                        siteId: state.check.siteId,
                        foremanId: state.check.foremanId,
                        equipmentType: state.check.equipmentType,
                        checkType: state.check.checkType,
                        serialNumber: state.check.serialNumber ?? '',
                        checkTime: state.check.checkTime,
                        checklist: state.check.checklist,
                        remarks: state.check.remarks ?? '',
                      )
                    : null);

          if (loadedState == null) {
            return const Center(child: Text('Gagal memuat formulir SOP'));
          }

          final bloc = context.read<EquipmentCheckBloc>();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Equipment Type Selector Tabs
                EquipmentTypeTabs(
                  selectedType: loadedState.equipmentType,
                  onTypeSelected: (type) {
                    bloc.add(SelectEquipmentTypeEvent(type));
                  },
                ),
                const SizedBox(height: 16),

                // Check Type (Pre-work vs Post-work) Toggle
                CheckTypeToggle(
                  selectedCheckType: loadedState.checkType,
                  onCheckTypeChanged: (checkType) {
                    bloc.add(SelectCheckTypeEvent(checkType));
                  },
                ),
                const SizedBox(height: 16),

                // Equipment Serial Number Field
                TextField(
                  controller: _serialNumberController,
                  onChanged: (val) => bloc.add(UpdateSerialNumberEvent(val)),
                  decoration: const InputDecoration(
                    labelText: 'Nomor Seri Alat / ID Unit',
                    hintText: 'Misal: Trimble-GNSS-8891 / TS-Leica-02',
                    prefixIcon: Icon(LucideIcons.qrCode, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Operational Condition Summary Badge
                ConditionSummaryBadge(
                  status: loadedState.overallStatus,
                  isOperational: loadedState.isOperational,
                  passedCount: loadedState.passedCount,
                  totalCount: loadedState.totalCount,
                ),
                const SizedBox(height: 20),

                // Section Header: SOP Checklist Items
                Text(
                  'DAFTAR CEK KELAYAKAN SOP',
                  style: theme.typography.body.xs.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                // Checklist Item Cards
                ...loadedState.checklist.map(
                  (item) => SopChecklistItemCard(
                    item: item,
                    onToggle: (isPassed, remarks) {
                      bloc.add(
                        ToggleCheckItemEvent(
                          itemId: item.id,
                          isPassed: isPassed,
                          remarks: remarks,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Overall Inspection Notes / Remarks
                TextField(
                  controller: _remarksController,
                  maxLines: 2,
                  onChanged: (val) => bloc.add(UpdateRemarksEvent(val)),
                  decoration: const InputDecoration(
                    labelText: 'Catatan Tambahan Inspeksi',
                    hintText: 'Misal: Cuaca berawan, lokasi sektor pit A2',
                    prefixIcon: Icon(LucideIcons.fileText, size: 20),
                  ),
                ),

                // CF-080: submit lives in a persistent bottom bar (see
                // Scaffold.bottomNavigationBar) so the long SOP list can't push
                // it below the fold.
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<EquipmentCheckBloc, EquipmentCheckState>(
        builder: (context, state) {
          if (state is! EquipmentCheckLoaded) {
            return const SizedBox.shrink();
          }
          final loadedState = state;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FButton(
                  // CF-017 + CF-039: disabled until every SOP item has an
                  // explicit verdict and a serial number is entered.
                  onPress:
                      (loadedState.isSubmitting ||
                          !loadedState.isComplete ||
                          _serialNumberController.text.trim().isEmpty)
                      ? null
                      : () => context.read<EquipmentCheckBloc>().add(
                          const SubmitEquipmentCheckEvent(),
                        ),
                  child: loadedState.isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colors.primaryForeground,
                            ),
                          ),
                        )
                      : Text(
                          loadedState.unansweredCount > 0
                              ? 'Jawab semua item SOP (${loadedState.totalCount - loadedState.unansweredCount}/${loadedState.totalCount})'
                              : 'Simpan Inspeksi SOP (${loadedState.passedCount}/${loadedState.totalCount} Lolos)',
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
