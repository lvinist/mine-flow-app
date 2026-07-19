import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_cubit.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_state.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/date_range_selector.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/report_summary_card.dart';
import 'package:printing/printing.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Konfigurasi ${widget.reportType.displayName}'),
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
    ThemeData theme,
  ) {
    final cubit = context.read<ReportCubit>();
    final isLoading = state is ReportLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            _getIconForType(widget.reportType),
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            widget.reportType.displayName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          DateRangeSelector(
            initialRange: cubit.currentRange,
            onChanged: (range) => cubit.setDateRange(range),
          ),
          const SizedBox(height: 24),

          if (widget.reportType == ReportType.cutFill) ...[
            TextFormField(
              controller: _zoneController,
              decoration: const InputDecoration(
                labelText: 'ID Zona (Opsional)',
                hintText: 'Biarkan kosong untuk semua zona',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => cubit.setZoneFilter(
                value.trim().isEmpty ? null : value.trim(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (state is ReportError) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                state.message,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
            const SizedBox(height: 24),
          ],

          ElevatedButton(
            onPressed: isLoading
                ? null
                : () => cubit.generateReport(siteId: defaultSiteId),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Buat Laporan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(
    BuildContext context,
    ReportSuccess state,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReportSummaryCard(result: state.result),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () {
              Printing.sharePdf(
                bytes: state.result.pdfBytes,
                filename: state.result.fileName,
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Bagikan PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () {
              Printing.layoutPdf(
                onLayout: (format) async => state.result.pdfBytes,
                name: state.result.title,
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Cetak'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextButton.icon(
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
