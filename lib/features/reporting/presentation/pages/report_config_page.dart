import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/core/constants/app_constants.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_cubit.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_state.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/date_range_selector.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/report_summary_card.dart';
import 'package:printing/printing.dart';

// Phase 2 — shadcn-admin design language constants (DESIGN.md §29).
const double _kPagePadding = 24;

/// Spacing scale derived from DESIGN.md §29 (4, 8, 12, 16, 20, 24, 32 dp).
const double _kSpacing4 = 4;
const double _kSpacing8 = 8;
const double _kSpacing12 = 12;
const double _kSpacing16 = 16;
const double _kSpacing20 = 20;
const double _kSpacing24 = 24;

/// Brand primary — Steel Blue / Navy (#0f172a), the restrained foundation.
const Color _kBrandPrimary = Color(0xFF0F172A);

/// Accent — Cyan / Teal, used sparingly for interactive elements.
const Color _kAccent = Color(0xFF0891B2);

/// Card border radius for surface containers.
const double _kCardRadius = 12;
const double _kInputRadius = 8;

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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(
            'Konfigurasi ${widget.reportType.displayName}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
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
    final colorScheme = theme.colorScheme;
    final cubit = context.read<ReportCubit>();
    final isLoading = state is ReportLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(_kPagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header — constrained width per DESIGN.md §19
          // to prevent excessively long heading lines on wide screens.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Konfigurasi ${widget.reportType.displayName}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: _kSpacing8),
                Text(
                  'Atur parameter laporan sebelum membuat PDF.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _kSpacing24),
          // Section divider — decorative, exclude from semantics
          Semantics(
            excludeSemantics: true,
            child: Divider(
              height: 32,
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: _kSpacing8),

          // Report type icon + name card surface
          Semantics(
            label: widget.reportType.displayName,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(_kSpacing20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(_kCardRadius),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Semantics(
                    excludeSemantics: true,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _kBrandPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(_kSpacing12),
                      ),
                      child: Icon(
                        _getIconForType(widget.reportType),
                        size: 28,
                        color: _kAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: _kSpacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.reportType.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: _kSpacing4),
                        Text(
                          _getDescriptionForType(widget.reportType),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: _kSpacing24),

          // Date range section — card surface
          Semantics(
            label: 'Periode laporan',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(_kSpacing20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(_kCardRadius),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Periode Laporan',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: _kSpacing16),
                  DateRangeSelector(
                    initialRange: cubit.currentRange,
                    onChanged: (range) => cubit.setDateRange(range),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: _kSpacing16),

          // Zone filter section — card surface (cut/fill only)
          if (widget.reportType == ReportType.cutFill) ...[
            Semantics(
              label: 'Filter zona',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(_kSpacing20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(_kCardRadius),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Zona',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: _kSpacing16),
                    TextFormField(
                      controller: _zoneController,
                      decoration: InputDecoration(
                        labelText: 'ID Zona (Opsional)',
                        hintText: 'Biarkan kosong untuk semua zona',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_kInputRadius),
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) => cubit.setZoneFilter(
                        value.trim().isEmpty ? null : value.trim(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: _kSpacing16),
          ],

          // Error banner
          if (state is ReportError) ...[
            Semantics(
              label: 'Kesalahan: ${state.message}',
              container: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(_kSpacing12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(_kCardRadius),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 20,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: _kSpacing8),
                    Expanded(
                      child: Text(
                        state.message,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: _kSpacing16),
          ],

          // Generate button
          Semantics(
            label: isLoading ? 'Memuat...' : 'Buat Laporan',
            button: true,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () => cubit.generateReport(siteId: defaultSiteId),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: _kSpacing16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kInputRadius),
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
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(_kPagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success header
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Laporan Selesai',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: _kSpacing8),
                Text(
                  'Laporan ${widget.reportType.displayName} berhasil dibuat.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: _kSpacing24),
          // Section divider — decorative, exclude from semantics
          Semantics(
            excludeSemantics: true,
            child: Divider(
              height: 32,
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: _kSpacing8),

          // Summary card
          ReportSummaryCard(result: state.result),
          const SizedBox(height: _kSpacing24),

          // Share PDF button
          Semantics(
            label: 'Bagikan PDF',
            button: true,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Printing.sharePdf(
                    bytes: state.result.pdfBytes,
                    filename: state.result.fileName,
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Bagikan PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: _kSpacing16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kInputRadius),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: _kSpacing12),

          // Print button
          Semantics(
            label: 'Cetak',
            button: true,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Printing.layoutPdf(
                    onLayout: (format) async => state.result.pdfBytes,
                    name: state.result.title,
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text('Cetak'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: _kSpacing16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kInputRadius),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: _kSpacing12),

          // Reset / redo button
          Semantics(
            label: 'Buat Ulang',
            button: true,
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => context.read<ReportCubit>().resetReport(),
                icon: const Icon(Icons.refresh),
                label: const Text('Buat Ulang'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: _kSpacing16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kInputRadius),
                  ),
                ),
              ),
            ),
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

  String _getDescriptionForType(ReportType type) {
    switch (type) {
      case ReportType.attendance:
        return 'Laporan kehadiran kru berdasarkan periode.';
      case ReportType.cutFill:
        return 'Laporan volume galian dan timbunan per zona.';
      case ReportType.inventory:
        return 'Laporan stok material dan perlengkapan.';
    }
  }
}
