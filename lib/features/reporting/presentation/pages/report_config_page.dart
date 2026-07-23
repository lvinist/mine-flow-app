// Report Config Page — report configuration and PDF generation in ForUI aesthetic.
//
// Phase 2 Tier 2 rebuild (STEP-30.4): Replaced hand-rolled Material layouts and
// hardcoded raw Colors.red/Colors.orange/Colors.green with FTheme colors.
// Replaced ElevatedButton/OutlinedButton/TextButton with Material buttons styled
// via FTheme where possible. No logic, state, or data-fetching changes.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
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
const double _kCardRadius = 12;

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
  final TextEditingController _zoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ReportCubit>().selectReportType(widget.reportType);
  }

  @override
  void dispose() {
    _zoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: MediaQuery.of(context).size.width > 800 ? null : AppBar(
        title: Semantics(
          header: true,
          child: Text(
            'Konfigurasi ${widget.reportType.displayName}',
            style: theme.typography.display.sm.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: BlocBuilder<ReportCubit, ReportState>(
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
            TextFormField(
              controller: _zoneController,
              decoration: InputDecoration(
                labelText: 'ID Zona (Opsional)',
                hintText: 'Biarkan kosong untuk semua zona',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_kCardRadius),
                ),
                isDense: true,
              ),
              onChanged: (value) => cubit.setZoneFilter(
                value.trim().isEmpty ? null : value.trim(),
              ),
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

          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_kCardRadius),
              ),
            ),
            onPressed: isLoading
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

          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_kCardRadius),
              ),
            ),
            onPressed: () {
              Printing.sharePdf(
                bytes: state.result.pdfBytes,
                filename: state.result.fileName,
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Bagikan PDF'),
          ),
          const SizedBox(height: _kSpacing12),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_kCardRadius),
              ),
              side: BorderSide(color: theme.colors.primary),
              foregroundColor: theme.colors.primary,
            ),
            onPressed: () {
              Printing.layoutPdf(
                onLayout: (format) async => state.result.pdfBytes,
                name: state.result.title,
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Cetak'),
          ),
          const SizedBox(height: _kSpacing12),

          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: theme.colors.mutedForeground,
            ),
            onPressed: () => context.read<ReportCubit>().resetReport(),
            icon: const Icon(Icons.refresh),
            label: const Text('Buat Ulang'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(ReportType type) {
    switch (type) {
      case ReportType.attendance:
        return Icons.people_outline;
      case ReportType.cutFill:
        return Icons.terrain_outlined;
      case ReportType.inventory:
        return Icons.inventory_2_outlined;
    }
  }
}
