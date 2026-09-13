import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:mine_flow/features/timeline/presentation/pages/timeline_page.dart';
import 'package:mocktail/mocktail.dart';

class MockTimelineRepository extends Mock implements TimelineRepository {}

void main() {
  late MockTimelineRepository repository;

  setUp(() {
    repository = MockTimelineRepository();
    when(
      () => repository.getMilestones(
        siteId: any(named: 'siteId'),
        zoneId: any(named: 'zoneId'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => repository.getProgressData(
        siteId: any(named: 'siteId'),
        zoneId: any(named: 'zoneId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => []);
  });

  testWidgets('summary badges wrap without overflow on a phone surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final errors = <String>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.toString());
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.touch,
        child: MaterialApp(
          home: TimelinePage(repository: repository, siteId: 'site-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Berjalan 0'), findsOneWidget);
    expect(find.text('Selesai 0'), findsOneWidget);
    expect(find.text('Terlambat 0'), findsOneWidget);
    expect(
      errors.where(
        (error) => error.toString().contains('RenderFlex overflowed'),
      ),
      isEmpty,
    );
  });

  testWidgets('Work Timeline is strictly read-only: no create form, no FAB, no report action', (
    tester,
  ) async {
    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.touch,
        child: MaterialApp(
          home: TimelinePage(repository: repository, siteId: 'site-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify zero FloatingActionButton instances
    expect(find.byType(FloatingActionButton), findsNothing);

    // Verify zero create/add milestone buttons
    expect(find.widgetWithText(FButton, 'Tambah Milestone'), findsNothing);
    expect(find.widgetWithText(FButton, 'Buat Milestone'), findsNothing);

    // Verify zero report actions (per Master Spec §4.8 deliberate absence)
    expect(find.bySemanticsLabel('Buat Laporan Timeline'), findsNothing);
    expect(find.widgetWithText(FButton, 'Laporan'), findsNothing);
    expect(find.widgetWithText(FButton, 'Buat Laporan'), findsNothing);
  });

  testWidgets('renders desktop layout with Muat Ulang refresh button on wide screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.touch,
        child: MaterialApp(
          home: TimelinePage(repository: repository, siteId: 'site-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FButton, 'Muat Ulang'), findsOneWidget);
    await tester.tap(find.widgetWithText(FButton, 'Muat Ulang'));
    await tester.pumpAndSettle();

    // Verify repository load was called again
    verify(() => repository.getMilestones(siteId: 'site-1')).called(2);
  });
}
