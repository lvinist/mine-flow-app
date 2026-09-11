// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'mine-flow';

  @override
  String get localizationBaseline => 'Dasar Lokalisasi STEP-41';

  @override
  String get reportTypePickerTitle => 'Pilih Jenis Laporan';

  @override
  String get fileDetailNotFound => 'File tidak ditemukan.';

  @override
  String get sheetClose => 'Tutup';

  @override
  String get sheetBarrierLabel => 'Tutup lembar';

  @override
  String get processInProgress => 'Proses masih berjalan';

  @override
  String get unsavedChangesTitle => 'Perubahan belum disimpan';

  @override
  String get unsavedChangesBody => 'Perubahan yang belum disimpan akan hilang.';

  @override
  String get continueEditing => 'Lanjut Mengedit';

  @override
  String get discardChanges => 'Buang Perubahan';

  @override
  String statusLabel(String value) {
    return 'Status: $value';
  }

  @override
  String get filterLabel => 'Filter';

  @override
  String get cancel => 'Batal';

  @override
  String get resetFilters => 'Reset filter';

  @override
  String get apply => 'Terapkan';

  @override
  String get chooseDateRange => 'Pilih rentang tanggal';

  @override
  String get chooseDate => 'Pilih tanggal';

  @override
  String get interactionFixtureTitle => 'Contoh interaksi';

  @override
  String get interactionFixtureList => 'Contoh daftar tersimpan';

  @override
  String get interactionFixtureSheet => 'Contoh lembar berbasis rute';

  @override
  String get cutFillNotFound => 'Pengukuran cut/fill tidak ditemukan.';

  @override
  String get backToList => 'Kembali ke daftar';

  @override
  String get newMeasurement => 'Pengukuran Baru';

  @override
  String get editMeasurement => 'Edit Pengukuran';

  @override
  String get saveMeasurement => 'Simpan Pengukuran';

  @override
  String get saving => 'Menyimpan...';

  @override
  String get measurementSaved => 'Data cut/fill berhasil disimpan!';

  @override
  String contextualReportTitle(String sourceTitle) {
    return 'Laporan: $sourceTitle';
  }

  @override
  String get operationalZoneOptional => 'Zona Operasional (Opsional)';

  @override
  String get generateReport => 'Buat Laporan';

  @override
  String get sharePdf => 'Bagikan PDF';

  @override
  String get printReport => 'Cetak';

  @override
  String get regenerateReport => 'Buat Ulang';

  @override
  String get dataNotFound => 'Data Tidak Ditemukan';

  @override
  String get cutFillTitle => 'Volume Cut / Fill';

  @override
  String get selectZoneValidation => 'Pilih zona terlebih dahulu.';

  @override
  String get selectMaterialValidation => 'Pilih material terlebih dahulu.';

  @override
  String get volumeValidation =>
      'Isi minimal salah satu volume (BCM atau LCM).';
}
