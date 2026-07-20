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

/// Curve constant for micro-interactions (DESIGN.md §33).
const Curve _kAnimCurve = Curves.easeOutQuart;

/// Card border radius for surface containers — matches the 12dp used across
/// Phase 2 card surfaces (DESIGN.md §29 shape scale).
const double _kCardRadius = 12;
const double _kInputRadius = 8;

/// Report configuration page with date range, zone filter, and generate action.
///
/// Displays a form to configure the report parameters (date range, optional zone)
/// and buttons to generate, share, or print the resulting PDF.
///
/// Phase 2 Polish (substep 26.2): staggered entrance animations with
/// easeOutQuart curves, refined spacing using DESIGN.md spacing scale,
/// micro-interactions on all tappable elements, and consistent theme-token
/// usage throughout (no raw color values).
class ReportConfigPage extends StatefulWidget {
  final ReportType reportType;

  const ReportConfigPage({super.key, required this.reportType});

  @override
  State<ReportConfigPage> createState() => _ReportConfigPageState();
}

class _ReportConfigPageState extends State<ReportConfigPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _zoneController = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _headerFade;
  late final Animation<double> _typeCardFade;
  late final Animation<double> _dateFade;
  late final Animation<double> _zoneFade;
  late final Animation<double> _actionFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<Offset> _typeCardSlide;
  late final Animation<Offset> _dateSlide;
  late final Animation<Offset> _zoneSlide;
  late final Animation<Offset> _actionSlide;

  /// Tracks whether the success view entrance has been triggered.
  bool _successEntered = false;

  @override
  void initState() {
    super.initState();
    context.read<ReportCubit>().selectReportType(widget.reportType);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Staggered entrance: each section fades + slides in with 80ms offset.
    const curve = _kAnimCurve;

    _headerFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.4, curve: curve),
    );
    _typeCardFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.1, 0.45, curve: curve),
    );
    _dateFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.55, curve: curve),
    );
    _zoneFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 0.65, curve: curve),
    );
    _actionFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 0.75, curve: curve),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_headerFade);
    _typeCardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_typeCardFade);
    _dateSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_dateFade);
    _zoneSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_zoneFade);
    _actionSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_actionFade);

    _animController.forward();
  }

  @override
  void dispose() {
    _zoneController.dispose();
    _animController.dispose();
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
      body: BlocListener<ReportCubit, ReportState>(
        listener: (context, state) {
          if (state is ReportSuccess && !_successEntered) {
            // Reset and replay entrance for success view.
            _successEntered = true;
            _animController.reset();
            _animController.forward();
          }
        },
        child: BlocBuilder<ReportCubit, ReportState>(
          builder: (context, state) {
            if (state is ReportSuccess) {
              return _buildSuccessView(context, state, theme, colorScheme);
            }
            return _buildConfigForm(context, state, theme, colorScheme);
          },
        ),
      ),
    );
  }

  Widget _buildConfigForm(
    BuildContext context,
    ReportState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final cubit = context.read<ReportCubit>();
    final isLoading = state is ReportLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(_kPagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header — staggered entrance 1
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: ConstrainedBox(
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

          // Report type icon + name card surface — staggered entrance 2
          FadeTransition(
            opacity: _typeCardFade,
            child: SlideTransition(
              position: _typeCardSlide,
              child: _buildReportTypeCard(theme, colorScheme),
            ),
          ),
          const SizedBox(height: _kSpacing24),

          // Date range section — staggered entrance 3
          FadeTransition(
            opacity: _dateFade,
            child: SlideTransition(
              position: _dateSlide,
              child: _buildDateRangeSection(theme, colorScheme, cubit),
            ),
          ),
          const SizedBox(height: _kSpacing16),

          // Zone filter section — staggered entrance 4 (cut/fill only)
          if (widget.reportType == ReportType.cutFill) ...[
            FadeTransition(
              opacity: _zoneFade,
              child: SlideTransition(
                position: _zoneSlide,
                child: _buildZoneFilterSection(theme, colorScheme, cubit),
              ),
            ),
            const SizedBox(height: _kSpacing16),
          ],

          // Error banner
          if (state is ReportError) ...[
            _buildErrorBanner(state, theme, colorScheme),
            const SizedBox(height: _kSpacing16),
          ],

          // Generate button — staggered entrance 5
          FadeTransition(
            opacity: _actionFade,
            child: SlideTransition(
              position: _actionSlide,
              child: _buildGenerateButton(context, isLoading, colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard(ThemeData theme, ColorScheme colorScheme) {
    return Semantics(
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
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(_kSpacing12),
                ),
                child: Icon(
                  _getIconForType(widget.reportType),
                  size: 28,
                  color: colorScheme.primary,
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
    );
  }

  Widget _buildDateRangeSection(
    ThemeData theme,
    ColorScheme colorScheme,
    ReportCubit cubit,
  ) {
    return Semantics(
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
    );
  }

  Widget _buildZoneFilterSection(
    ThemeData theme,
    ColorScheme colorScheme,
    ReportCubit cubit,
  ) {
    return Semantics(
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
    );
  }

  Widget _buildErrorBanner(
    ReportError state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Semantics(
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
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton(
    BuildContext context,
    bool isLoading,
    ColorScheme colorScheme,
  ) {
    return Semantics(
      label: isLoading ? 'Memuat...' : 'Buat Laporan',
      button: true,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () => context.read<ReportCubit>().generateReport(
                  siteId: defaultSiteId,
                ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: _kSpacing16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_kInputRadius),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Text(
                  'Buat Laporan',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
        ),
      ),
    );
  }

  // ——— Success view ———

  Widget _buildSuccessView(
    BuildContext context,
    ReportSuccess state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(_kPagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success header — staggered entrance 1
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: ConstrainedBox(
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

          // Summary card — staggered entrance 2
          FadeTransition(
            opacity: _typeCardFade,
            child: SlideTransition(
              position: _typeCardSlide,
              child: ReportSummaryCard(result: state.result),
            ),
          ),
          const SizedBox(height: _kSpacing24),

          // Share PDF button — staggered entrance 3
          FadeTransition(
            opacity: _dateFade,
            child: SlideTransition(
              position: _dateSlide,
              child: Semantics(
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
                      padding: const EdgeInsets.symmetric(
                        vertical: _kSpacing16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_kInputRadius),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: _kSpacing12),

          // Print button — staggered entrance 4
          FadeTransition(
            opacity: _zoneFade,
            child: SlideTransition(
              position: _zoneSlide,
              child: Semantics(
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
                      padding: const EdgeInsets.symmetric(
                        vertical: _kSpacing16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_kInputRadius),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: _kSpacing12),

          // Reset / redo button — staggered entrance 5
          FadeTransition(
            opacity: _actionFade,
            child: SlideTransition(
              position: _actionSlide,
              child: Semantics(
                label: 'Buat Ulang',
                button: true,
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => context.read<ReportCubit>().resetReport(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Buat Ulang'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: _kSpacing16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_kInputRadius),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ——— Helpers ———

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
