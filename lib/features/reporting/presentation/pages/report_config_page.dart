// Report Config Page — report configuration and PDF generation in ForUI aesthetic.
//
// Phase 2 Tier 2 rebuild (STEP-30.4): Replaced hand-rolled Material layouts and
// hardcoded raw Colors.red/Colors.orange/Colors.green with FTheme colors.
// Replaced ElevatedButton/OutlinedButton/TextButton with ForUI FButton components.
// No logic, state, or data-fetching changes.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_cubit.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_state.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/date_range_selector.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/report_summary_card.dart';
import 'package:printing/printing.dart';

const double _kPagePadding = 24;
const double _kSpacing12 = 12;
const double _kSpacing16 = 16;
const double _kSpacing24 = 24;
const double _kSpacing32 = 32;

/// Report configuration page with date range, zone filter, and generate action.
///
/// Displays a form to configure the report parameters (date range, optional zone)
/// and buttons to generate, share, or print the resulting PDF.
class ReportConfigPage extends StatefulWidget {
  final ReportType reportType;

  const ReportConfigPage({super.key, required this.reportType});

  @override
  State<ReportConfigPage> createState() => _ReportConfigPageState();
}

class _ReportConfigPageState extends State<ReportConfigPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReportCubit>().selectReportType(widget.reportType);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return FScaffold(
      header: MediaQuery.of(context).size.width > 800
          ? null
          : FHeader(
              title: Semantics(
                header: true,
                child: Text(
                  'Konfigurasi ${widget.reportType.displayName}',
                  style: theme.typography.display.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
      child: BlocBuilder<ReportCubit, ReportState>(
        builder: (context, state) {
          if (state is ReportSuccess) {
            return _buildSuccessView(context, state, theme);
          }
          return _buildConfigForm(context, state, theme);
        },
      ),
    );
  }

  Widget _buildConfigForm(
    BuildContext context,
    ReportState state,
    FThemeData theme,
  ) {
    final cubit = context.read<ReportCubit>();
    final isLoading = state is ReportLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(_kPagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            _getIconForType(widget.reportType),
            size: 64,
            color: theme.colors.primary,
          ),
          const SizedBox(height: _kSpacing16),
          Text(
            widget.reportType.displayName,
            textAlign: TextAlign.center,
            style: theme.typography.body.lg.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: _kSpacing32),

          DateRangeSelector(
            initialRange: cubit.currentRange,
            onChanged: (range) => cubit.setDateRange(range),
          ),
          const SizedBox(height: _kSpacing24),

          if (widget.reportType == ReportType.cutFill) ...[
            Text(
              'Zona Operasional (Opsional)',
              style: theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // CF-074: use a validated ZonePicker instead of a raw free-text
            // zone-ID field (a typo previously produced a silent empty report).
            ZonePicker(
              selectedZoneId: cubit.currentZoneId,
              onZoneSelected: cubit.setZoneFilter,
              siteId: defaultSiteId,
            ),
            const SizedBox(height: _kSpacing24),
          ],

          if (state is ReportError) ...[
            Container(
              padding: const EdgeInsets.all(_kSpacing12),
              decoration: BoxDecoration(
                color: theme.colors.destructive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.message,
                style: theme.typography.body.md.copyWith(
                  color: theme.colors.destructive,
                ),
              ),
            ),
            const SizedBox(height: _kSpacing24),
          ],

          FButton(
            // CF-075: explicit primary variant for WCAG-AA contrast.
            variant: FButtonVariant.primary,
            onPress: isLoading
                ? null
                : () => cubit.generateReport(siteId: defaultSiteId),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Buat Laporan',
                    style: theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(
    BuildContext context,
    ReportSuccess state,
    FThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(_kPagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReportSummaryCard(result: state.result),
          const SizedBox(height: _kSpacing24),

          FButton(
            onPress: () {
              Printing.sharePdf(
                bytes: state.result.pdfBytes,
                filename: state.result.fileName,
              );
            },
            prefix: const Icon(LucideIcons.share, size: 18),
            child: const Text('Bagikan PDF'),
          ),
          const SizedBox(height: _kSpacing12),

          FButton(
            variant: FButtonVariant.outline,
            onPress: () {
              Printing.layoutPdf(
                onLayout: (format) async => state.result.pdfBytes,
                name: state.result.title,
              );
            },
            prefix: const Icon(LucideIcons.printer, size: 18),
            child: const Text('Cetak'),
          ),
          const SizedBox(height: _kSpacing12),

          FButton(
            variant: FButtonVariant.ghost,
            onPress: () => context.read<ReportCubit>().resetReport(),
            prefix: const Icon(LucideIcons.refreshCw, size: 18),
            child: const Text('Buat Ulang'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(ReportType type) {
    switch (type) {
      case ReportType.attendance:
        return LucideIcons.users;
      case ReportType.cutFill:
        return LucideIcons.mountain;
      case ReportType.inventory:
        return LucideIcons.boxes;
      case ReportType.dailyLog:
        return LucideIcons.clipboardList;
      case ReportType.landClearing:
        return LucideIcons.mountainSnow;
      case ReportType.equipmentCheck:
        return LucideIcons.wrench;
      case ReportType.benchmark:
        return LucideIcons.circleDot;
    }
  }
}
