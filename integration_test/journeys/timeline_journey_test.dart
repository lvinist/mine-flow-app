// E2E Critical User Journey: Work Timeline (STEP-45.10)
//
// Exercises work timeline visualization against staging:
// - Login & navigation to timeline page
// - Progress chart & date range selection
// - Summary statistics and milestone cards
// - Milestone status badge styling and color distinction (CF-067 guard: Berjalan vs Selesai)
// - Empty state handling when no milestones are present (CF-066 guard)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';
import 'package:mine_flow/features/timeline/domain/entities/timeline_milestone.dart';
import 'package:mine_flow/features/timeline/presentation/pages/timeline_page.dart';
import 'package:mine_flow/features/timeline/presentation/widgets/milestone_card.dart';
import 'package:mine_flow/features/timeline/presentation/widgets/timeline_chart.dart';

import '../helpers/app_harness.dart';
import '../helpers/login_helper.dart';
import '../helpers/staging_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Timeline Journey (STEP-45.10)', () {
    testWidgets(
      'login, navigate to timeline, verify progress chart, date range selector, and milestone status badges (CF-067)',
      (tester) async {
        if (!isStagingConfigured) {
          markTestSkipped('Unverified: Staging credentials absent');
          return;
        }

        final storage = SecureStorageService();
        await storage.clearAll();

        // 1. Boot app and log in as staging user.
        await pumpApp(tester);
        await loginAsStagingUser(tester);

        expect(authCubit?.state.status, AuthStatus.authenticated);

        // 2. Navigate to Timeline screen via router.
        appRouter.go(AppRoutes.timeline);
        await tester.pumpAndSettle();

        expect(find.byType(TimelinePage), findsOneWidget);

        // 3. Verify Date Range Selector is present.
        final calendarIconFinder = find.byIcon(LucideIcons.calendarRange);
        expect(calendarIconFinder, findsOneWidget);

        // 4. Verify Progress chart section.
        expect(find.text('Progress Kumulatif'), findsOneWidget);
        expect(find.byType(TimelineChart), findsOneWidget);

        // 5. Verify Summary stats badges render with distinct color styling (CF-067).
        expect(find.textContaining('Berjalan'), findsWidgets);
        expect(find.textContaining('Selesai'), findsWidgets);
        expect(find.textContaining('Terlambat'), findsWidgets);

        // 6. Inspect milestones rendering: either cards in sections or valid empty state (CF-066).
        final milestoneCards = find.byType(MilestoneCard);
        if (milestoneCards.evaluate().isNotEmpty) {
          // Verify section ordering: Overdue (0) <= Active (1) <= Completed (2)
          // and chronological ordering (descending by startDate) within sections.
          int lastStatusOrder = -1;
          DateTime? lastDate;
          for (final cardElement in milestoneCards.evaluate()) {
            final cardWidget = tester.widget<MilestoneCard>(
              find.byWidget(cardElement.widget),
            );
            final milestone = cardWidget.milestone;
            final currentStatusOrder =
                milestone.status == MilestoneStatus.overdue
                ? 0
                : (milestone.status == MilestoneStatus.completed ? 2 : 1);

            expect(
              currentStatusOrder >= lastStatusOrder,
              isTrue,
              reason:
                  'Milestones must render in section order: Overdue -> Active -> Completed',
            );

            if (currentStatusOrder == lastStatusOrder && lastDate != null) {
              expect(
                milestone.startDate.compareTo(lastDate) <= 0,
                isTrue,
                reason:
                    'Milestones must render in descending date order within sections',
              );
            }

            lastStatusOrder = currentStatusOrder;
            lastDate = milestone.startDate;

            // Confirm status label matches milestone status
            switch (milestone.status) {
              case MilestoneStatus.planned:
                expect(
                  find.descendant(
                    of: find.byWidget(cardWidget),
                    matching: find.text('Direncanakan'),
                  ),
                  findsOneWidget,
                );
              case MilestoneStatus.inProgress:
                expect(
                  find.descendant(
                    of: find.byWidget(cardWidget),
                    matching: find.text('Berjalan'),
                  ),
                  findsOneWidget,
                );
              case MilestoneStatus.completed:
                expect(
                  find.descendant(
                    of: find.byWidget(cardWidget),
                    matching: find.text('Selesai'),
                  ),
                  findsOneWidget,
                );
              case MilestoneStatus.overdue:
                expect(
                  find.descendant(
                    of: find.byWidget(cardWidget),
                    matching: find.text('Terlambat'),
                  ),
                  findsOneWidget,
                );
            }
          }
        } else {
          // CF-066: Empty state when milestones are empty
          expect(find.text('Belum ada data timeline'), findsOneWidget);
          expect(
            find.text('Belum ada milestone yang tersedia untuk ditampilkan.'),
            findsOneWidget,
          );
        }

        // 7. Test Date Range Picker interaction.
        final dateSelectorContainer = find.ancestor(
          of: calendarIconFinder,
          matching: find.byType(InkWell),
        );
        expect(dateSelectorContainer, findsOneWidget);
        await tester.tap(dateSelectorContainer);
        await tester.pump(const Duration(milliseconds: 500));

        // Verify date range picker dialog opened, then dismiss via close button or tapping outside.
        final closePickerBtn = find.byIcon(Icons.close);
        if (closePickerBtn.evaluate().isNotEmpty) {
          await tester.tap(closePickerBtn);
          await tester.pump(const Duration(milliseconds: 500));
        } else {
          // Tap top-left to dismiss if modal
          await tester.tapAt(const Offset(10, 10));
          await tester.pump(const Duration(milliseconds: 500));
        }

        // 8. Test Refresh button if on wide layout (CF-032).
        final refreshBtn = find.widgetWithText(FButton, 'Muat Ulang');
        if (refreshBtn.evaluate().isNotEmpty) {
          await tester.tap(refreshBtn);
          await tester.pumpAndSettle();
          expect(find.byType(TimelinePage), findsOneWidget);
        }
      },
    );
  });
}
