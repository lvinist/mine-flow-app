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
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Note: The route '/reports/config' will be wired in substep 9.5
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(
            'Laporan',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                      'Pilih Jenis Laporan',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: _kSpacing8),
                  Text(
                    'Pilih jenis laporan yang ingin Anda buat dan unduh dalam format PDF.',
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
            // Report type grid
            Semantics(
              label: 'Pilih jenis laporan',
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // 3 columns on wide screens, 2 on medium, 1 on very narrow (< 360dp)
                crossAxisCount: screenWidth < 360
                    ? 1
                    : screenWidth > 600
                    ? 3
                    : 2,
                crossAxisSpacing: _kSpacing16,
                mainAxisSpacing: _kSpacing16,
                // Looser aspect ratio on narrow screens to prevent content overflow
                childAspectRatio: screenWidth < 360 ? 1.0 : 0.85,
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
                      context.push(
                        '/reports/config',
                        extra: ReportType.cutFill,
                      );
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
            ),
          ],
        ),
      ),
    );
  }
}
