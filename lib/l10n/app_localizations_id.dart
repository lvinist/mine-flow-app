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
}
