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
  String get fileDetailNotFound => 'File not found.';

  @override
  String get sheetClose => 'Close';

  @override
  String get sheetBarrierLabel => 'Close sheet';

  @override
  String get sheetDragHandle => 'Drag down to close';

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

  @override
  String get attendanceFormTitle => 'Crew Attendance Input';

  @override
  String get attendanceHeaderSemantics => 'Attendance header';

  @override
  String get attendanceEmptyRosterTitle => 'No crew registered yet';

  @override
  String get attendanceEmptyRosterBody =>
      'The crew list for this site will load from registered user data.';

  @override
  String get attendanceBulkMarkPresent => 'Mark All Present';

  @override
  String get attendanceDiscardReasonTitle => 'Remove reason?';

  @override
  String attendanceDiscardReasonBody(String reason) {
    return 'Changing the status to one without a reason will remove the typed reason \"$reason\". Continue?';
  }

  @override
  String get attendanceDiscardReasonConfirm => 'Remove reason';

  @override
  String get attendanceSaving => 'Saving Attendance...';

  @override
  String attendanceSaveCount(int count) {
    return 'Save Attendance ($count Crew)';
  }

  @override
  String get attendanceStatusLeave => 'Leave';

  @override
  String get attendanceStatusSick => 'Sick';

  @override
  String get attendanceStatusAbsent => 'Absent';

  @override
  String get attendanceStatusPresent => 'Present';

  @override
  String get attendanceStatusUnset => 'not chosen';

  @override
  String get attendanceReasonSickLabel => 'Sick reason';

  @override
  String get attendanceReasonLeaveLabel => 'Leave reason';

  @override
  String attendanceReasonRequiredLabel(String label) {
    return '$label (required)';
  }

  @override
  String attendanceReasonHint(String label) {
    return 'Enter $label';
  }

  @override
  String get attendanceReasonClearTooltip => 'Remove reason';

  @override
  String attendanceStatusChooseLabel(String label) {
    return 'Choose $label status for this crew member';
  }

  @override
  String attendanceCrewStatusLabel(String name, String status) {
    return 'Crew $name — Status: $status';
  }

  @override
  String get attendanceSyncQueued => 'Waiting to sync';

  @override
  String get attendanceSyncSyncing => 'Syncing...';

  @override
  String get attendanceSyncFailed => 'Sync failed';

  @override
  String get attendanceSyncSynced => 'Synced';

  @override
  String get attendanceSyncRetry => 'Retry';

  @override
  String attendanceSyncStatusLabel(String label) {
    return 'Sync status: $label';
  }

  @override
  String get attendanceSyncRetryLabel => 'Retry sync';

  @override
  String get dailyLogOperationalDate => 'Operational Date';

  @override
  String get dailyLogSummaryLabel => 'Work Summary *';

  @override
  String get dailyLogNotesLabel => 'Additional Notes & Safety (K3)';

  @override
  String get dailyLogZoneLabel => 'Operational Zone';

  @override
  String get dailyLogWeatherLabel => 'Weather Conditions';

  @override
  String get dailyLogHazardLabel => 'Hazard Assessment (K3)';

  @override
  String get dailyLogHazardRequiredLabel => 'Hazard Assessment (K3) *';

  @override
  String get dailyLogHazardSeverityLabel => 'Severity Level *';

  @override
  String get dailyLogHazardActionLabel => 'Corrective Action';

  @override
  String get dailyLogHazardNotesHint => 'Describe the identified hazard...';

  @override
  String get dailyLogHazardActionHint =>
      'Corrective action taken or planned...';

  @override
  String get dailyLogHazardNone => 'No Hazard';

  @override
  String get dailyLogHazardPresent => 'Hazard Present';

  @override
  String get dailyLogHazardNotesLabel => 'Hazard Notes';

  @override
  String get dailyLogHazardSeverityLow => 'Low';

  @override
  String get dailyLogHazardSeverityMedium => 'Medium';

  @override
  String get dailyLogHazardSeverityHigh => 'High';

  @override
  String get dailyLogHazardSeverityCritical => 'Critical';

  @override
  String get equipmentCheckDeleteRecord => 'Delete Record';

  @override
  String equipmentCheckSerialNumber(String serial) {
    return 'S/N: $serial';
  }

  @override
  String equipmentCheckInspector(String name) {
    return 'Inspector: $name';
  }

  @override
  String equipmentCheckSite(String site) {
    return 'Site: $site';
  }

  @override
  String get equipmentCheckResultHeader => 'SOP CHECKLIST RESULTS';

  @override
  String equipmentCheckResultSummary(int passed, int failed, int total) {
    return '$passed Passed • $failed Failed / $total Items';
  }

  @override
  String get equipmentCheckAdditionalRemarks => 'ADDITIONAL INSPECTION REMARKS';

  @override
  String get equipmentCheckDetailTitle => 'Equipment Inspection Details';

  @override
  String get equipmentCheckAccessDeniedTitle => 'Access Denied';

  @override
  String get equipmentCheckAccessDeniedMessage =>
      'Invalid work site or you do not have access.';

  @override
  String get equipmentCheckBack => 'Back';

  @override
  String get equipmentCheckInvalidRecord => 'Invalid inspection record.';

  @override
  String get equipmentCheckDeleteConfirmMessage =>
      'Are you sure you want to delete this equipment inspection record?';

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileDetail => 'Profile Details';

  @override
  String get profileDisplayName => 'Display Name';

  @override
  String get profileRoleManaged => 'Role (system managed)';

  @override
  String get profileSave => 'Save';

  @override
  String get dataBucketBack => 'Back';

  @override
  String get inventoryChangeData => 'Change Data';

  @override
  String get inventoryStockAdjustment => 'Stock Adjustment';

  @override
  String get inventoryDeleteItem => 'Delete Item';

  @override
  String get inventoryCurrentStock => 'Current Stock';

  @override
  String get inventoryAdjustmentHistory => 'Adjustment History';

  @override
  String get inventoryNoTransactionHistory => 'No transaction history yet.';

  @override
  String get privacyTitle => 'Privacy & Terms';

  @override
  String get privacyLogout => 'Log out';

  @override
  String get privacyCardTitle => 'Internal Privacy Notice';

  @override
  String get privacyCardSubtitle =>
      'Please review and acknowledge our data usage policy.';

  @override
  String get privacyCardBody =>
      'This application collects personal data related to your work operations and safety, including Name, Contact, National ID, and operational activity logs. This data is processed based on Employment Contracts and Legitimate Business Interests. Operational data is retained indefinitely, and employee identity data is retained for 7 years post-employment before being permanently deleted. By continuing, you agree to the processing of this data.';

  @override
  String get privacyAckButton => 'Agree & Continue';

  @override
  String get crsProjectionFailure =>
      'Projection failed: coordinates out-of-bounds or zone mismatch. Ensure CRS/Datum matches Easting/Northing.';

  @override
  String get error => 'Error';
}
