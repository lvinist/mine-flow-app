/// Navigation tests for Benchmark feature routes and screens.
///
/// Verifies direct navigation to edit mode and push transition from
/// inspector to form screen, preventing timing and occlusion regressions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/core/navigation/route_observer.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/features/benchmark/domain/entities/benchmark.dart';
import 'package:mine_flow/features/benchmark/domain/repositories/benchmark_repository.dart';
import 'package:mine_flow/features/benchmark/presentation/pages/benchmark_form_screen.dart';
import 'package:mine_flow/features/benchmark/presentation/pages/benchmark_inspector_screen.dart';
import 'package:mine_flow/features/benchmark/presentation/pages/benchmark_list_screen.dart';
import 'package:mine_flow/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockBenchmarkRepository extends Mock implements BenchmarkRepository {}

void main() {
  late MockBenchmarkRepository mockRepository;

  const testBenchmark = Benchmark(
    id: 'test-id-1',
    bmId: 'BM-01',
    northing: -8500000.123,
    easting: 300000.456,
    orthoHeight: 150.5,
    code: 'CP-01',
    orde: 'Orde 2',
    latitude: -7.5,
    longitude: 110.5,
    ellipsHeight: 152.0,
    status: 'active',
  );

  setUpAll(() {
    registerFallbackValue(testBenchmark);
  });

  setUp(() {
    mockRepository = MockBenchmarkRepository();
    when(
      () => mockRepository.getBenchmarks(),
    ).thenAnswer((_) async => [testBenchmark]);
    when(
      () => mockRepository.getBenchmarkById('test-id-1'),
    ).thenAnswer((_) async => testBenchmark);
  });

  GoRouter buildRouter({required String initialLocation}) {
    return GoRouter(
      initialLocation: initialLocation,
      observers: [routeObserver],
      routes: [
        GoRoute(
          path: '/operations/benchmark-db',
          name: 'benchmark-db',
          builder: (context, state) => BenchmarkListScreen(
            key: ValueKey(state.pageKey),
            repository: mockRepository,
          ),
          routes: [
            GoRoute(
              path: 'form',
              name: 'benchmark-form',
              builder: (context, state) =>
                  BenchmarkFormScreen(repository: mockRepository),
            ),
            GoRoute(
              path: ':id',
              name: 'benchmark-detail',
              pageBuilder: (context, state) {
                return CustomTransitionPage<void>(
                  key: state.pageKey,
                  opaque: false,
                  barrierColor: const Color(0x00000000),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  child: BenchmarkInspectorScreen(
                    repository: mockRepository,
                    benchmarkId: state.pathParameters['id']!,
                    existingBenchmark: state.extra as Benchmark?,
                    routeUri: state.uri,
                  ),
                );
              },
            ),
            GoRoute(
              path: ':id/form',
              name: 'benchmark-edit',
              pageBuilder: (context, state) {
                return CustomTransitionPage<void>(
                  key: state.pageKey,
                  opaque: false,
                  barrierColor: const Color(0x00000000),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  child: BenchmarkFormScreen(
                    repository: mockRepository,
                    benchmarkId: state.pathParameters['id'],
                    existingBenchmark: state.extra as Benchmark?,
                    routeUri: state.uri,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget buildApp(GoRouter router) {
    return FTheme(
      data: FTheme.neutral.light.touch,
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) =>
            FToaster(child: child ?? const SizedBox.shrink()),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('id'), Locale('en')],
      ),
    );
  }

  group('Benchmark Navigation and Push Transition', () {
    testWidgets(
      'direct navigation to benchmark edit mode resolves BenchmarkFormScreen',
      (tester) async {
        final router = buildRouter(
          initialLocation: '/operations/benchmark-db/test-id-1/form',
        );
        await tester.pumpWidget(buildApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkFormScreen), findsOneWidget);
      },
    );

    testWidgets(
      'push transition from BenchmarkInspectorScreen via edit button mounts BenchmarkFormScreen',
      (tester) async {
        final router = buildRouter(
          initialLocation: '/operations/benchmark-db/test-id-1',
        );
        await tester.pumpWidget(buildApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkInspectorScreen), findsOneWidget);
        final editBtn = find.byKey(const Key('benchmark_edit_button'));
        expect(editBtn, findsOneWidget);

        await tester.tap(editBtn);
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkFormScreen), findsOneWidget);
      },
    );

    testWidgets(
      'journey flow: list card tap opens inspector, then edit button pushes form, and form remains mounted',
      (tester) async {
        final router = buildRouter(initialLocation: '/operations/benchmark-db');
        await tester.pumpWidget(buildApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkListScreen), findsOneWidget);

        final recordCard = find.descendant(
          of: find.byType(FCard),
          matching: find.textContaining('BM-01'),
        );
        expect(recordCard, findsOneWidget);

        await tester.tap(recordCard);
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkInspectorScreen), findsOneWidget);

        final inspectorEditBtn = find.byKey(const Key('benchmark_edit_button'));
        expect(inspectorEditBtn, findsOneWidget);

        await tester.tap(inspectorEditBtn);
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkFormScreen), findsOneWidget);
      },
    );

    testWidgets(
      'popping pushed BenchmarkFormScreen returns cleanly to BenchmarkInspectorScreen and triggers reload',
      (tester) async {
        final router = buildRouter(
          initialLocation: '/operations/benchmark-db/test-id-1',
        );
        await tester.pumpWidget(buildApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkInspectorScreen), findsOneWidget);
        final editBtn = find.byKey(const Key('benchmark_edit_button'));
        await tester.tap(editBtn);
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkFormScreen), findsOneWidget);

        // Trigger dismiss via Escape shortcut
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsOneWidget);

        final discardButton = find.widgetWithText(
          FilledButton,
          'Discard changes',
        );
        expect(discardButton, findsOneWidget);
        await tester.tap(discardButton);
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsNothing);
        expect(find.byType(BenchmarkFormScreen), findsNothing);
        expect(find.byType(BenchmarkInspectorScreen), findsOneWidget);
        verify(
          () => mockRepository.getBenchmarkById('test-id-1'),
        ).called(greaterThan(1));
      },
    );

    testWidgets(
      'submitting BenchmarkFormScreen saves and returns cleanly to inspector',
      (tester) async {
        when(
          () => mockRepository.saveBenchmark(any()),
        ).thenAnswer((_) async {});

        final router = buildRouter(
          initialLocation: '/operations/benchmark-db/test-id-1',
        );
        await tester.pumpWidget(buildApp(router));
        await tester.pumpAndSettle();

        final editBtn = find.byKey(const Key('benchmark_edit_button'));
        await tester.tap(editBtn);
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkFormScreen), findsOneWidget);

        final saveBtn = find.widgetWithText(FButton, 'Simpan Benchmark');
        await tester.tap(saveBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkFormScreen), findsNothing);
        expect(find.byType(BenchmarkInspectorScreen), findsOneWidget);
      },
    );

    testWidgets(
      'canceling discard confirmation on dirty BenchmarkFormScreen keeps form mounted',
      (tester) async {
        final router = buildRouter(
          initialLocation: '/operations/benchmark-db/test-id-1',
        );
        await tester.pumpWidget(buildApp(router));
        await tester.pumpAndSettle();

        final editBtn = find.byKey(const Key('benchmark_edit_button'));
        await tester.tap(editBtn);
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkFormScreen), findsOneWidget);

        // Trigger dismiss via Escape shortcut (matching user interaction)
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsOneWidget);

        final continueButton = find.widgetWithText(
          TextButton,
          'Continue editing',
        );
        expect(continueButton, findsOneWidget);
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsNothing);
        expect(find.byType(BenchmarkFormScreen), findsOneWidget);
      },
    );

    testWidgets(
      'system back on dirty BenchmarkFormScreen triggers discard dialog without navigator lock assertion',
      (tester) async {
        final router = buildRouter(
          initialLocation: '/operations/benchmark-db/test-id-1',
        );
        await tester.pumpWidget(buildApp(router));
        await tester.pumpAndSettle();

        final editBtn = find.byKey(const Key('benchmark_edit_button'));
        await tester.tap(editBtn);
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkFormScreen), findsOneWidget);

        // Simulate Android/system back button
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsOneWidget);

        final continueButton = find.widgetWithText(
          TextButton,
          'Continue editing',
        );
        expect(continueButton, findsOneWidget);
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsNothing);
        expect(find.byType(BenchmarkFormScreen), findsOneWidget);
      },
    );

    testWidgets(
      'GoRouter.pop on dirty BenchmarkFormScreen triggers discard dialog without throwing navigator lock assertion',
      (tester) async {
        final router = buildRouter(
          initialLocation: '/operations/benchmark-db/test-id-1',
        );
        await tester.pumpWidget(buildApp(router));
        await tester.pumpAndSettle();

        final editBtn = find.byKey(const Key('benchmark_edit_button'));
        await tester.tap(editBtn);
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkFormScreen), findsOneWidget);

        // Call router.pop() directly (which locks navigator during pop)
        router.pop();
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsOneWidget);

        final continueButton = find.widgetWithText(
          TextButton,
          'Continue editing',
        );
        expect(continueButton, findsOneWidget);
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsNothing);
      },
    );

    testWidgets(
      'tapping close button on dirty BenchmarkFormScreen triggers discard dialog and discarding returns to inspector',
      (tester) async {
        final router = buildRouter(
          initialLocation: '/operations/benchmark-db/test-id-1',
        );
        await tester.pumpWidget(buildApp(router));
        await tester.pumpAndSettle();

        final editBtn = find.byKey(const Key('benchmark_edit_button'));
        await tester.tap(editBtn);
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkFormScreen), findsOneWidget);

        // Tap the sheet header close button (X) on the form
        final formCloseBtn = find.descendant(
          of: find.byType(BenchmarkFormScreen),
          matching: find.byIcon(Icons.close),
        );
        expect(formCloseBtn, findsOneWidget);
        await tester.tap(formCloseBtn);
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsOneWidget);

        final discardButton = find.widgetWithText(
          FilledButton,
          'Discard changes',
        );
        expect(discardButton, findsOneWidget);
        await tester.tap(discardButton);
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsNothing);
        expect(find.byType(BenchmarkFormScreen), findsNothing);
        expect(find.byType(BenchmarkInspectorScreen), findsOneWidget);
      },
    );

    testWidgets(
      'tapping close button on BenchmarkInspectorScreen dismisses sheet and returns to benchmark list',
      (tester) async {
        final router = buildRouter(initialLocation: '/operations/benchmark-db');
        await tester.pumpWidget(buildApp(router));
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkListScreen), findsOneWidget);

        final recordCard = find.descendant(
          of: find.byType(FCard),
          matching: find.textContaining('BM-01'),
        );
        await tester.tap(recordCard);
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkInspectorScreen), findsOneWidget);

        final inspectorCloseBtn = find.descendant(
          of: find.byType(BenchmarkInspectorScreen),
          matching: find.byIcon(Icons.close),
        );
        expect(inspectorCloseBtn, findsOneWidget);
        await tester.tap(inspectorCloseBtn);
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkInspectorScreen), findsNothing);
        expect(find.byType(BenchmarkListScreen), findsOneWidget);
      },
    );

    testWidgets(
      'tapping modal barrier on clean BenchmarkInspectorScreen dismisses sheet and returns to benchmark list',
      (tester) async {
        final router = buildRouter(initialLocation: '/operations/benchmark-db');
        await tester.pumpWidget(buildApp(router));
        await tester.pumpAndSettle();

        final recordCard = find.descendant(
          of: find.byType(FCard),
          matching: find.textContaining('BM-01'),
        );
        await tester.tap(recordCard);
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkInspectorScreen), findsOneWidget);

        // Tap the barrier to the left of the sheet panel (panel starts at x=320)
        await tester.tapAt(const Offset(100, 300));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pumpAndSettle();

        expect(find.byType(BenchmarkInspectorScreen), findsNothing);
        expect(find.byType(BenchmarkListScreen), findsOneWidget);
      },
    );
  });
}
