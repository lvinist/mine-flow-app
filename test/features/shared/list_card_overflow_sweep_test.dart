// Class-level overflow sweep across every list-card widget (STEP-48.22 re-run,
// finding R-2 / BH-015).
//
// The lesson from CI run 33480009094 is that fixing the `file:line` a failure
// names leaves the class alive elsewhere. So rather than testing only the two
// cards the log happened to name, this suite renders EVERY card that appears in a
// scrollable list at the narrowest supported width (Doc 07: Android locks to
// portrait mobile) with worst-case content — long zone names, UUID identifiers,
// full timestamps, all optional fields populated — and lets `flutter_test` fail
// on any `RenderFlex overflowed`.
//
// The emulator's own logical width (393x873, Pixel-class) is included alongside
// 400x800 because the CI overflow was reported at the device width, not the
// default 800x600 test surface.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/presentation/widgets/file_card.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_status.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/check_type.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_check.dart';
import 'package:mine_flow/features/equipment_check/domain/entities/equipment_type.dart';
import 'package:mine_flow/features/equipment_check/presentation/widgets/equipment_check_card.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_milestone.dart';
import 'package:mine_flow/features/timeline/presentation/widgets/milestone_card.dart';
import 'package:mine_flow/features/tracking/domain/entities/inventory_item.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/inventory_card.dart';

const _uuid = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
const _longZone = 'Zona Operasional Utara Blok 7 (perluasan tahap 2)';

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  /// Renders [child] in a scrollable at [size] and lets the framework fail the
  /// test on any layout overflow.
  Future<void> pumpCard(
    WidgetTester tester,
    Widget child, {
    required Size size,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.touch,
        child: MaterialApp(
          locale: const Locale('id'),
          home: Scaffold(body: ListView(children: [child])),
        ),
      ),
    );
    await tester.pump();
  }

  final surfaces = <String, Size>{
    // The emulator/CI device width, where the run 33480009094 overflows fired.
    'device 393x873': const Size(393, 873),
    'phone 400x800': const Size(400, 800),
  };

  final cards = <String, Widget>{
    'EquipmentCheckCard': EquipmentCheckCard(
      check: EquipmentCheck(
        id: 'ec-1',
        siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        foremanId: _uuid,
        equipmentType: EquipmentType.totalStation,
        checkType: CheckType.preWork,
        status: CheckStatus.flagged,
        checkTime: DateTime(2026, 9, 1, 14, 35),
        serialNumber: 'TS-9982-XYZ',
        checklist: const [],
      ),
    ),
    'FileCard': FileCard(
      file: GeospatialFile(
        id: 'gf-1',
        siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        zoneId: _longZone,
        fileName: 'survey_topografi_area_utara_20260901_final_v3.tiff',
        fileType: '.tiff',
        mimeType: 'image/tiff',
        driveFileId: 'drive-1',
        driveLink: 'https://drive.google.com/file/d/1/view',
        fileSizeBytes: 48 * 1024 * 1024,
        acquisitionDate: DateTime(2026, 8, 30),
        notes: 'Catatan panjang untuk menguji batas lebar kartu file.',
        uploadedBy: _uuid,
        createdAt: DateTime(2026, 9),
        updatedAt: DateTime(2026, 9),
      ),
    ),
    'InventoryCard': InventoryCard(
      item: InventoryItem(
        id: 'inv-1',
        siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        zoneId: _longZone,
        itemName: 'Solar (Bio Diesel B35) — drum 200 liter',
        sku: 'SKU-000123456789',
        category: 'Bahan Bakar',
        quantityOnHand: 123456.75,
        unit: 'liter',
        minThreshold: 5000,
        notes: 'Catatan panjang untuk menguji batas lebar kartu inventori.',
        createdAt: DateTime(2026, 9),
        updatedAt: DateTime(2026, 9),
      ),
    ),
    'MilestoneCard': MilestoneCard(
      milestone: TimelineMilestone(
        id: 'tm-1',
        siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
        zoneId: _longZone,
        title: 'Penyelesaian pembersihan lahan tahap dua blok utara',
        description: 'Deskripsi panjang untuk menguji batas lebar kartu.',
        targetValue: 123456.75,
        actualValue: 98765.25,
        targetDate: DateTime(2026, 10, 15),
        startDate: DateTime(2026, 9),
        endDate: DateTime(2026, 10, 31),
        status: MilestoneStatus.inProgress,
      ),
    ),
  };

  for (final surface in surfaces.entries) {
    for (final card in cards.entries) {
      testWidgets('${card.key} does not overflow on ${surface.key} (R-2)', (
        tester,
      ) async {
        await pumpCard(tester, card.value, size: surface.value);
        expect(find.byWidget(card.value), findsOneWidget);
      });
    }
  }
}
