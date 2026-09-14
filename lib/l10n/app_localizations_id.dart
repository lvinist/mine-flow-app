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

  @override
  String get attendanceFormTitle => 'Input Absensi Kru';

  @override
  String get attendanceHeaderSemantics => 'Header absensi';

  @override
  String get attendanceEmptyRosterTitle => 'Belum ada kru terdaftar';

  @override
  String get attendanceEmptyRosterBody =>
      'Daftar kru untuk site ini akan dimuat dari data pengguna terdaftar.';

  @override
  String get attendanceBulkMarkPresent => 'Tandai Semua Masuk';

  @override
  String get attendanceDiscardReasonTitle => 'Hapus alasan?';

  @override
  String attendanceDiscardReasonBody(String reason) {
    return 'Mengubah status menjadi tanpa alasan akan menghapus alasan \"$reason\" yang sudah diketik. Lanjutkan?';
  }

  @override
  String get attendanceDiscardReasonConfirm => 'Hapus alasan';

  @override
  String get attendanceSaving => 'Menyimpan Absensi...';

  @override
  String attendanceSaveCount(int count) {
    return 'Simpan Absensi ($count Kru)';
  }

  @override
  String get attendanceStatusLeave => 'Izin';

  @override
  String get attendanceStatusSick => 'Sakit';

  @override
  String get attendanceStatusAbsent => 'Alpa';

  @override
  String get attendanceStatusPresent => 'Masuk';

  @override
  String get attendanceStatusUnset => 'belum dipilih';

  @override
  String get attendanceReasonSickLabel => 'Alasan sakit';

  @override
  String get attendanceReasonLeaveLabel => 'Alasan izin';

  @override
  String attendanceReasonRequiredLabel(String label) {
    return '$label (wajib)';
  }

  @override
  String attendanceReasonHint(String label) {
    return 'Masukkan $label';
  }

  @override
  String get attendanceReasonClearTooltip => 'Hapus alasan';

  @override
  String attendanceStatusChooseLabel(String label) {
    return 'Pilih status $label untuk kru ini';
  }

  @override
  String attendanceCrewStatusLabel(String name, String status) {
    return 'Kru $name — Status: $status';
  }

  @override
  String get attendanceSyncQueued => 'Menunggu sinkronisasi';

  @override
  String get attendanceSyncSyncing => 'Menyinkronkan...';

  @override
  String get attendanceSyncFailed => 'Gagal sinkronisasi';

  @override
  String get attendanceSyncSynced => 'Tersinkronisasi';

  @override
  String get attendanceSyncRetry => 'Coba lagi';

  @override
  String attendanceSyncStatusLabel(String label) {
    return 'Status sinkronisasi: $label';
  }

  @override
  String get attendanceSyncRetryLabel => 'Coba sinkronisasi ulang';

  @override
  String get dailyLogOperationalDate => 'Tanggal Operasional';

  @override
  String get dailyLogSummaryLabel => 'Ringkasan Pekerjaan *';

  @override
  String get dailyLogNotesLabel => 'Catatan Tambahan & K3 (Safety)';

  @override
  String get dailyLogZoneLabel => 'Zona Operasional';

  @override
  String get dailyLogWeatherLabel => 'Kondisi Cuaca';

  @override
  String get dailyLogHazardLabel => 'Assessment Bahaya K3';

  @override
  String get dailyLogHazardRequiredLabel => 'Assessment Bahaya K3 *';

  @override
  String get dailyLogHazardSeverityLabel => 'Tingkat Keparahan *';

  @override
  String get dailyLogHazardActionLabel => 'Tindakan Perbaikan';

  @override
  String get dailyLogHazardNotesHint =>
      'Jelaskan bahaya yang teridentifikasi...';

  @override
  String get dailyLogHazardActionHint =>
      'Langkah korektif yang diambil atau direncanakan...';

  @override
  String get dailyLogHazardNone => 'Tidak Ada Bahaya';

  @override
  String get dailyLogHazardPresent => 'Ada Bahaya';

  @override
  String get dailyLogHazardNotesLabel => 'Catatan Bahaya';

  @override
  String get dailyLogHazardSeverityLow => 'Rendah';

  @override
  String get dailyLogHazardSeverityMedium => 'Sedang';

  @override
  String get dailyLogHazardSeverityHigh => 'Tinggi';

  @override
  String get dailyLogHazardSeverityCritical => 'Kritis';

  @override
  String get equipmentCheckDeleteRecord => 'Hapus Catatan';

  @override
  String equipmentCheckSerialNumber(String serial) {
    return 'S/N: $serial';
  }

  @override
  String equipmentCheckInspector(String name) {
    return 'Inspektur: $name';
  }

  @override
  String equipmentCheckSite(String site) {
    return 'Site: $site';
  }

  @override
  String get equipmentCheckResultHeader => 'HASIL SOP CHECKLIST';

  @override
  String equipmentCheckResultSummary(int passed, int failed, int total) {
    return '$passed Lolos • $failed Gagal / $total Item';
  }

  @override
  String get equipmentCheckAdditionalRemarks => 'CATATAN TAMBAHAN PEMERIKSAAN';

  @override
  String get equipmentCheckDetailTitle => 'Detail Pemeriksaan Peralatan';

  @override
  String get equipmentCheckAccessDeniedTitle => 'Akses Ditolak';

  @override
  String get equipmentCheckAccessDeniedMessage =>
      'Lokasi kerja tidak valid atau Anda tidak memiliki akses.';

  @override
  String get equipmentCheckBack => 'Kembali';

  @override
  String get equipmentCheckInvalidRecord => 'Catatan pemeriksaan tidak valid.';

  @override
  String get equipmentCheckDeleteConfirmMessage =>
      'Anda yakin ingin menghapus catatan pemeriksaan peralatan ini?';

  @override
  String get profileEditTitle => 'Edit Profil';

  @override
  String get profileDetail => 'Detail Profil';

  @override
  String get profileDisplayName => 'Nama Tampilan';

  @override
  String get profileRoleManaged => 'Peran (dikelola sistem)';

  @override
  String get profileSave => 'Simpan';

  @override
  String get dataBucketBack => 'Kembali';

  @override
  String get inventoryChangeData => 'Ubah Data';

  @override
  String get inventoryStockAdjustment => 'Penyesuaian Stok';

  @override
  String get inventoryDeleteItem => 'Hapus Item';

  @override
  String get inventoryCurrentStock => 'Stok Saat Ini';

  @override
  String get inventoryAdjustmentHistory => 'Riwayat Penyesuaian';

  @override
  String get inventoryNoTransactionHistory => 'Belum ada riwayat transaksi.';

  @override
  String get privacyTitle => 'Privasi & Syarat';

  @override
  String get privacyLogout => 'Keluar';

  @override
  String get privacyCardTitle => 'Pemberitahuan Privasi Internal';

  @override
  String get privacyCardSubtitle =>
      'Harap tinjau dan setujui kebijakan penggunaan data kami.';

  @override
  String get privacyCardBody =>
      'Aplikasi ini mengumpulkan data pribadi yang terkait dengan operasional kerja dan keselamatan Anda, termasuk Nama, Kontak, Nomor KTP, dan log aktivitas operasional. Data ini diproses berdasarkan Kontrak Kerja dan Kepentingan Bisnis yang Sah. Data operasional akan disimpan tanpa batas waktu, dan data identitas karyawan akan disimpan selama 7 tahun setelah masa kerja berakhir sebelum dihapus secara permanen. Dengan melanjutkan, Anda menyetujui pemrosesan data ini.';

  @override
  String get privacyAckButton => 'Setuju & Lanjutkan';

  @override
  String get error => 'Kesalahan';
}
