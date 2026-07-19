import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mine_flow/core/services/pdf_service.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';

void main() {
  late PdfService pdfService;

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    pdfService = PdfService();
  });

  group('PdfService', () {
    test(
      'generatePdf returns non-empty bytes for attendance report with empty data',
      () async {
        final bytes = await pdfService.generatePdf(
          reportType: ReportType.attendance,
          title: 'Laporan Kehadiran',
          data: [],
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
        );

        expect(bytes, isA<Uint8List>());
        expect(bytes.length, greaterThan(0));
      },
    );

    test(
      'generatePdf returns non-empty bytes for cut/fill report with empty data',
      () async {
        final bytes = await pdfService.generatePdf(
          reportType: ReportType.cutFill,
          title: 'Laporan Volume Cut/Fill',
          data: [],
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
        );

        expect(bytes, isA<Uint8List>());
        expect(bytes.length, greaterThan(0));
      },
    );

    test(
      'generatePdf returns non-empty bytes for inventory report with empty data',
      () async {
        final bytes = await pdfService.generatePdf(
          reportType: ReportType.inventory,
          title: 'Laporan Inventaris',
          data: [],
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
        );

        expect(bytes, isA<Uint8List>());
        expect(bytes.length, greaterThan(0));
      },
    );

    test('generatePdf returns larger bytes when data is provided', () async {
      final emptyBytes = await pdfService.generatePdf(
        reportType: ReportType.attendance,
        title: 'Laporan Kehadiran',
        data: [],
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );

      final filledBytes = await pdfService.generatePdf(
        reportType: ReportType.attendance,
        title: 'Laporan Kehadiran',
        data: [
          {
            'user_name': 'Budi',
            'date': '2026-07-15',
            'status': 'present',
            'check_in': '07:00',
            'check_out': '16:00',
            'overtime_hours': 1.0,
          },
          {
            'user_name': 'Siti',
            'date': '2026-07-15',
            'status': 'present',
            'check_in': '07:30',
            'check_out': '16:30',
            'overtime_hours': 0.0,
          },
        ],
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );

      // Filled data should produce larger PDF than empty data
      expect(filledBytes.length, greaterThan(emptyBytes.length));
    });
  });
}
