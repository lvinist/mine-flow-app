import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/report_type_card.dart';

// Phase 2 — shadcn-admin design language constants (DESIGN.md §29).
const double _kPagePadding = 24;

/// Spacing scale derived from DESIGN.md §29 (4, 8, 12, 16, 20, 24, 32 dp).
const double _kSpacing8 = 8;
const double _kSpacing16 = 16;
const double _kSpacing24 = 24;

/// Dashboard page for selecting report types.
///
/// Displays a grid of [ReportTypeCard] widgets, one for each available
/// report type. Tapping a card navigates to the report config page.
class ReportDashboardPage extends StatelessWidget {
  const ReportDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Note: The route '/reports/config' will be wired in substep 9.5
    return Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: const Text('Laporan')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_kPagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page header
            Semantics(
              header: true,
              child: Text(
                'Pilih Jenis Laporan',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: _kSpacing8),
            Text(
              'Pilih jenis laporan yang ingin Anda buat dan unduh dalam format PDF.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: _kSpacing24),
            // Report type grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: screenWidth > 600 ? 3 : 2,
              crossAxisSpacing: _kSpacing16,
              mainAxisSpacing: _kSpacing16,
              childAspectRatio: 0.85,
              children: [
                ReportTypeCard(
                  type: ReportType.attendance,
                  icon: Icons.people_outline,
                  onTap: () {
                    context.push(
                      '/reports/config',
                      extra: ReportType.attendance,
                    );
                  },
                ),
                ReportTypeCard(
                  type: ReportType.cutFill,
                  icon: Icons.terrain_outlined,
                  onTap: () {
                    context.push('/reports/config', extra: ReportType.cutFill);
                  },
                ),
                ReportTypeCard(
                  type: ReportType.inventory,
                  icon: Icons.inventory_2_outlined,
                  onTap: () {
                    context.push(
                      '/reports/config',
                      extra: ReportType.inventory,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
