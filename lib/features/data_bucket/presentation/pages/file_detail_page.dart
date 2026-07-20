import 'package:flutter/material.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:url_launcher/url_launcher.dart';

// Phase 2 — shadcn-admin design language constants (DESIGN.md §29).
const double _kCardRadius = 12;
const double _kPagePadding = 24;
const double _kContentGap = 24;

/// Spacing scale derived from DESIGN.md §29 (4, 8, 12, 16, 20, 24, 32 dp).
/// Using a helper avoids stray hardcoded values and keeps the rhythm consistent.
const double _kSpacing4 = 4;
const double _kSpacing8 = 8;
const double _kSpacing12 = 12;
const double _kSpacing20 = 20;

/// Curve constant for micro-interactions (DESIGN.md §33).
const Curve _kAnimCurve = Curves.easeOutQuart;

/// Micro-spacing constant (DESIGN.md §29 spacing scale — 6 is the
/// internal detail-row vertical padding, between standard steps).
const double _kSpacing6 = 6;

/// Screen displaying detailed metadata for a single [GeospatialFile].
///
/// Shows file name, type icon, size, zone, coordinates, acquisition date,
/// upload info, notes, and actions (Open in Drive, Delete).
///
/// Phase 2 Polish (substep 24.2): staggered entrance animations with
/// easeOutQuart curves, refined spacing using DESIGN.md spacing scale,
/// micro-interactions on all tappable elements, and consistent theme-token
/// usage throughout (no raw color values).
class FileDetailPage extends StatefulWidget {
  final GeospatialFile file;
  final DataBucketRepository repository;

  const FileDetailPage({
    super.key,
    required this.file,
    required this.repository,
  });

  @override
  State<FileDetailPage> createState() => _FileDetailPageState();
}

