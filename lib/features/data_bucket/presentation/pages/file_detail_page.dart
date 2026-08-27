// File Detail Page — geospatial file metadata detail in ForUI aesthetic.
//
// Phase 2 Tier 2 rebuild (STEP-30.4): Replaced hardcoded Colors.blue/Colors.teal/
// Colors.orange/Colors.green/Colors.purple/Colors.indigo/Colors.red/Colors.grey
// with FTheme semantic tokens. No logic, state, or data-fetching changes.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:url_launcher/url_launcher.dart';

const double _kPagePadding = 24;
const double _kSpacing8 = 8;
const double _kSpacing12 = 12;
const double _kSpacing24 = 24;
const double _kBadgeRadius = 12;

/// Screen displaying detailed metadata for a single [GeospatialFile].
///
/// Shows file name, type icon, size, zone, coordinates, acquisition date,
/// upload info, notes, and actions (Open in Drive, Delete).
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

class _FileDetailPageState extends State<FileDetailPage> {
  bool _isDeleting = false;

  GeospatialFile get file => widget.file;
  DataBucketRepository get repository => widget.repository;

  /// CF-079: delete with a loading state and a double-trigger guard. The bloc
  /// is local to the list route (not accessible from this pushed detail route),
  /// so this deletes via the repository; the list page refreshes on return.
  Future<void> _delete() async {
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    try {
      await widget.repository.deleteFile(widget.file.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final theme = FTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus file: ${e.toString()}'),
            backgroundColor: theme.colors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final file = widget.file;

    return Scaffold(
      appBar: MediaQuery.of(context).size.width > 800
          ? null
          : AppBar(
              title: Semantics(
                header: true,
                child: Text(
                  'Detail File',
                  style: theme.typography.display.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.of(context).pop(),
              ),
              elevation: 0,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreVertical),
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
                            FButton(
                              variant: FButtonVariant.ghost,
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
                      if (confirmed == true && context.mounted) {
                        unawaited(_delete());
                      }
                    } else if (value == 'open_drive') {
                      _openDriveLink(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'open_drive',
                      child: FTile(
                        prefix: const Icon(LucideIcons.externalLink),
                        title: const Text('Buka di Drive'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: FTile(
                        prefix: Icon(
                          LucideIcons.trash2,
                          color: theme.colors.destructive,
                        ),
                        title: Text(
                          'Hapus',
                          style: theme.typography.body.md.copyWith(
                            color: theme.colors.destructive,
                          ),
                        ),
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
            // File icon and name
            _buildFileHeader(file, theme),
            const SizedBox(height: _kSpacing24),

            // Details card
            _buildDetailsCard(context, file, theme),
            const SizedBox(height: _kSpacing24),

            // Open in Drive button
            if (file.driveLink.isNotEmpty)
              FButton(
                prefix: const Icon(LucideIcons.externalLink),
                onPress: () => _openDriveLink(context),
                child: const Text('Buka di Google Drive'),
              ),

            // Notes section
            if (file.notes != null && file.notes!.isNotEmpty) ...[
              const SizedBox(height: _kSpacing24),
              _buildNotesSection(file.notes!, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileHeader(GeospatialFile file, FThemeData theme) {
    return Column(
      children: [
        Icon(
          _fileTypeIcon(file.fileType),
          size: 64,
          color: _fileTypeColor(theme),
        ),
        const SizedBox(height: _kSpacing12),
        Text(
          file.fileName,
          style: theme.typography.display.xs,
          textAlign: TextAlign.center,
        ),
        if (file.fileSizeBytes != null) ...[
          const SizedBox(height: 4),
          Text(
            _formatSize(file.fileSizeBytes!),
            style: theme.typography.body.md.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    GeospatialFile file,
    FThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colors.border),
        borderRadius: BorderRadius.circular(_kBadgeRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_kPagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detail', style: theme.typography.body.md),
            const FDivider(),
            _detailRow(context, 'Tipe', _typeLabel(file.fileType)),
            if (file.mimeType != null)
              _detailRow(context, 'MIME', file.mimeType!),
            if (file.zoneId != null) _detailRow(context, 'Zona', file.zoneId!),
            _detailRow(
              context,
              'Tanggal Akuisisi',
              file.acquisitionDate != null
                  ? DateFormat('yyyy-MM-dd').format(file.acquisitionDate!)
                  : '-',
            ),
            _detailRow(
              context,
              'Diunggah',
              DateFormat('yyyy-MM-dd').format(file.createdAt),
            ),
            if (file.uploadedBy != null)
              _detailRow(context, 'Diunggah Oleh', file.uploadedBy!),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final theme = FTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _kSpacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CF-072: flexible label (was fixed 130dp) so it ellipsizes instead
          // of clipping at large text scale.
          Flexible(
            flex: 2,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.body.sm,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(String notes, FThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colors.border),
        borderRadius: BorderRadius.circular(_kBadgeRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_kPagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catatan', style: theme.typography.body.md),
            const SizedBox(height: _kSpacing8),
            Text(notes, style: theme.typography.body.md),
          ],
        ),
      ),
    );
  }

  void _openDriveLink(BuildContext context) async {
    final theme = FTheme.of(context);
    if (file.driveLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada tautan Drive untuk file ini.')),
      );
      return;
    }

    // CF-071: guard malformed links and launch failures — previously a bad
    // link or a failed launch was silent.
    final uri = Uri.tryParse(file.driveLink);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tautan Drive tidak valid.'),
          backgroundColor: theme.colors.destructive,
        ),
      );
      return;
    }

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tidak dapat membuka tautan Drive.'),
              backgroundColor: theme.colors.destructive,
            ),
          );
        }
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal membuka tautan Drive.'),
            backgroundColor: theme.colors.destructive,
          ),
        );
      }
    }
  }

  IconData _fileTypeIcon(String fileType) {
    switch (fileType) {
      case '.shp':
        return LucideIcons.layers;
      case '.tiff':
      case '.tif':
        return LucideIcons.image;
      case '.dxf':
      case '.dwg':
        return LucideIcons.map;
      case '.csv':
        return LucideIcons.table;
      case '.kml':
      case '.kmz':
        return LucideIcons.globe;
      case '.gpx':
        return LucideIcons.spline;
      case '.pdf':
        return LucideIcons.fileText;
      default:
        return LucideIcons.file;
    }
  }

  Color _fileTypeColor(FThemeData theme) {
    // CF-095: collapse the pointless per-type switch — every type shared the
    // primary token and .pdf used `destructive`, which read as "broken".
    return theme.colors.primary;
  }

  String _typeLabel(String fileType) {
    switch (fileType) {
      case '.shp':
        return 'Shapefile (.shp)';
      case '.tiff':
      case '.tif':
        return 'GeoTIFF (.tiff)';
      case '.dxf':
        return 'DXF (.dxf)';
      case '.dwg':
        return 'DWG (.dwg)';
      case '.csv':
        return 'CSV (.csv)';
      case '.kml':
        return 'KML (.kml)';
      case '.kmz':
        return 'KMZ (.kmz)';
      case '.gpx':
        return 'GPX (.gpx)';
      case '.pdf':
        return 'PDF (.pdf)';
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
