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

  @override
  String get cutFillNotFound => 'Cut/fill measurement not found.';

  @override
  String get backToList => 'Back to list';

  @override
  String get newMeasurement => 'New Measurement';

  @override
  String get editMeasurement => 'Edit Measurement';

  @override
  String get saveMeasurement => 'Save Measurement';

  @override
  String get saving => 'Saving...';

  @override
  String get measurementSaved => 'Cut/fill data saved successfully!';

  @override
  String contextualReportTitle(String sourceTitle) {
    return 'Report: $sourceTitle';
  }

  @override
  String get operationalZoneOptional => 'Operational Zone (Optional)';

  @override
  String get generateReport => 'Generate Report';

  @override
  String get sharePdf => 'Share PDF';

  @override
  String get printReport => 'Print';

  @override
  String get regenerateReport => 'Regenerate';

  @override
  String get dataNotFound => 'Data Not Found';

  @override
  String get cutFillTitle => 'Cut / Fill Volume';

  @override
  String get selectZoneValidation => 'Select a zone first.';

  @override
  String get selectMaterialValidation => 'Select a material first.';

  @override
  String get volumeValidation => 'Fill in at least one volume (BCM or LCM).';
}
