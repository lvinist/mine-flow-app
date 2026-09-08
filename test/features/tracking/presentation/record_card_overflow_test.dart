// Narrow-surface overflow regression coverage for the record-card class.
//
// STEP-48.26 residual failure R-2: `RenderFlex overflowed` fired at
// `cut_fill_card.dart:33` (80 px bottom, ×3) and `land_clearing_card.dart:30`
// / `:34` (58 px bottom, 53/49/45 px right) in CI run 33480009094, failing the
// Android deep-link journey. 48.22's first pass fixed only
// `timeline_page.dart:289` and never swept the class.
//
// Two causes, both covered here:
//   1. the list screens sized every tile with a fixed `childAspectRatio`, so a
//      card taller than the tile overflowed vertically;
//   2. the cards' header/metadata `Row`s could not shrink, so long badge text
//      overflowed horizontally.
//
// Every card is rendered at 400x800 (phone) and 700x1000 (tablet, two columns)
// with the most content-heavy record shape, and any `RenderFlex overflowed`
// error fails the test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/core/presentation/widgets/adaptive_card_sliver_grid.dart';
import 'package:mine_flow/features/daily_log/domain/entities/daily_log.dart';
import 'package:mine_flow/features/daily_log/domain/entities/log_status.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/daily_log_card.dart';
import 'package:mine_flow/features/tracking/domain/entities/cut_fill_record.dart';
import 'package:mine_flow/features/tracking/domain/entities/land_clearing_record.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/cut_fill_card.dart';
import 'package:mine_flow/features/tracking/presentation/widgets/land_clearing_card.dart';

/// A record with every optional field populated and long values — the worst
/// case for a fixed-height tile.
CutFillRecord _cutFill(int i) => CutFillRecord(
  id: 'cf-$i',
  siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
  zoneId: 'Zona Operasional Utara Blok $i (perluasan)',
  bcmVolume: 123456.75,
  lcmVolume: 98765.25,
  materialType: 'OB / Waste',
  elevationChange: -12.3456,
  measurementDate: DateTime(2026, 9, 1),
  notes:
      'Catatan panjang untuk menguji overflow pada kartu ringkasan pengukuran volume.',
);

LandClearingRecord _landClearing(int i) => LandClearingRecord(
  id: 'lc-$i',
  siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
  zoneId: 'Zona Operasional Selatan Blok $i (perluasan)',
  planArea: 123456.75,
  actualArea: 98765.25,
  method: 'Dozer + Excavator',
  clearingDate: DateTime(2026, 9, 1),
  notes:
      'Catatan panjang untuk menguji overflow pada kartu ringkasan land clearing.',
);

DailyLog _dailyLog(int i) => DailyLog(
  id: 'dl-$i',
  siteId: 'f47ac10b-58cc-4372-a567-0e02b2c3d479',
  foremanId: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
  logDate: DateTime(2026, 9, 1),
  status: LogStatus.submitted,
  zoneId: 'Zona Operasional Utara Blok $i (perluasan)',
  weather: 'Hujan ringan sepanjang shift',
  summary:
      'Ringkasan panjang untuk menguji overflow: pekerjaan cut/fill dan land '
      'clearing berjalan sesuai rencana, tidak ada insiden K3.',
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  /// Renders [cards] through the production sliver layout at [size].
  ///
  /// No `FlutterError.onError` override is used: `flutter_test` already fails a
  /// test on any unexpected framework error, and `RenderFlex overflowed` is
  /// exactly that. Overriding the handler here would swallow other real errors.
  Future<void> pumpCards(
    WidgetTester tester, {
    required Size size,
    required int crossAxisCount,
    required List<Widget> cards,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.touch,
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                AdaptiveCardSliverGrid(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  crossAxisCount: crossAxisCount,
                  itemCount: cards.length,
                  itemBuilder: (context, index) => cards[index],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  const phone = Size(400, 800);
  const tablet = Size(700, 1000);

  for (final surface in <(String, Size, int)>[
    ('phone', phone, 1),
    ('tablet', tablet, 2),
  ]) {
    final (name, size, columns) = surface;

    testWidgets('CutFillCard does not overflow on $name (R-2)', (tester) async {
      await pumpCards(
        tester,
        size: size,
        crossAxisCount: columns,
        cards: [for (var i = 0; i < 4; i++) CutFillCard(record: _cutFill(i))],
      );
      expect(find.byType(CutFillCard), findsWidgets);
    });

    testWidgets('LandClearingCard does not overflow on $name (R-2)', (
      tester,
    ) async {
      await pumpCards(
        tester,
        size: size,
        crossAxisCount: columns,
        cards: [
          for (var i = 0; i < 4; i++)
            LandClearingCard(record: _landClearing(i)),
        ],
      );
      expect(find.byType(LandClearingCard), findsWidgets);
    });

    testWidgets('DailyLogCard does not overflow on $name (R-2)', (
      tester,
    ) async {
      await pumpCards(
        tester,
        size: size,
        crossAxisCount: columns,
        cards: [for (var i = 0; i < 4; i++) DailyLogCard(log: _dailyLog(i))],
      );
      expect(find.byType(DailyLogCard), findsWidgets);
    });
  }

  testWidgets(
    'cards keep their delete affordance visible when onDelete is provided (R-2)',
    (tester) async {
      // The delete row is the tallest optional element and was the part clipped
      // by the fixed-ratio tile. Assert it renders rather than merely not
      // erroring. One card per pump so nothing is off-screen and unbuilt.
      await pumpCards(
        tester,
        size: phone,
        crossAxisCount: 1,
        cards: [CutFillCard(record: _cutFill(0), onDelete: () {})],
      );
      expect(find.byType(IconButton), findsOneWidget);

      await pumpCards(
        tester,
        size: phone,
        crossAxisCount: 1,
        cards: [LandClearingCard(record: _landClearing(0), onDelete: () {})],
      );
      expect(find.byType(IconButton), findsOneWidget);

      await pumpCards(
        tester,
        size: phone,
        crossAxisCount: 1,
        cards: [
          DailyLogCard(
            log: _dailyLog(0).copyWith(status: LogStatus.draft),
            onDelete: () {},
          ),
        ],
      );
      // The card's own Semantics wraps the whole tile, so the delete
      // affordance is asserted by its icon rather than a nested label.
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
    },
  );
}
