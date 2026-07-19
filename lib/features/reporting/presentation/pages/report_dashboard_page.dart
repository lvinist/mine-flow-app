import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/report_type_card.dart';

/// Dashboard page for selecting report types.
///
/// Displays a grid of [ReportTypeCard] widgets, one for each available
/// report type. Tapping a card navigates to the report config page.
class ReportDashboardPage extends StatelessWidget {
  const ReportDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: The route '/reports/config' will be wired in substep 9.5
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Jenis Laporan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih jenis laporan yang ingin Anda buat dan unduh dalam format PDF.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
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
