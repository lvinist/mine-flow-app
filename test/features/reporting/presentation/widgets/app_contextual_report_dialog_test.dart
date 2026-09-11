import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';
import 'package:mine_flow/features/reporting/domain/repositories/reporting_repository.dart';
import 'package:mine_flow/features/reporting/presentation/widgets/app_contextual_report_dialog.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockReportingRepository extends Mock implements ReportingRepository {}
class MockZoneRepository extends Mock implements ZoneRepository {}

void main() {
  late MockReportingRepository reportingRepository;
  late MockZoneRepository zoneRepository;

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  setUp(() {
    reportingRepository = MockReportingRepository();
    zoneRepository = MockZoneRepository();
    when(() => zoneRepository.getZones()).thenReturn([]);
  });



  Widget wrap(Widget child) {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  testWidgets('showAppContextualReportDialog opens dialog and keeps origin mounted', (tester) async {
    await tester.pumpWidget(wrap(
      Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () {
              showAppContextualReportDialog(
                context: context,
                reportType: ReportType.attendance,
                sourceTitle: 'Kehadiran',
                reportingRepository: reportingRepository,
                zoneRepository: zoneRepository,
              );
            },
            child: const Text('Buka Dialog'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Buka Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Laporan: Kehadiran'), findsOneWidget);
    expect(find.text('Laporan Kehadiran'), findsWidgets); // reportType.displayName
    expect(find.text('Buka Dialog'), findsOneWidget); // Origin route still mounted
  });
}
