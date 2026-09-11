// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'mine-flow';

  @override
  String get localizationBaseline => 'STEP-41 Localization Baseline';

  @override
  String get reportTypePickerTitle => 'Choose Report Type';

  @override
  String get fileDetailNotFound => 'File not found.';

  @override
  String get sheetClose => 'Close';

  @override
  String get sheetBarrierLabel => 'Close sheet';

  @override
  String get processInProgress => 'A process is still running';

  @override
  String get unsavedChangesTitle => 'Unsaved changes';

  @override
  String get unsavedChangesBody => 'Unsaved changes will be lost.';

  @override
  String get continueEditing => 'Continue editing';

  @override
  String get discardChanges => 'Discard changes';

  @override
  String statusLabel(String value) {
    return 'Status: $value';
  }

  @override
  String get filterLabel => 'Filter';

  @override
  String get cancel => 'Cancel';

  @override
  String get resetFilters => 'Reset filters';

  @override
  String get apply => 'Apply';

  @override
  String get chooseDateRange => 'Choose date range';

  @override
  String get chooseDate => 'Choose date';

  @override
  String get interactionFixtureTitle => 'Interaction fixture';

  @override
  String get interactionFixtureList => 'Preserved list fixture';

  @override
  String get interactionFixtureSheet => 'Route-backed sheet fixture';
}
