import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';

/// Landing page that lets the user pick a report type (CF-030).
///
/// Shown when `/reports/config` is opened without a report type, so the
/// Reports entry is usable from a fresh load / deep link instead of depending
/// on another feature screen's FAB.
class ReportTypePickerPage extends StatelessWidget {
  const ReportTypePickerPage({super.key});

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
                  'Pilih Jenis Laporan',
                  style: theme.typography.display.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          for (final type in ReportType.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FCard(
                child: ListTile(
                  leading: Icon(_iconFor(type), color: theme.colors.primary),
                  title: Text(
                    type.displayName,
                    style: theme.typography.body.md.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.pushNamed('report-config', extra: type),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(ReportType type) {
    switch (type) {
      case ReportType.attendance:
        return Icons.people_outline;
      case ReportType.cutFill:
        return Icons.terrain_outlined;
      case ReportType.inventory:
        return Icons.inventory_2_outlined;
      case ReportType.dailyLog:
        return Icons.event_note_outlined;
      case ReportType.landClearing:
        return Icons.landscape_outlined;
      case ReportType.equipmentCheck:
        return Icons.build_outlined;
      case ReportType.benchmark:
        return Icons.trip_origin;
    }
  }
}
