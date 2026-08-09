// File Card — geospatial file list item in ForUI aesthetic.
//
// Phase 2 Tier 2 rebuild (STEP-30.4): Replaced hardcoded Colors.blue/Colors.teal/
// Colors.orange/Colors.green/Colors.purple/Colors.indigo/Colors.red/Colors.grey
// with FTheme semantic tokens. No logic, state, or data-fetching changes.

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
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
    final theme = FTheme.of(context);

    return Dismissible(
      key: ValueKey(file.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colors.destructive,
        child: Icon(
          Icons.delete_outline,
          color: theme.colors.primaryForeground,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus File'),
            content: Text('Yakin ingin menghapus "${file.fileName}"?'),
            actions: [
              FButton(
                variant: FButtonVariant.outline,
                onPress: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal'),
              ),
              FButton(
                variant: FButtonVariant.destructive,
                onPress: () => Navigator.of(ctx).pop(true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: FCard(
          child: ListTile(
            leading: _fileTypeIcon(file.fileType, theme),
            title: Text(
              file.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.body.md.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              [
                if (file.zoneId != null) 'Zona: ${file.zoneId}',
                _formatDate(file.acquisitionDate ?? file.createdAt),
                if (file.fileSizeBytes != null)
                  _formatSize(file.fileSizeBytes!),
              ].join('  •  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.body.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            trailing: onOpenDrive != null
                ? FButton(
                    variant: FButtonVariant.outline,
                    onPress: onOpenDrive,
                    child: const Text('Buka di Drive'),
                  )
                : null,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  Widget _fileTypeIcon(String fileType, FThemeData theme) {
    IconData icon;
    Color color;

    switch (fileType) {
      case '.shp':
        icon = Icons.layers;
        color = theme.colors.primary;
      case '.tiff':
      case '.tif':
        icon = Icons.image;
        color = theme.colors.primary;
      case '.dxf':
      case '.dwg':
        icon = Icons.map;
        color = theme.colors.primary;
      case '.csv':
        icon = Icons.table_chart;
        color = theme.colors.primary;
      case '.kml':
      case '.kmz':
        icon = Icons.public;
        color = theme.colors.primary;
      case '.gpx':
        icon = Icons.route;
        color = theme.colors.primary;
      case '.pdf':
        icon = Icons.picture_as_pdf;
        color = theme.colors.destructive;
      default:
        icon = Icons.insert_drive_file;
        color = theme.colors.mutedForeground;
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
