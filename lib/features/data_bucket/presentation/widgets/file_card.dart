import 'package:flutter/material.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';

/// A card widget displaying a [GeospatialFile] summary for use in the file list.
///
/// Shows a file-type icon, file name, zone, acquisition date, and file size.
/// Supports tap to navigate to detail and swipe-to-delete.
class FileCard extends StatelessWidget {
  final GeospatialFile file;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenDrive;

  const FileCard({
    super.key,
    required this.file,
    this.onTap,
    this.onDelete,
    this.onOpenDrive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(file.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus File'),
            content: Text('Yakin ingin menghapus "${file.fileName}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: _fileTypeIcon(file.fileType),
          title: Text(
            file.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            [
              if (file.zoneId != null) 'Zona: ${file.zoneId}',
              _formatDate(file.acquisitionDate ?? file.createdAt),
              if (file.fileSizeBytes != null) _formatSize(file.fileSizeBytes!),
            ].join('  •  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: onOpenDrive != null
              ? TextButton(
                  onPressed: onOpenDrive,
                  child: const Text('Buka di Drive'),
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }

  Icon _fileTypeIcon(String fileType) {
    IconData icon;
    Color color;

    switch (fileType) {
      case '.shp':
        icon = Icons.layers;
        color = Colors.blue;
      case '.tiff':
      case '.tif':
        icon = Icons.image;
        color = Colors.teal;
      case '.dxf':
      case '.dwg':
        icon = Icons.map;
        color = Colors.orange;
      case '.csv':
        icon = Icons.table_chart;
        color = Colors.green;
      case '.kml':
      case '.kmz':
        icon = Icons.public;
        color = Colors.purple;
      case '.gpx':
        icon = Icons.route;
        color = Colors.indigo;
      case '.pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 32);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
