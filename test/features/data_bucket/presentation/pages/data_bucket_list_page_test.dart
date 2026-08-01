import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/pages/data_bucket_list_page.dart';
import 'package:mocktail/mocktail.dart';

class MockDataBucketRepository extends Mock implements DataBucketRepository {}

void main() {
  late MockDataBucketRepository mockRepository;

  setUp(() {
    mockRepository = MockDataBucketRepository();
    when(() => mockRepository.getFiles(
          siteId: any(named: 'siteId'),
          zoneId: any(named: 'zoneId'),
          fileType: any(named: 'fileType'),
          searchQuery: any(named: 'searchQuery'),
        )).thenAnswer((_) async => []);
  });

  Widget buildTestWidget() {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp(
        home: DataBucketListPage(
          repository: mockRepository,
          siteId: 'site-1',
        ),
      ),
    );
  }

  group('DataBucketListPage Substep 38.1 Widget Tests', () {
    testWidgets('renders Upload File and Laporan in FABs', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Upload File FAB
      expect(find.widgetWithText(FloatingActionButton, 'Upload File'), findsOneWidget);

      // Verify Laporan FAB via semantics label
      expect(find.bySemanticsLabel('Buat Laporan Data Bucket'), findsOneWidget);
    });
  });
}
