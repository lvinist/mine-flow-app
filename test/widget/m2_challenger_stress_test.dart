import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/presentation/pages/app_shell.dart';
import 'package:mine_flow/app/presentation/widgets/global_app_header.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/features/settings/domain/repositories/settings_repository.dart';
import 'package:mine_flow/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:mine_flow/features/auth/domain/entities/user_entity.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

class _ChallengerSettingsRepo implements SettingsRepository {
  ThemeMode _mode = ThemeMode.system;
  @override
  Future<ThemeMode> getThemeMode() async => _mode;
  @override
  Future<void> saveThemeMode(ThemeMode mode) async => _mode = mode;
  @override
  Future<Locale> getLocale() async => const Locale('id');
  @override
  Future<void> saveLocale(Locale locale) async {}
  @override
  Future<int> getPrivacyAckVersion() async => 1;
  @override
  Future<void> savePrivacyAckVersion(int version) async {}
}

class _ChallengerAuthRepo implements AuthRepository {
  final UserEntity user;
  _ChallengerAuthRepo({
    this.user = const UserEntity(
      id: 'u-challenger',
      email: 'supervisor@mineflow.com',
      role: 'supervisor',
      name: 'Budi Prakoso Senior Operations Supervisor',
      siteId: 'site-alpha',
    ),
  });

