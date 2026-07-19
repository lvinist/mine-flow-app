import 'package:flutter/material.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen displaying detailed metadata for a single [GeospatialFile].
///
/// Shows file name, type icon, size, zone, coordinates, acquisition date,
/// upload info, notes, and actions (Open in Drive, Delete).
class FileDetailPage extends StatelessWidget {
  final GeospatialFile file;
  final DataBucketRepository repository;

  const FileDetailPage({
    super.key,
    required this.file,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail File'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus File'),
                    content: Text(
                      'Yakin ingin menghapus "${file.fileName}"?\n\n'
                      'File ini akan dihapus dari Google Drive dan database.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  try {
                    await repository.deleteFile(file.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${file.fileName}" berhasil dihapus.'),
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Gagal menghapus file: ${e.toString()}',
                          ),
                          backgroundColor: Colors.red,
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
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Hapus', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File icon and name
            _buildFileHeader(file, theme),
            const SizedBox(height: 24),

            // Details card
            _buildDetailsCard(file, theme),
            const SizedBox(height: 24),

            // Open in Drive button
            if (file.driveLink.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Buka di Google Drive'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _openDriveLink(context),
              ),

            // Notes section
            if (file.notes != null && file.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildNotesSection(file.notes!, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileHeader(GeospatialFile file, ThemeData theme) {
    return Column(
      children: [
        Icon(
          _fileTypeIcon(file.fileType),
          size: 64,
          color: _fileTypeColor(file.fileType),
        ),
        const SizedBox(height: 12),
        Text(
          file.fileName,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        if (file.fileSizeBytes != null) ...[
          const SizedBox(height: 4),
          Text(
            _formatSize(file.fileSizeBytes!),
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsCard(GeospatialFile file, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detail', style: theme.textTheme.titleMedium),
            const Divider(),
            _detailRow('Tipe', _typeLabel(file.fileType)),
            if (file.mimeType != null) _detailRow('MIME', file.mimeType!),
            if (file.zoneId != null) _detailRow('Zona', file.zoneId!),
            if (file.latitude != null && file.longitude != null) ...[
              _detailRow('Latitude', file.latitude!.toStringAsFixed(7)),
              _detailRow('Longitude', file.longitude!.toStringAsFixed(7)),
            ],
            _detailRow(
              'Tanggal Akuisisi',
              file.acquisitionDate != null
                  ? '${file.acquisitionDate!.year}-${file.acquisitionDate!.month.toString().padLeft(2, '0')}-${file.acquisitionDate!.day.toString().padLeft(2, '0')}'
                  : '-',
            ),
            _detailRow(
              'Diunggah',
              '${file.createdAt.year}-${file.createdAt.month.toString().padLeft(2, '0')}-${file.createdAt.day.toString().padLeft(2, '0')}',
            ),
            if (file.uploadedBy != null)
              _detailRow('Diunggah Oleh', file.uploadedBy!),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildNotesSection(String notes, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catatan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(notes, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _openDriveLink(BuildContext context) async {
    if (file.driveLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada tautan Drive untuk file ini.')),
      );
      return;
    }

    final uri = Uri.tryParse(file.driveLink);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
