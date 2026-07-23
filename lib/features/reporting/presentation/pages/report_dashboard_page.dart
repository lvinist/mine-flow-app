// Report Dashboard — report type selection in ForUI aesthetic.
//
// Phase 2 Tier 2 rebuild (STEP-30.4): Replaced hand-rolled Material layouts and
// hardcoded raw colors with ForUI components (FCard, FButton) and FTheme
// colors/typography tokens. No logic, state, or data-fetching changes.

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/report_type_card.dart';

const double _kPagePadding = 24;
const double _kSpacing8 = 8;
const double _kSpacing24 = 24;

/// Dashboard page for selecting report types.
///
/// Displays a grid of [ReportTypeCard] widgets, one for each available
/// report type. Tapping a card navigates to the report config page.
class ReportDashboardPage extends StatelessWidget {
  const ReportDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      appBar: MediaQuery.of(context).size.width > 800 ? null : AppBar(
        title: Semantics(
          header: true,
          child: Text(
            'Laporan',
            style: theme.typography.display.sm.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(_kPagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Pilih Jenis Laporan',
                style: theme.typography.display.xs.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: _kSpacing8),
            Text(
              'Pilih jenis laporan yang ingin Anda buat dan unduh dalam format PDF.',
              style: theme.typography.body.md.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: _kSpacing24),
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
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
