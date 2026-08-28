// File Card — geospatial file list item in ForUI aesthetic.
//
// Phase 2 Tier 2 rebuild (STEP-30.4): Replaced hardcoded Colors.blue/Colors.teal/
// Colors.orange/Colors.green/Colors.purple/Colors.indigo/Colors.red/Colors.grey
// with FTheme semantic tokens. No logic, state, or data-fetching changes.

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
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
        child: Icon(LucideIcons.trash2, color: theme.colors.primaryForeground),
      ),
      confirmDismiss: (_) async {
        // CF-024: role-gate to supervisors, and make the copy explicit that
        // the file is permanently removed from Google Drive.
        final user = authCubit?.state.user;
        if (user == null || !user.isSupervisor) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Hanya supervisor yang dapat menghapus file.',
              ),
              backgroundColor: theme.colors.destructive,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        return await showFDialog<bool>(
          context: context,
          builder: (context, style, animation) => FDialog(
            builder: (context, style) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FAlert(
                  variant: FAlertVariant.destructive,
                  title: const Text('Hapus File'),
                  subtitle: Text(
                    'Yakin ingin menghapus "${file.fileName}" dari Google Drive? '
                    'Tindakan tidak dapat dibatalkan.',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FButton(
                      variant: FButtonVariant.outline,
                      onPress: () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    FButton(
                      variant: FButtonVariant.destructive,
                      onPress: () => Navigator.of(context).pop(true),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: FCard(
          child: FTile(
            prefix: _fileTypeIcon(file.fileType, theme),
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
            suffix: onOpenDrive != null
                ? FButton(
                    variant: FButtonVariant.outline,
                    onPress: onOpenDrive,
                    child: const Text('Buka di Drive'),
                  )
                : null,
            onPress: onTap,
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
        icon = LucideIcons.layers;
        color = theme.colors.primary;
      case '.tiff':
      case '.tif':
        icon = LucideIcons.image;
        color = theme.colors.primary;
      case '.dxf':
      case '.dwg':
        icon = LucideIcons.map;
        color = theme.colors.primary;
      case '.csv':
        icon = LucideIcons.table;
        color = theme.colors.primary;
      case '.kml':
      case '.kmz':
        icon = LucideIcons.globe;
        color = theme.colors.primary;
      case '.gpx':
        icon = LucideIcons.spline;
        color = theme.colors.primary;
      case '.pdf':
        icon = LucideIcons.fileText;
        color = theme.colors.destructive;
      default:
        icon = LucideIcons.file;
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
