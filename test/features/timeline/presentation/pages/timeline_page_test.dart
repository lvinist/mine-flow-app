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
}
