import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';

/// Service responsible for generating PDF documents from report data.
///
/// Uses the `pdf` package to create formatted PDF pages with headers,
/// data tables, and summary statistics. Follows the Forest & Stone design
/// system colors where applicable.
class PdfService {
  static final Logger _logger = Logger('PdfService');

  /// Forest & Stone primary color for PDF headers.
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF166534);

  /// Stone gray for secondary text.
  static const PdfColor _stoneGray = PdfColor.fromInt(0xFF78716C);

  /// Generates a PDF document for the given report type and data.
  ///
  /// Returns the PDF as raw [Uint8List] bytes suitable for sharing/saving.
  /// [reportType] determines the table column layout.
  /// [title] is the report title shown in the header.
  /// [data] is a list of maps where keys are column identifiers.
  /// [startDate] and [endDate] define the report period.
  Future<Uint8List> generatePdf({
    required ReportType reportType,
    required String title,
    required List<Map<String, dynamic>> data,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _logger.info('Generating PDF for $title (${data.length} records)');

    final pdf = pw.Document(
      title: title,
      author: 'mine-flow',
      creator: 'mine-flow Reporting System',
    );

    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final periodText =
        '${dateFormat.format(startDate)} — ${dateFormat.format(endDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(title, periodText, context),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildSummarySection(reportType, data),
          pw.SizedBox(height: 16),
          _buildDataTable(reportType, data),
        ],
      ),
    );

    final bytes = await pdf.save();
    _logger.info('PDF generated successfully: ${bytes.length} bytes');
    return Uint8List.fromList(bytes);
  }

  /// Builds the page header with title, period, and a colored divider.
  pw.Widget _buildHeader(String title, String periodText, pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            pw.Text(
              'mine-flow',
              style: const pw.TextStyle(fontSize: 10, color: _stoneGray),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Periode: $periodText',
          style: const pw.TextStyle(fontSize: 10, color: _stoneGray),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Dibuat: ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 9, color: _stoneGray),
        ),
        pw.Divider(color: _primaryColor, thickness: 1.5),
      ],
    );
  }

  /// Builds the page footer with page numbers.
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Halaman ${context.pageNumber} / ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: _stoneGray),
      ),
    );
  }

  /// Builds a summary statistics section based on report type.
  pw.Widget _buildSummarySection(
    ReportType reportType,
    List<Map<String, dynamic>> data,
  ) {
    switch (reportType) {
      case ReportType.attendance:
        return _buildAttendanceSummary(data);
      case ReportType.cutFill:
        return _buildCutFillSummary(data);
      case ReportType.inventory:
        return _buildInventorySummary(data);
    }
  }

  pw.Widget _buildAttendanceSummary(List<Map<String, dynamic>> data) {
    final total = data.length;
    final present = data.where((d) => d['status'] == 'present').length;
    final absent = data.where((d) => d['status'] == 'absent').length;
    final sick = data.where((d) => d['status'] == 'sick').length;
    final leave = data.where((d) => d['status'] == 'leave').length;
    final totalOvertime = data.fold<double>(
      0.0,
      (sum, d) => sum + ((d['overtime_hours'] as num?)?.toDouble() ?? 0.0),
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total', '$total'),
          _summaryItem('Hadir', '$present'),
          _summaryItem('Absen', '$absent'),
          _summaryItem('Sakit', '$sick'),
          _summaryItem('Cuti', '$leave'),
          _summaryItem('Lembur (jam)', totalOvertime.toStringAsFixed(1)),
        ],
      ),
    );
  }

  pw.Widget _buildCutFillSummary(List<Map<String, dynamic>> data) {
    final totalCut = data.fold<double>(
      0.0,
      (sum, d) => sum + ((d['cut_volume_m3'] as num?)?.toDouble() ?? 0.0),
    );
    final totalFill = data.fold<double>(
      0.0,
      (sum, d) => sum + ((d['fill_volume_m3'] as num?)?.toDouble() ?? 0.0),
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total Pengukuran', '${data.length}'),
          _summaryItem('Total Cut (m³)', totalCut.toStringAsFixed(2)),
          _summaryItem('Total Fill (m³)', totalFill.toStringAsFixed(2)),
          _summaryItem('Netto (m³)', (totalCut - totalFill).toStringAsFixed(2)),
        ],
      ),
    );
  }

  pw.Widget _buildInventorySummary(List<Map<String, dynamic>> data) {
    final totalItems = data.length;
    final lowStock = data.where((d) {
      final qty = (d['quantity'] as num?)?.toDouble() ?? 0.0;
      final minStock = (d['minimum_stock'] as num?)?.toDouble() ?? 0.0;
      return qty <= minStock && minStock > 0;
    }).length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total Item', '$totalItems'),
          _summaryItem('Stok Rendah', '$lowStock'),
        ],
      ),
    );
  }

  pw.Widget _summaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: _stoneGray),
        ),
      ],
    );
  }

  /// Builds the data table based on report type.
  pw.Widget _buildDataTable(
    ReportType reportType,
    List<Map<String, dynamic>> data,
  ) {
    switch (reportType) {
      case ReportType.attendance:
        return _buildAttendanceTable(data);
      case ReportType.cutFill:
        return _buildCutFillTable(data);
      case ReportType.inventory:
        return _buildInventoryTable(data);
    }
  }

  pw.Widget _buildAttendanceTable(List<Map<String, dynamic>> data) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
      },
      headers: ['Nama', 'Tanggal', 'Status', 'Masuk', 'Keluar', 'Lembur (jam)'],
      data: data.map((row) {
        final date = row['date'] != null
            ? dateFormat.format(DateTime.parse(row['date'] as String))
            : '-';
        return [
          row['user_name']?.toString() ?? '-',
          date,
          _translateStatus(row['status']?.toString() ?? ''),
          row['check_in']?.toString() ?? '-',
          row['check_out']?.toString() ?? '-',
          (row['overtime_hours'] as num?)?.toStringAsFixed(1) ?? '0.0',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildCutFillTable(List<Map<String, dynamic>> data) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerLeft,
      },
      headers: [
        'Zona',
        'Tanggal',
        'Cut (m³)',
        'Fill (m³)',
        'Netto (m³)',
        'Diukur oleh',
      ],
      data: data.map((row) {
        final date = row['measurement_date'] != null
            ? dateFormat.format(
                DateTime.parse(row['measurement_date'] as String),
              )
            : '-';
        return [
          row['zone_name']?.toString() ?? '-',
          date,
          (row['cut_volume_m3'] as num?)?.toStringAsFixed(2) ?? '0.00',
          (row['fill_volume_m3'] as num?)?.toStringAsFixed(2) ?? '0.00',
          (row['net_volume_m3'] as num?)?.toStringAsFixed(2) ?? '0.00',
          row['measured_by']?.toString() ?? '-',
        ];
      }).toList(),
    );
  }

  pw.Widget _buildInventoryTable(List<Map<String, dynamic>> data) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
      },
      headers: ['Nama Item', 'Kategori', 'Jumlah', 'Satuan', 'Stok Minimum'],
      data: data.map((row) {
        return [
          row['item_name']?.toString() ?? '-',
          row['category']?.toString() ?? '-',
          (row['quantity'] as num?)?.toStringAsFixed(1) ?? '0.0',
          row['unit']?.toString() ?? '-',
          (row['minimum_stock'] as num?)?.toStringAsFixed(1) ?? '0.0',
        ];
      }).toList(),
    );
  }

  /// Translates attendance status to Indonesian display text.
  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return 'Hadir';
      case 'absent':
        return 'Absen';
      case 'sick':
        return 'Sakit';
      case 'leave':
        return 'Cuti';
      default:
        return status;
    }
  }
}
