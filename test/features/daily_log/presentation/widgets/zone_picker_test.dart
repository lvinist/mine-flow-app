import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/core/domain/entities/zone_entity.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/features/zone/presentation/bloc/zone_cubit.dart';

class MockZoneRepository extends Mock implements ZoneRepository {}

Widget buildTestWidget({
  required ZoneCubit cubit,
  String? selectedZoneId,
  ValueChanged<String?>? onZoneSelected,
}) {
  return FTheme(
    data: FTheme.neutral.light.touch,
    child: BlocProvider<ZoneCubit>.value(
      value: cubit,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ZonePicker(
              selectedZoneId: selectedZoneId,
              onZoneSelected: onZoneSelected ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late MockZoneRepository mockRepository;
  late ZoneCubit cubit;

  final testZones = [
    ZoneEntity(
      id: 'zone-1',
      siteId: 'site-1',
      name: 'Pit A - Utama (North Cut)',
      category: 'Pit',
      createdAt: DateTime(2026, 7, 23),
    ),
    ZoneEntity(
      id: 'zone-2',
      siteId: 'site-1',
      name: 'Stockpile 1 (ROM)',
      category: 'Stockpile',
      createdAt: DateTime(2026, 7, 23),
    ),
  ];

  setUp(() {
    mockRepository = MockZoneRepository();
    cubit = ZoneCubit(repository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('ZonePicker', () {
    testWidgets('shows error state when ZoneError emitted', (tester) async {
      when(() => mockRepository.getZones()).thenThrow(Exception('Gagal'));

      await tester.pumpWidget(buildTestWidget(cubit: cubit));
      await cubit.loadZones();
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.textContaining('Gagal'), findsOneWidget);
    });

    testWidgets('renders CreatableCombobox with zone names when loaded', (
      tester,
    ) async {
      when(() => mockRepository.getZones()).thenReturn(testZones);

      await tester.pumpWidget(buildTestWidget(cubit: cubit));
      await cubit.loadZones();
      await tester.pumpAndSettle();

      // Label should be present
      expect(find.text('Zona Operasional'), findsOneWidget);

      // Focus the text field to show dropdown
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      // Zone names should be visible
      expect(find.text('Pit A - Utama (North Cut)'), findsWidgets);
      expect(find.text('Stockpile 1 (ROM)'), findsWidgets);
    });

    testWidgets('calls onZoneSelected when a zone is tapped', (tester) async {
      when(() => mockRepository.getZones()).thenReturn(testZones);

      String? selectedId;
      await tester.pumpWidget(
        buildTestWidget(cubit: cubit, onZoneSelected: (id) => selectedId = id),
      );
      await cubit.loadZones();
      await tester.pumpAndSettle();

      // Focus and tap on first zone
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pit A - Utama (North Cut)').last);
      await tester.pumpAndSettle();

      expect(selectedId, equals('zone-1'));
    });
  });
}