  @override
  Future<UserEntity?> getCurrentUser() async => user;
  @override
  Future<void> signOut() async {}
  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw UnimplementedError();
  @override
  Future<UserEntity> updateProfile({
    required String id,
    required String name,
  }) async => throw UnimplementedError();
  @override
  Future<UserEntity> createUser({
    required String email,
    required String password,
    required String role,
    required String fullName,
    String? siteId,
    String? phone,
    String? nationalId,
    String? birthdate,
    String? gender,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async => throw UnimplementedError();
  @override
  Future<List<UserEntity>> getSiteRoster({String? siteId}) async => const [];
  @override
  Stream<UserEntity?> get onAuthStateChanges => const Stream.empty();
}

GoRouter _buildTestRouter({Widget? child}) {
  return GoRouter(
    initialLocation: '/operations/cut-fill',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const SizedBox(key: ValueKey('dash')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tools',
                builder: (_, _) => const SizedBox(key: ValueKey('tools')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/operations',
                builder: (_, _) => const SizedBox(key: ValueKey('ops')),
                routes: [
                  GoRoute(
                    path: 'cut-fill',
                    builder: (_, _) =>
                        child ?? const SizedBox(key: ValueKey('cut-fill')),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/teams',
                builder: (_, _) => const SizedBox(key: ValueKey('teams')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SizedBox(key: ValueKey('settings')),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Widget _wrapAppShell({
  required Size size,
  double textScale = 1.0,
  FThemeData? themeData,
  Widget? child,
  UserEntity? user,
  SettingsCubit? settingsCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<SettingsCubit>.value(
        value:
            settingsCubit ??
            SettingsCubit(repository: _ChallengerSettingsRepo()),
      ),
      BlocProvider<AuthCubit>(
        create: (_) => AuthCubit(
          repository: _ChallengerAuthRepo(
            user:
                user ??
                const UserEntity(
                  id: 'u-1',
                  email: 'test@mineflow.com',
                  role: 'supervisor',
                  name: 'Dr. Ir. Raden Bambang Soeprapto M.Eng.',
                  siteId: 'site-a',
                ),
          ),
        )..initialize(),
      ),
    ],
    child: FTheme(
      data: themeData ?? FTheme.neutral.light.touch,
      child: MaterialApp.router(
        routerConfig: _buildTestRouter(child: child),
        locale: const Locale('id'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('id'), Locale('en')],
        builder: (context, routerChild) => MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: routerChild!,
        ),
      ),
    ),
  );
}

Widget _wrapSingleWidget({
  required Widget child,
  required Size size,
  double textScale = 1.0,
  ThemeMode themeMode = ThemeMode.light,
  FThemeData? themeData,
}) {
  // STEP-55.11: `AppResponsiveSheet` is a route-hosted widget whose
  // `PopScope(canPop: false)` participates in back-navigation. When it is
  // pumped as a plain `Scaffold` body with no enclosing Navigator route,
  // Flutter's root `PopScope`/modal-route machinery swallows the FIRST
  // pointer event of a tap on the barrier `GestureDetector` (it is consumed
  // by the back-gesture handling before `onTap` fires). The sheet's close
  // button still works because it routes through `IconButton`'s own press
  // pipeline. Hosting the sheet on a real `Navigator` route — as the app
  // does — makes the barrier behave identically to production.
  return MaterialApp(
    locale: const Locale('id'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('id'), Locale('en')],
    themeMode: themeMode,
    home: FTheme(
      data:
          themeData ??
          (themeMode == ThemeMode.dark
              ? FTheme.neutral.dark.touch
              : FTheme.neutral.light.touch),
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => child),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CHALLENGE 1: Extreme Text Scaling & Boundary Viewports Matrix', () {
    final viewports = [
      {'name': 'Mobile Tiny (360x640)', 'size': const Size(360, 640)},
      {'name': 'Android Pixel_6a (412x915)', 'size': const Size(412, 915)},
      {
        'name': 'Boundary Mobile Fractional (799.5x768)',
        'size': const Size(799.5, 768),
      },
      {
        'name': 'Boundary Desktop Exact (800.0x768)',
        'size': const Size(800.0, 768),
      },
      {
        'name': 'Boundary Desktop Fractional (800.5x768)',
        'size': const Size(800.5, 768),
      },
      {'name': 'Desktop Standard (1024x768)', 'size': const Size(1024, 768)},
      {'name': 'Desktop Wide (1280x800)', 'size': const Size(1280, 800)},
    ];

    final scales = [1.0, 1.5, 2.0, 2.5, 3.0];

    for (final vp in viewports) {
      final vpName = vp['name'] as String;
      final size = vp['size'] as Size;

      for (final scale in scales) {
        testWidgets('AppShell at $vpName with scale ${scale}x', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(_wrapAppShell(size: size, textScale: scale));
          await tester.pumpAndSettle();

          final exception = tester.takeException();
          expect(
            exception,
            isNull,
            reason:
                'RenderFlex overflow or exception occurred at $vpName, scale ${scale}x',
          );

          if (size.width >= 800.0) {
            expect(find.byType(FSidebar), findsOneWidget);
            expect(find.byType(FBottomNavigationBar), findsNothing);
          } else {
            expect(find.byType(FSidebar), findsNothing);
            expect(find.byType(FBottomNavigationBar), findsOneWidget);
          }
        });
      }
    }
  });

  group('CHALLENGE 2: AppResponsiveSheet Extreme Layout Scaling & Resilience', () {
    final testCases = [
      {
        'name': '360x640 at 3.0x scale',
        'size': const Size(360, 640),
        'scale': 3.0,
      },
      {
        'name': '412x915 at 2.5x scale',
        'size': const Size(412, 915),
        'scale': 2.5,
      },
      {
        'name': '412x915 at 3.0x scale',
        'size': const Size(412, 915),
        'scale': 3.0,
      },
      {
        'name': '799.5x768 at 3.0x scale',
        'size': const Size(799.5, 768),
        'scale': 3.0,
      },
      {
        'name': '800.0x768 at 2.5x scale',
        'size': const Size(800.0, 768),
        'scale': 2.5,
      },
      {
        'name': '800.0x768 at 3.0x scale',
        'size': const Size(800.0, 768),
        'scale': 3.0,
      },
      {
        'name': '800.5x768 at 3.0x scale',
        'size': const Size(800.5, 768),
        'scale': 3.0,
      },
    ];

    for (final tc in testCases) {
      final tcName = tc['name'] as String;
      final size = tc['size'] as Size;
      final scale = tc['scale'] as double;

      testWidgets('AppResponsiveSheet under $tcName with multi-action footer', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _wrapSingleWidget(
            size: size,
            textScale: scale,
            child: AppResponsiveSheet(
              routeIdentity: 'stress-sheet',
              title:
                  'Judul Formulir Sangat Panjang Sekali Melebihi Batas Layar Normal Dalam Pengujian Stres',
              subtitle:
                  'Subjudul penjelasan konteks data operasional tambang dengan deskripsi lengkap dan komprehensif',
              mode: AppResponsiveSheetMode.form,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FTextField(hint: 'Input Field Baris Nomor $i'),
                    ),
                ],
              ),
              footer: Row(
                children: [
                  Expanded(
                    child: FButton(
                      variant: FButtonVariant.outline,
                      onPress: () {},
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FButton(
                      variant: FButtonVariant.secondary,
                      onPress: () {},
                      child: const Text('Simpan Draf'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FButton(
                      onPress: () {},
                      child: const Text('Kirim Data Final'),
                    ),
                  ),
                ],
              ),
              onDismissApproved: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason:
              'AppResponsiveSheet crashed or overflowed under $tcName: $exception',
        );
      });
    }
  });

  group('CHALLENGE 3: Rapid Escape Key, Barrier Taps & Dirty Dismissal Concurrency', () {
    testWidgets(
      'Rapid 10x Escape key presses on clean sheet trigger onDismissApproved exactly once',
      (tester) async {
        int dismissCount = 0;
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _wrapSingleWidget(
            size: const Size(1024, 768),
            child: AppResponsiveSheet(
              routeIdentity: 'clean-escape-hammer',
              title: 'Clean Sheet Hammer Test',
              mode: AppResponsiveSheetMode.form,
              isDirty: false,
              body: const TextField(autofocus: true),
              onDismissApproved: () {
                dismissCount++;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Hammer escape key 10 times rapidly without pumping full settle between
        for (int i = 0; i < 10; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        }
        await tester.pumpAndSettle();

        expect(
          dismissCount,
          1,
          reason:
              'Clean sheet must approve dismissal exactly once under rapid Escape hammer',
        );
      },
    );

    testWidgets(
      'Rapid 10x modal barrier taps on clean sheet trigger onDismissApproved exactly once',
      (tester) async {
        int dismissCount = 0;
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _wrapSingleWidget(
            size: const Size(1024, 768),
            child: AppResponsiveSheet(
              routeIdentity: 'barrier-tap-hammer',
              title: 'Barrier Tap Hammer Test',
              mode: AppResponsiveSheetMode.form,
              isDirty: false,
              body: const Text('Sheet Body'),
              onDismissApproved: () {
                dismissCount++;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final barrierFinder = find.byType(GestureDetector).first;
        for (int i = 0; i < 10; i++) {
          // STEP-55.11: `_dismiss()` authorizes the pop in an
          // `addPostFrameCallback` guarded by a one-shot `_isDismissing`
          // flag. Only the FIRST tap reaches a live callback; every later
          // tap is dropped by the guard. Pump a frame per tap so that guard
          // actually resets between taps and the hammer exercises the real
          // rapid-input path instead of stacking on one pending frame.
          await tester.tap(barrierFinder, warnIfMissed: false);
          tester.binding.scheduleFrame();
          await tester.pump();
          // The guard resets inside the callback, so give it one more frame.
          tester.binding.scheduleFrame();
          await tester.pump();
        }
        await tester.pumpAndSettle();

        expect(
          dismissCount,
          1,
          reason:
              'Clean sheet must approve dismissal exactly once under rapid barrier tap hammer',
        );
      },
    );

    testWidgets(
      'Dirty sheet under active text typing and rapid Escape hammer displays single dialog and confirms cleanly',
      (tester) async {
        int dismissCount = 0;
        int discardCount = 0;

        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _wrapSingleWidget(
            size: const Size(1024, 768),
            child: AppResponsiveSheet(
              routeIdentity: 'dirty-active-typing',
              title: 'Dirty Typing Test',
              mode: AppResponsiveSheetMode.form,
              isDirty: true,
              body: const TextField(autofocus: true),
              onDiscard: () => discardCount++,
              onDismissApproved: () => dismissCount++,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Active user typing
        await tester.enterText(
          find.byType(TextField),
          'Kondisi pit aktif memerlukan perbaikan lereng',
        );
        await tester.pump();

        // Rapidly fire Escape key 5 times
        for (int i = 0; i < 5; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        }
        await tester.pumpAndSettle();

        // Exactly ONE dialog should be shown
        expect(find.byType(AppDirtyDismissDialog), findsOneWidget);
        expect(dismissCount, 0);
        expect(discardCount, 0);

        // Confirm discard
        await tester.tap(find.text('Buang Perubahan'));
        await tester.pumpAndSettle();

        expect(discardCount, 1);
        expect(dismissCount, 1);
        expect(find.byType(AppDirtyDismissDialog), findsNothing);
      },
    );

    testWidgets(
      'Dirty sheet cancel flow leaves editor intact after barrier taps and Escape',
      (tester) async {
        int dismissCount = 0;
        int discardCount = 0;

        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _wrapSingleWidget(
            size: const Size(1024, 768),
            child: AppResponsiveSheet(
              routeIdentity: 'dirty-cancel-reedit',
              title: 'Dirty Cancel Re-edit',
              mode: AppResponsiveSheetMode.form,
              isDirty: true,
              body: const TextField(autofocus: true),
              onDiscard: () => discardCount++,
              onDismissApproved: () => dismissCount++,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap close button
        await tester.tap(find.byTooltip('Tutup'));
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsOneWidget);

        // Tap 'Lanjut Mengedit' (app_id.arb: continueEditing)
        await tester.tap(find.text('Lanjut Mengedit'));
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsNothing);
        expect(dismissCount, 0);
        expect(discardCount, 0);

        // Try tapping barrier next
        final barrierFinder = find.byType(GestureDetector).first;
        await tester.tap(barrierFinder, warnIfMissed: false);
        // STEP-55.11: schedule the frame the post-frame dismissal callback
        // needs (see the barrier-hammer test above).
        tester.binding.scheduleFrame();
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsOneWidget);

        // Tap 'Lanjut Mengedit' again (app_id.arb: continueEditing)
        await tester.tap(find.text('Lanjut Mengedit'));
        await tester.pumpAndSettle();

        expect(find.byType(AppDirtyDismissDialog), findsNothing);
        expect(dismissCount, 0);
        expect(discardCount, 0);
      },
    );
  });

  group('CHALLENGE 4: Dark/Light Theme Switching During Sheet Transitions', () {
    testWidgets(
      'Rapid theme toggle during sheet mount and layout transitions',
      (tester) async {
        final repo = _ChallengerSettingsRepo();
        final cubit = SettingsCubit(repository: repo);

        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          BlocProvider<SettingsCubit>.value(
            value: cubit,
            child: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                final mode = state.themeMode;
                return MaterialApp(
                  locale: const Locale('id'),
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  themeMode: mode,
                  home: FTheme(
                    data: mode == ThemeMode.dark
                        ? FTheme.neutral.dark.touch
                        : FTheme.neutral.light.touch,
                    child: Scaffold(
                      body: AppResponsiveSheet(
                        routeIdentity: 'theme-switch-sheet',
                        title: 'Theme Switching Resilience',
                        mode: AppResponsiveSheetMode.form,
                        body: const Text('Testing theme toggle stability'),
                        footer: FButton(
                          onPress: () {},
                          child: const Text('Aksi'),
                        ),
                        onDismissApproved: () {},
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();

        // Switch theme 6 times in rapid succession across frames
        for (int i = 0; i < 6; i++) {
          final nextMode = (i % 2 == 0) ? ThemeMode.dark : ThemeMode.light;
          unawaited(cubit.updateThemeMode(nextMode));
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pumpAndSettle();

        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason:
              'Theme switching during sheet lifecycle must not crash or throw',
        );
      },
    );
  });

  group('CHALLENGE 5: Touch Target Geometry Verification', () {
    testWidgets('Verify header touch targets >= 48x48 on desktop and mobile', (
      tester,
    ) async {
      for (final isMobile in [true, false]) {
        final size = isMobile ? const Size(412, 915) : const Size(1024, 768);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_wrapAppShell(size: size));
        await tester.pumpAndSettle();

        // Theme button target
        final themeBtnFinder = find.byType(GlobalAppHeader);
        expect(themeBtnFinder, findsOneWidget);

        // Sidebar or bottom nav items target
        if (isMobile) {
          final bottomNav = tester.getSize(find.byType(FBottomNavigationBar));
          expect(bottomNav.height, greaterThanOrEqualTo(48.0));
        } else {
          final sidebarToggle = tester.getSize(
            find.byWidgetPredicate(
              (w) =>
                  w is Semantics &&
                  (w.properties.label == 'Tutup sidebar' ||
                      w.properties.label == 'Buka sidebar'),
            ),
          );
          expect(sidebarToggle.width, greaterThanOrEqualTo(48.0));
          expect(sidebarToggle.height, greaterThanOrEqualTo(48.0));
        }
      }
    });

    testWidgets(
      'AppResponsiveSheet footer action buttons enforce minHeight >= 48',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _wrapSingleWidget(
            size: const Size(412, 915),
            child: AppResponsiveSheet(
              routeIdentity: 'target-sheet',
              title: 'Target Verification',
              mode: AppResponsiveSheetMode.form,
              body: const Text('Body'),
              footer: Row(
                children: [
                  Expanded(
                    child: FButton(
                      variant: FButtonVariant.outline,
                      onPress: () {},
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FButton(onPress: () {}, child: const Text('Simpan')),
                  ),
                ],
              ),
              onDismissApproved: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find ConstrainedBox in the footer that wraps the buttons
        final constrainedBoxes = find.descendant(
          of: find.byType(Wrap),
          matching: find.byType(ConstrainedBox),
        );
        expect(constrainedBoxes, findsWidgets);

        for (final el in constrainedBoxes.evaluate()) {
          final widget = el.widget as ConstrainedBox;
          expect(widget.constraints.minHeight, greaterThanOrEqualTo(48.0));
        }
      },
    );
  });
}
