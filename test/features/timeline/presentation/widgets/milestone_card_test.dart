import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_milestone.dart';
import 'package:mine_flow/features/timeline/presentation/widgets/milestone_card.dart';

void main() {
  final testMilestone = TimelineMilestone(
    id: 'm1',
    siteId: 's1',
    title: 'Penggalian Sektor A',
    description: 'Target penggalian awal 50,000 m3',
    startDate: DateTime(2026, 7, 1),
    targetDate: DateTime(2026, 7, 15),
    targetValue: 50000,
    actualValue: 25000,
    status: MilestoneStatus.inProgress,
  );

  Widget buildTestWidget({
    required TimelineMilestone milestone,
    VoidCallback? onTap,
  }) {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        home: Scaffold(
          body: MilestoneCard(milestone: milestone, onTap: onTap),
        ),
      ),
    );
  }

  group('MilestoneCard', () {
    testWidgets('does not use raw Material Card widget', (tester) async {
      await tester.pumpWidget(buildTestWidget(milestone: testMilestone));

      expect(find.byType(Card), findsNothing);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders milestone details correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget(milestone: testMilestone));

      expect(find.text('Penggalian Sektor A'), findsOneWidget);
      expect(find.text('Target penggalian awal 50,000 m3'), findsOneWidget);
      expect(find.text('Berjalan'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestWidget(milestone: testMilestone, onTap: () => tapped = true),
      );

      await tester.tap(find.text('Penggalian Sektor A'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