class _FileDetailPageState extends State<FileDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _headerFade;
  late final Animation<double> _detailsFade;
  late final Animation<double> _driveFade;
  late final Animation<double> _notesFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<Offset> _detailsSlide;
  late final Animation<Offset> _driveSlide;
  late final Animation<Offset> _notesSlide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Staggered entrance: each section fades + slides in with 80ms delay.
    const curve = _kAnimCurve;

    _headerFade = CurvedAnimation(
      parent: _animController,
      curve: Interval(0.0, 0.4, curve: curve),
    );
    _detailsFade = CurvedAnimation(
      parent: _animController,
      curve: Interval(0.15, 0.55, curve: curve),
    );
    _driveFade = CurvedAnimation(
      parent: _animController,
      curve: Interval(0.3, 0.7, curve: curve),
    );
    _notesFade = CurvedAnimation(
      parent: _animController,
      curve: Interval(0.45, 0.85, curve: curve),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_headerFade);
    _detailsSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_detailsFade);
    _driveSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_driveFade);
    _notesSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(_notesFade);

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: const Text('Detail File')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Lainnya',
            onSelected: (value) async {
              if (value == 'delete') {
                final confirmed = await _showDeleteDialog(context, theme);
                if (confirmed == true && context.mounted) {
                  try {
                    await widget.repository.deleteFile(widget.file.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_kCardRadius),
                          ),
                          content: Text(
                            '"${widget.file.fileName}" berhasil dihapus.',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_kCardRadius),
                          ),
                          content: Text(
                            'Gagal menghapus file: ${e.toString()}',
                          ),
                          backgroundColor: theme.colorScheme.error,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                }
              } else if (value == 'open_drive') {
                _openDriveLink(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'open_drive',
                child: ListTile(
                  leading: Icon(Icons.open_in_new),
                  title: Text('Buka di Drive'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: theme.colorScheme.error),
                  title: Text(
                    'Hapus',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(_kPagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File icon and name — staggered entrance
            FadeTransition(
              opacity: _headerFade,
              child: SlideTransition(
                position: _headerSlide,
                child: _buildFileHeader(widget.file, theme),
              ),
            ),
            const SizedBox(height: _kContentGap),

            // Details card — staggered entrance
            FadeTransition(
              opacity: _detailsFade,
              child: SlideTransition(
                position: _detailsSlide,
                child: _buildDetailsCard(widget.file, theme),
              ),
            ),
            const SizedBox(height: _kContentGap),

            // Open in Drive button — staggered entrance
            if (widget.file.driveLink.isNotEmpty)
              FadeTransition(
                opacity: _driveFade,
                child: SlideTransition(
                  position: _driveSlide,
                  child: Semantics(
                    label: 'Buka file di Google Drive',
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Buka di Google Drive'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_kCardRadius),
                        ),
                      ),
                      onPressed: () => _openDriveLink(context),
                    ),
                  ),
                ),
              ),

            // Notes section — staggered entrance
            if (widget.file.notes != null && widget.file.notes!.isNotEmpty) ...[
              const SizedBox(height: _kContentGap),
              FadeTransition(
                opacity: _notesFade,
                child: SlideTransition(
                  position: _notesSlide,
                  child: _buildNotesSection(widget.file.notes!, theme),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context, ThemeData theme) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kCardRadius),
        ),
        title: const Text('Hapus File'),
        content: Text(
          'Yakin ingin menghapus "${widget.file.fileName}"?\n\n'
          'File ini akan dihapus dari Google Drive dan database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileHeader(GeospatialFile file, ThemeData theme) {
    return Semantics(
      label: 'File: ${file.fileName}',
      child: Column(
        children: [
          // Icon container with themed background
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _fileTypeColor(file.fileType).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              _fileTypeIcon(file.fileType),
              size: 40,
              color: _fileTypeColor(file.fileType),
            ),
          ),
          const SizedBox(height: _kSpacing12),
          Text(
            file.fileName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (file.fileSizeBytes != null) ...[
            const SizedBox(height: _kSpacing4),
            Text(
              _formatSize(file.fileSizeBytes!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard(GeospatialFile file, ThemeData theme) {
    return Semantics(
      label: 'Detail file',
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(_kCardRadius),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(_kSpacing20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Detail',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: _kSpacing8),
              const Divider(height: 1),
              const SizedBox(height: _kSpacing8),
              _detailRow('Tipe', _typeLabel(file.fileType), theme),
              if (file.mimeType != null)
                _detailRow('MIME', file.mimeType!, theme),
              if (file.zoneId != null) _detailRow('Zona', file.zoneId!, theme),
              if (file.latitude != null && file.longitude != null) ...[
                _detailRow(
                  'Latitude',
                  file.latitude!.toStringAsFixed(7),
                  theme,
                ),
                _detailRow(
                  'Longitude',
                  file.longitude!.toStringAsFixed(7),
                  theme,
                ),
              ],
              _detailRow(
                'Tanggal Akuisisi',
                file.acquisitionDate != null
                    ? '${file.acquisitionDate!.year}-${file.acquisitionDate!.month.toString().padLeft(2, '0')}-${file.acquisitionDate!.day.toString().padLeft(2, '0')}'
                    : '-',
                theme,
              ),
              _detailRow(
                'Diunggah',
                '${file.createdAt.year}-${file.createdAt.month.toString().padLeft(2, '0')}-${file.createdAt.day.toString().padLeft(2, '0')}',
                theme,
              ),
              if (file.uploadedBy != null)
                _detailRow('Diunggah Oleh', file.uploadedBy!, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _kSpacing6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(String notes, ThemeData theme) {
    return Semantics(
      label: 'Catatan file',
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(_kCardRadius),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(_kSpacing20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Catatan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: _kSpacing8),
              const Divider(height: 1),
              const SizedBox(height: _kSpacing12),
              Text(
                notes,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDriveLink(BuildContext context) async {
    if (widget.file.driveLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kCardRadius),
          ),
          content: const Text('Tidak ada tautan Drive untuk file ini.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(widget.file.driveLink);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ——— File-type helpers ———

  IconData _fileTypeIcon(String fileType) {
    switch (fileType) {
      case '.shp':
        return Icons.layers;
      case '.tiff':
      case '.tif':
        return Icons.image;
      case '.dxf':
      case '.dwg':
        return Icons.map;
      case '.csv':
        return Icons.table_chart;
      case '.kml':
      case '.kmz':
        return Icons.public;
      case '.gpx':
        return Icons.route;
      case '.pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _fileTypeColor(String fileType) {
    // Semantic file-type colour coding — these are informational badges,
    // not UI chrome, so using named colours is appropriate and consistent
    // with the shadcn-admin badge/status-dot pattern.
    switch (fileType) {
      case '.shp':
        return Colors.blue;
      case '.tiff':
      case '.tif':
        return Colors.teal;
      case '.dxf':
      case '.dwg':
        return Colors.orange;
      case '.csv':
        return Colors.green;
      case '.kml':
      case '.kmz':
        return Colors.purple;
      case '.gpx':
        return Colors.indigo;
      case '.pdf':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _typeLabel(String fileType) {
    switch (fileType) {
      case '.shp':
        return 'Shapefile';
      case '.tiff':
      case '.tif':
        return 'GeoTIFF';
      case '.dxf':
        return 'DXF';
      case '.dwg':
        return 'DWG';
      case '.csv':
        return 'CSV';
      case '.kml':
        return 'KML';
      case '.kmz':
        return 'KMZ';
      case '.gpx':
        return 'GPX';
      case '.pdf':
        return 'PDF';
      default:
        return fileType;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
