import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/features/reporting/domain/entities/date_range_filter.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/domain/repositories/reporting_repository.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_cubit.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_state.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/report_config_content.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/features/zone/presentation/bloc/zone_cubit.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

/// Shows a cohesive, responsive contextual report dialog.
///
/// Ensures the origin route remains mounted and visible in the background,
/// traps focus, prevents dismissal while generating, and configures the report
/// using [reportType] and initial parameters.
Future<void> showAppContextualReportDialog({
  required BuildContext context,
  required ReportType reportType,
  required String sourceTitle,
  DateTimeRange? initialDateRange,
  String? initialZoneId,
  required ReportingRepository reportingRepository,
  required ZoneRepository zoneRepository,
  VoidCallback? onComplete,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AppContextualReportDialog(
        reportType: reportType,
        sourceTitle: sourceTitle,
        initialDateRange: initialDateRange,
        initialZoneId: initialZoneId,
        reportingRepository: reportingRepository,
        zoneRepository: zoneRepository,
        onComplete: onComplete,
      );
    },
  );
}

class AppContextualReportDialog extends StatefulWidget {
  final ReportType reportType;
  final String sourceTitle;
  final DateTimeRange? initialDateRange;
  final String? initialZoneId;
  final ReportingRepository reportingRepository;
  final ZoneRepository zoneRepository;
  final VoidCallback? onComplete;

  const AppContextualReportDialog({
    super.key,
    required this.reportType,
    required this.sourceTitle,
    this.initialDateRange,
    this.initialZoneId,
    required this.reportingRepository,
    required this.zoneRepository,
    this.onComplete,
  });

  @override
  State<AppContextualReportDialog> createState() => _AppContextualReportDialogState();
}

class _AppContextualReportDialogState extends State<AppContextualReportDialog> {
  late final ReportCubit _reportCubit;
  late final ZoneCubit _zoneCubit;

  @override
  void initState() {
    super.initState();
    _reportCubit = ReportCubit(repository: widget.reportingRepository);
    _reportCubit.selectReportType(widget.reportType);
    if (widget.initialDateRange != null) {
      _reportCubit.setDateRange(DateRangeFilter(
        startDate: widget.initialDateRange!.start,
        endDate: widget.initialDateRange!.end,
      ));
    }
    if (widget.initialZoneId != null) {
      _reportCubit.setZoneFilter(widget.initialZoneId);
    }
    _zoneCubit = ZoneCubit(repository: widget.zoneRepository)..loadZones();
  }

  @override
  void dispose() {
    _reportCubit.close();
    _zoneCubit.close();
    super.dispose();
  }

  void _handleDismiss(AppDismissReason reason, ReportState state) {
    if (state is ReportLoading) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        AppLocalizations.of(context)!.processInProgress,
        TextDirection.ltr,
      );
      return;
    }
    Navigator.of(context).pop();
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _reportCubit),
        BlocProvider.value(value: _zoneCubit),
      ],
      child: BlocBuilder<ReportCubit, ReportState>(
        builder: (context, state) {
          final isBusy = state is ReportLoading;
          
          return PopScope(
            canPop: !isBusy,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) {
                _handleDismiss(AppDismissReason.systemBack, state);
              } else {
                widget.onComplete?.call();
              }
            },
            child: Dialog(
              insetPadding: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: FocusTraversalGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                    header: true,
                                    child: Text(
                                      'Laporan: ${widget.sourceTitle}',
                                      style: FTheme.of(context).typography.body.lg.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.reportType.displayName,
                                    style: FTheme.of(context).typography.body.sm.copyWith(
                                      color: FTheme.of(context).colors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppAccessibleIconButton(
                              tooltip: AppLocalizations.of(context)!.sheetBarrierLabel,
                              icon: Icons.close,
                              onPressed: isBusy
                                  ? null
                                  : () => _handleDismiss(AppDismissReason.closeButton, state),
                            ),
                          ],
                        ),
                      ),
                      // Scrollable Body
                      Flexible(
                        child: SafeArea(
                          top: false,
                          child: ReportConfigContent(
                            reportType: widget.reportType,
                            onClose: () => _handleDismiss(AppDismissReason.cancel, state),
                          ),
                        ),
                      ),
                    ],
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
