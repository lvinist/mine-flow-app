import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
                  trailing: const Icon(LucideIcons.chevronRight),
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
        return LucideIcons.users;
      case ReportType.cutFill:
        return LucideIcons.mountain;
      case ReportType.inventory:
        return LucideIcons.boxes;
      case ReportType.dailyLog:
        return LucideIcons.clipboardList;
      case ReportType.landClearing:
        return LucideIcons.mountainSnow;
      case ReportType.equipmentCheck:
        return LucideIcons.wrench;
      case ReportType.benchmark:
        return LucideIcons.circleDot;
    }
  }
}
