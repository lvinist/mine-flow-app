import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// The name of the application.
  ///
  /// In id, this message translates to:
  /// **'mine-flow'**
  String get appTitle;

  /// A sentinel string used by the STEP-41 localization baseline guard. Not displayed to users.
  ///
  /// In id, this message translates to:
  /// **'Dasar Lokalisasi STEP-41'**
  String get localizationBaseline;

  /// Header of the report-type picker landing page (CF-030).
  ///
  /// In id, this message translates to:
  /// **'Pilih Jenis Laporan'**
  String get reportTypePickerTitle;

  /// Empty-state message when a data-bucket file id resolves to nothing (CF-031).
  ///
  /// In id, this message translates to:
  /// **'File tidak ditemukan.'**
  String get fileDetailNotFound;

  /// No description provided for @sheetClose.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get sheetClose;

  /// No description provided for @sheetBarrierLabel.
  ///
  /// In id, this message translates to:
  /// **'Tutup lembar'**
  String get sheetBarrierLabel;

  /// No description provided for @processInProgress.
  ///
  /// In id, this message translates to:
  /// **'Proses masih berjalan'**
  String get processInProgress;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In id, this message translates to:
  /// **'Perubahan belum disimpan'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesBody.
  ///
  /// In id, this message translates to:
  /// **'Perubahan yang belum disimpan akan hilang.'**
  String get unsavedChangesBody;

  /// No description provided for @continueEditing.
  ///
  /// In id, this message translates to:
  /// **'Lanjut Mengedit'**
  String get continueEditing;

  /// No description provided for @discardChanges.
  ///
  /// In id, this message translates to:
  /// **'Buang Perubahan'**
  String get discardChanges;

  /// No description provided for @statusLabel.
  ///
  /// In id, this message translates to:
  /// **'Status: {value}'**
  String statusLabel(String value);

  /// No description provided for @filterLabel.
  ///
  /// In id, this message translates to:
  /// **'Filter'**
  String get filterLabel;

  /// No description provided for @cancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancel;

  /// No description provided for @resetFilters.
  ///
  /// In id, this message translates to:
  /// **'Reset filter'**
  String get resetFilters;

  /// No description provided for @apply.
  ///
  /// In id, this message translates to:
  /// **'Terapkan'**
  String get apply;

  /// No description provided for @chooseDateRange.
  ///
  /// In id, this message translates to:
  /// **'Pilih rentang tanggal'**
  String get chooseDateRange;

  /// No description provided for @chooseDate.
  ///
  /// In id, this message translates to:
  /// **'Pilih tanggal'**
  String get chooseDate;

  /// No description provided for @interactionFixtureTitle.
  ///
  /// In id, this message translates to:
  /// **'Contoh interaksi'**
  String get interactionFixtureTitle;

  /// No description provided for @interactionFixtureList.
  ///
  /// In id, this message translates to:
  /// **'Contoh daftar tersimpan'**
  String get interactionFixtureList;

  /// No description provided for @interactionFixtureSheet.
  ///
  /// In id, this message translates to:
  /// **'Contoh lembar berbasis rute'**
  String get interactionFixtureSheet;

  /// No description provided for @cutFillNotFound.
  ///
  /// In id, this message translates to:
  /// **'Pengukuran cut/fill tidak ditemukan.'**
  String get cutFillNotFound;

  /// No description provided for @backToList.
  ///
  /// In id, this message translates to:
  /// **'Kembali ke daftar'**
  String get backToList;

  /// No description provided for @newMeasurement.
  ///
  /// In id, this message translates to:
  /// **'Pengukuran Baru'**
  String get newMeasurement;

  /// No description provided for @editMeasurement.
  ///
  /// In id, this message translates to:
  /// **'Edit Pengukuran'**
  String get editMeasurement;

  /// No description provided for @saveMeasurement.
  ///
  /// In id, this message translates to:
  /// **'Simpan Pengukuran'**
  String get saveMeasurement;

  /// No description provided for @saving.
  ///
  /// In id, this message translates to:
  /// **'Menyimpan...'**
  String get saving;

  /// No description provided for @measurementSaved.
  ///
  /// In id, this message translates to:
  /// **'Data cut/fill berhasil disimpan!'**
  String get measurementSaved;

  /// No description provided for @contextualReportTitle.
  ///
  /// In id, this message translates to:
  /// **'Laporan: {sourceTitle}'**
  String contextualReportTitle(String sourceTitle);

  /// No description provided for @operationalZoneOptional.
  ///
  /// In id, this message translates to:
  /// **'Zona Operasional (Opsional)'**
  String get operationalZoneOptional;

  /// No description provided for @generateReport.
  ///
  /// In id, this message translates to:
  /// **'Buat Laporan'**
  String get generateReport;

  /// No description provided for @sharePdf.
  ///
  /// In id, this message translates to:
  /// **'Bagikan PDF'**
  String get sharePdf;

  /// No description provided for @printReport.
  ///
  /// In id, this message translates to:
  /// **'Cetak'**
  String get printReport;

  /// No description provided for @regenerateReport.
  ///
  /// In id, this message translates to:
  /// **'Buat Ulang'**
  String get regenerateReport;

  /// No description provided for @dataNotFound.
  ///
  /// In id, this message translates to:
  /// **'Data Tidak Ditemukan'**
  String get dataNotFound;

  /// No description provided for @cutFillTitle.
  ///
  /// In id, this message translates to:
  /// **'Volume Cut / Fill'**
  String get cutFillTitle;

  /// No description provided for @selectZoneValidation.
  ///
  /// In id, this message translates to:
  /// **'Pilih zona terlebih dahulu.'**
  String get selectZoneValidation;

  /// No description provided for @selectMaterialValidation.
  ///
  /// In id, this message translates to:
  /// **'Pilih material terlebih dahulu.'**
  String get selectMaterialValidation;

  /// No description provided for @volumeValidation.
  ///
  /// In id, this message translates to:
  /// **'Isi minimal salah satu volume (BCM atau LCM).'**
  String get volumeValidation;

  /// Header title of the batch crew attendance sheet (STEP-55.5).
  ///
  /// In id, this message translates to:
  /// **'Input Absensi Kru'**
  String get attendanceFormTitle;

  /// No description provided for @attendanceHeaderSemantics.
  ///
  /// In id, this message translates to:
  /// **'Header absensi'**
  String get attendanceHeaderSemantics;

  /// No description provided for @attendanceEmptyRosterTitle.
  ///
  /// In id, this message translates to:
  /// **'Belum ada kru terdaftar'**
  String get attendanceEmptyRosterTitle;

  /// No description provided for @attendanceEmptyRosterBody.
  ///
  /// In id, this message translates to:
  /// **'Daftar kru untuk site ini akan dimuat dari data pengguna terdaftar.'**
  String get attendanceEmptyRosterBody;

  /// Bulk action marking every still-unset crew member present (STEP-55.5 item 2).
  ///
  /// In id, this message translates to:
  /// **'Tandai Semua Masuk'**
  String get attendanceBulkMarkPresent;

  /// No description provided for @attendanceDiscardReasonTitle.
  ///
  /// In id, this message translates to:
  /// **'Hapus alasan?'**
  String get attendanceDiscardReasonTitle;

  /// No description provided for @attendanceDiscardReasonBody.
  ///
  /// In id, this message translates to:
  /// **'Mengubah status menjadi tanpa alasan akan menghapus alasan \"{reason}\" yang sudah diketik. Lanjutkan?'**
  String attendanceDiscardReasonBody(String reason);

  /// No description provided for @attendanceDiscardReasonConfirm.
  ///
  /// In id, this message translates to:
  /// **'Hapus alasan'**
  String get attendanceDiscardReasonConfirm;

  /// No description provided for @attendanceSaving.
  ///
  /// In id, this message translates to:
  /// **'Menyimpan Absensi...'**
  String get attendanceSaving;

  /// No description provided for @attendanceSaveCount.
  ///
  /// In id, this message translates to:
  /// **'Simpan Absensi ({count} Kru)'**
  String attendanceSaveCount(int count);

  /// No description provided for @attendanceStatusLeave.
  ///
  /// In id, this message translates to:
  /// **'Izin'**
  String get attendanceStatusLeave;

  /// No description provided for @attendanceStatusSick.
  ///
  /// In id, this message translates to:
  /// **'Sakit'**
  String get attendanceStatusSick;

  /// No description provided for @attendanceStatusAbsent.
  ///
  /// In id, this message translates to:
  /// **'Alpa'**
  String get attendanceStatusAbsent;

  /// No description provided for @attendanceStatusPresent.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get attendanceStatusPresent;

  /// No description provided for @attendanceStatusUnset.
  ///
  /// In id, this message translates to:
  /// **'belum dipilih'**
  String get attendanceStatusUnset;

  /// No description provided for @attendanceReasonSickLabel.
  ///
  /// In id, this message translates to:
  /// **'Alasan sakit'**
  String get attendanceReasonSickLabel;

  /// No description provided for @attendanceReasonLeaveLabel.
  ///
  /// In id, this message translates to:
  /// **'Alasan izin'**
  String get attendanceReasonLeaveLabel;

  /// No description provided for @attendanceReasonRequiredLabel.
  ///
  /// In id, this message translates to:
  /// **'{label} (wajib)'**
  String attendanceReasonRequiredLabel(String label);

  /// No description provided for @attendanceReasonHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan {label}'**
  String attendanceReasonHint(String label);

  /// No description provided for @attendanceReasonClearTooltip.
  ///
  /// In id, this message translates to:
  /// **'Hapus alasan'**
  String get attendanceReasonClearTooltip;

  /// No description provided for @attendanceStatusChooseLabel.
  ///
  /// In id, this message translates to:
  /// **'Pilih status {label} untuk kru ini'**
  String attendanceStatusChooseLabel(String label);

  /// No description provided for @attendanceCrewStatusLabel.
  ///
  /// In id, this message translates to:
  /// **'Kru {name} — Status: {status}'**
  String attendanceCrewStatusLabel(String name, String status);

  /// No description provided for @attendanceSyncQueued.
  ///
  /// In id, this message translates to:
  /// **'Menunggu sinkronisasi'**
  String get attendanceSyncQueued;

  /// No description provided for @attendanceSyncSyncing.
  ///
  /// In id, this message translates to:
  /// **'Menyinkronkan...'**
  String get attendanceSyncSyncing;

  /// No description provided for @attendanceSyncFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal sinkronisasi'**
  String get attendanceSyncFailed;

  /// No description provided for @attendanceSyncSynced.
  ///
  /// In id, this message translates to:
  /// **'Tersinkronisasi'**
  String get attendanceSyncSynced;

  /// No description provided for @attendanceSyncRetry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get attendanceSyncRetry;

  /// No description provided for @attendanceSyncStatusLabel.
  ///
  /// In id, this message translates to:
  /// **'Status sinkronisasi: {label}'**
  String attendanceSyncStatusLabel(String label);

  /// No description provided for @attendanceSyncRetryLabel.
  ///
  /// In id, this message translates to:
  /// **'Coba sinkronisasi ulang'**
  String get attendanceSyncRetryLabel;

  /// No description provided for @dailyLogOperationalDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal Operasional'**
  String get dailyLogOperationalDate;

  /// No description provided for @dailyLogSummaryLabel.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan Pekerjaan *'**
  String get dailyLogSummaryLabel;

  /// No description provided for @dailyLogNotesLabel.
  ///
  /// In id, this message translates to:
  /// **'Catatan Tambahan & K3 (Safety)'**
  String get dailyLogNotesLabel;

  /// No description provided for @dailyLogZoneLabel.
  ///
  /// In id, this message translates to:
  /// **'Zona Operasional'**
  String get dailyLogZoneLabel;

  /// No description provided for @dailyLogWeatherLabel.
  ///
  /// In id, this message translates to:
  /// **'Kondisi Cuaca'**
  String get dailyLogWeatherLabel;

  /// No description provided for @dailyLogHazardLabel.
  ///
  /// In id, this message translates to:
  /// **'Assessment Bahaya K3'**
  String get dailyLogHazardLabel;

  /// No description provided for @dailyLogHazardRequiredLabel.
  ///
  /// In id, this message translates to:
  /// **'Assessment Bahaya K3 *'**
  String get dailyLogHazardRequiredLabel;

  /// No description provided for @dailyLogHazardSeverityLabel.
  ///
  /// In id, this message translates to:
  /// **'Tingkat Keparahan *'**
  String get dailyLogHazardSeverityLabel;

  /// No description provided for @dailyLogHazardActionLabel.
  ///
  /// In id, this message translates to:
  /// **'Tindakan Perbaikan'**
  String get dailyLogHazardActionLabel;

  /// No description provided for @dailyLogHazardNotesHint.
  ///
  /// In id, this message translates to:
  /// **'Jelaskan bahaya yang teridentifikasi...'**
  String get dailyLogHazardNotesHint;

  /// No description provided for @dailyLogHazardActionHint.
  ///
  /// In id, this message translates to:
  /// **'Langkah korektif yang diambil atau direncanakan...'**
  String get dailyLogHazardActionHint;

  /// No description provided for @dailyLogHazardNone.
  ///
  /// In id, this message translates to:
  /// **'Tidak Ada Bahaya'**
  String get dailyLogHazardNone;

  /// No description provided for @dailyLogHazardPresent.
  ///
  /// In id, this message translates to:
  /// **'Ada Bahaya'**
  String get dailyLogHazardPresent;

  /// No description provided for @dailyLogHazardNotesLabel.
  ///
  /// In id, this message translates to:
  /// **'Catatan Bahaya'**
  String get dailyLogHazardNotesLabel;

  /// No description provided for @dailyLogHazardSeverityLow.
  ///
  /// In id, this message translates to:
  /// **'Rendah'**
  String get dailyLogHazardSeverityLow;

  /// No description provided for @dailyLogHazardSeverityMedium.
  ///
  /// In id, this message translates to:
  /// **'Sedang'**
  String get dailyLogHazardSeverityMedium;

  /// No description provided for @dailyLogHazardSeverityHigh.
  ///
  /// In id, this message translates to:
  /// **'Tinggi'**
  String get dailyLogHazardSeverityHigh;

  /// No description provided for @dailyLogHazardSeverityCritical.
  ///
  /// In id, this message translates to:
  /// **'Kritis'**
  String get dailyLogHazardSeverityCritical;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
