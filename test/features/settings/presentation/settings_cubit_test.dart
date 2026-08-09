/// Unit tests for [SettingsCubit].
///
/// Uses mocktail to mock the [SettingsRepository] boundary and bloc_test to
/// verify state transitions for theme and locale changes.
///
/// Note: SettingsCubit._load() is async and called (unawaited) in the
/// constructor.  Build-only blocTests handle this well because blocTest
/// drains microtasks after build.  For mutation tests we use plain `test`
/// with manual state checks to avoid race conditions with the load
/// emission.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mine_flow/features/settings/domain/repositories/settings_repository.dart';
import 'package:mine_flow/features/settings/presentation/bloc/settings_cubit.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

/// Helper to match a [SettingsState] by its properties (since the class does
/// not use Equatable — we rely on matchers instead of == equality).
Matcher _settingsState({
  required ThemeMode themeMode,
  required String localeCode,
}) => isA<SettingsState>()
    .having((s) => s.themeMode, 'themeMode', themeMode)
    .having((s) => s.locale.languageCode, 'locale.languageCode', localeCode);

void main() {
  late MockSettingsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const Locale('en'));
    registerFallbackValue(ThemeMode.system);
  });

  setUp(() {
    mockRepository = MockSettingsRepository();

    when(
      () => mockRepository.getThemeMode(),
    ).thenAnswer((_) async => ThemeMode.system);
    when(
      () => mockRepository.getLocale(),
    ).thenAnswer((_) async => const Locale('en'));
    when(() => mockRepository.saveThemeMode(any())).thenAnswer((_) async {});
    when(() => mockRepository.saveLocale(any())).thenAnswer((_) async {});
  });

  group('SettingsCubit', () {
    // ------------------------------------------------------------------
    // Build-time load behaviour
    // ------------------------------------------------------------------

    blocTest<SettingsCubit, SettingsState>(
      'initial state has defaults when nothing is saved',
      build: () => SettingsCubit(repository: mockRepository),
      expect: () => [
        _settingsState(themeMode: ThemeMode.system, localeCode: 'en'),
      ],
      verify: (_) {
        verify(() => mockRepository.getThemeMode()).called(1);
        verify(() => mockRepository.getLocale()).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'loads saved preferences on creation',
      build: () {
        when(
          () => mockRepository.getThemeMode(),
        ).thenAnswer((_) async => ThemeMode.dark);
        when(
          () => mockRepository.getLocale(),
        ).thenAnswer((_) async => const Locale('id'));
        return SettingsCubit(repository: mockRepository);
      },
      expect: () => [
        _settingsState(themeMode: ThemeMode.dark, localeCode: 'id'),
      ],
    );

    // ------------------------------------------------------------------
    // Mutation behaviour — plain test blocks to avoid _load() race
    // with act-phase emissions inside blocTest.
    // ------------------------------------------------------------------

    test('updateThemeMode saves to repository and changes state', () async {
      final cubit = SettingsCubit(repository: mockRepository);
      // Wait for async _load() to settle
      await Future<void>.delayed(Duration.zero);

      await cubit.updateThemeMode(ThemeMode.dark);

      verify(() => mockRepository.saveThemeMode(ThemeMode.dark)).called(1);
      expect(cubit.state.themeMode, ThemeMode.dark);
      expect(cubit.state.settings.themeMode, ThemeMode.dark);
      await cubit.close();
    });

    test('updateLocale saves to repository and changes state', () async {
      final cubit = SettingsCubit(repository: mockRepository);
      await Future<void>.delayed(Duration.zero);

      await cubit.updateLocale(const Locale('id'));

      verify(() => mockRepository.saveLocale(const Locale('id'))).called(1);
      expect(cubit.state.locale.languageCode, 'id');
      expect(cubit.state.settings.locale.languageCode, 'id');
      await cubit.close();
    });

    test('toggle theme then locale works independently', () async {
      final cubit = SettingsCubit(repository: mockRepository);
      await Future<void>.delayed(Duration.zero);

      await cubit.updateThemeMode(ThemeMode.light);
      await cubit.updateLocale(const Locale('id'));

      verify(() => mockRepository.saveThemeMode(ThemeMode.light)).called(1);
      verify(() => mockRepository.saveLocale(const Locale('id'))).called(1);
      expect(cubit.state.themeMode, ThemeMode.light);
      expect(cubit.state.locale.languageCode, 'id');
      await cubit.close();
    });
  });
}
