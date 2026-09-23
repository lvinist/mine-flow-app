// Report Config Page — report configuration and PDF generation in ForUI aesthetic.
//
// Phase 2 Tier 2 rebuild (STEP-30.4): Replaced hand-rolled Material layouts and
// hardcoded raw Colors.red/Colors.orange/Colors.green with FTheme colors.
// Replaced ElevatedButton/OutlinedButton/TextButton with ForUI FButton components.
// No logic, state, or data-fetching changes.

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/presentation/bloc/report_cubit.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/report_config_content.dart';

/// Report configuration page with date range, zone filter, and generate action.
///
/// Displays a form to configure the report parameters (date range, optional zone)
/// and buttons to generate, share, or print the resulting PDF.
///
/// When accessed without a [reportType] (e.g. standalone navigation without
/// context), renders an explicit no-context state per master spec §3.1.
class ReportConfigPage extends StatefulWidget {
  final ReportType? reportType;

  const ReportConfigPage({super.key, this.reportType});

  @override
  State<ReportConfigPage> createState() => _ReportConfigPageState();
}

class _ReportConfigPageState extends State<ReportConfigPage> {
  @override
  void initState() {
    super.initState();
    if (widget.reportType != null) {
      context.read<ReportCubit>().selectReportType(widget.reportType!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    if (widget.reportType == null) {
      return _buildNoContextView(context, theme);
    }

    return FScaffold(
      header: MediaQuery.of(context).size.width > 800
          ? null
          : FHeader(
              title: Semantics(
                header: true,
                child: Text(
                  'Konfigurasi ${widget.reportType!.displayName}',
                  style: theme.typography.display.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
      child: ReportConfigContent(reportType: widget.reportType!),
    );
  }

  Widget _buildNoContextView(BuildContext context, FThemeData theme) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    return FScaffold(
      header: MediaQuery.of(context).size.width > 800
          ? null
          : FHeader(
              title: Semantics(
                header: true,
                child: Text(
                  isEn ? 'Report Configuration' : 'Konfigurasi Laporan',
                  style: theme.typography.display.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: FCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.fileX,
                      size: 48,
                      color: theme.colors.mutedForeground,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEn
                          ? 'Reports unavailable without feature context'
                          : 'Laporan tidak tersedia tanpa konteks fitur',
                      textAlign: TextAlign.center,
                      style: theme.typography.body.lg.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isEn
                          ? 'Reports must be launched from their respective feature screens (Cut & Fill, Land Clearing, Attendance, etc.).'
                          : 'Laporan harus dibuka dari menu fitur terkait (Cut & Fill, Land Clearing, Kehadiran, dll.) agar konteks dan filter terisi otomatis.',
                      textAlign: TextAlign.center,
                      style: theme.typography.body.md.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FButton(
                      variant: FButtonVariant.primary,
                      onPress: () => context.go(AppRoutes.dashboard),
                      child: Text(
                        isEn ? 'Back to Dashboard' : 'Kembali ke Dashboard',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
