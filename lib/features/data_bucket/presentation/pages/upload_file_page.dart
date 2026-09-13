// Upload File Page — geospatial file upload form in ForUI aesthetic.
//
// Phase 2 Tier 2 rebuild (STEP-30.4): Replaced hardcoded Colors.red/Colors.green/
// Colors.orange snackbar backgrounds and icons with FTheme semantic tokens.
// No logic, state, or data-fetching changes.

import 'dart:typed_data';
// Material: this file uses a Material primitive with no ForUI equivalent.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/app/router.dart';
import 'package:mine_flow/core/network/google_drive_service.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/bloc/data_bucket_upload_cubit.dart';
import 'package:mine_flow/features/data_bucket/presentation/widgets/upload_progress_indicator.dart';
import 'package:mine_flow/features/daily_log/presentation/widgets/zone_picker.dart';
import 'package:mine_flow/features/zone/domain/repositories/zone_repository.dart';
import 'package:mine_flow/features/zone/presentation/bloc/zone_cubit.dart';
import 'package:mine_flow/main.dart';

const double _kPagePadding = 24;
const double _kSpacing8 = 8;
const double _kSpacing12 = 12;
const double _kSpacing16 = 16;
const double _kSpacing24 = 24;

// CF-078: cap file size before reading into memory.
const int _kMaxFileSizeMb = 50;
const int _kMaxFileSizeBytes = _kMaxFileSizeMb * 1024 * 1024;
const double _kCardRadius = 12;

/// Screen for uploading a geospatial file to the Data Bucket.
///
/// Provides a file picker, metadata form, zone selector, and upload progress
/// tracking. Supports offline fallback when Drive is unreachable.
class UploadFilePage extends StatelessWidget {
  final DataBucketRepository repository;
  final String siteId;
  final GoogleDriveService? driveService;
  final ZoneRepository? zoneRepository;
  final Uri? routeUri;
  final VoidCallback? onClose;

  const UploadFilePage({
    super.key,
    required this.repository,
    required this.siteId,
    this.driveService,
    this.zoneRepository,
    this.routeUri,
    this.onClose,
  });

  void _handleClose(BuildContext context) {
    if (onClose != null) {
      onClose!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.dataBucket);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Drive is optional for the current release. Keep the route usable when
    // its credentials are absent instead of crashing during navigation.
    final gDrive = driveService ?? appServices?.driveService;

    if (gDrive == null) {
      final theme = FTheme.of(context);
      return AppResponsiveSheet(
        routeIdentity: routeUri?.toString() ?? AppRoutes.dataBucketUpload,
        title: 'Upload File',
        subtitle: 'Penyimpanan data geospasial',
        mode: AppResponsiveSheetMode.form,
        onDismissApproved: () => _handleClose(context),
        footer: SizedBox(
          width: double.infinity,
          child: FButton(
            variant: FButtonVariant.outline,
            onPress: () => _handleClose(context),
            child: const Text('Kembali'),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(_kPagePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.cloudOff,
                  size: 48,
                  color: theme.colors.mutedForeground,
                ),
                const SizedBox(height: _kSpacing16),
                Text(
                  'Integrasi Google Drive belum dikonfigurasi.',
                  textAlign: TextAlign.center,
                  style: theme.typography.body.md,
                ),
                const SizedBox(height: _kSpacing8),
                Text(
                  'Upload file belum tersedia di lingkungan ini.',
                  textAlign: TextAlign.center,
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final zRepo = zoneRepository ?? appServices?.zoneRepository;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DataBucketUploadCubit(
            driveService: gDrive,
            repository: repository,
            siteId: siteId,
          ),
        ),
        if (zRepo != null)
          BlocProvider<ZoneCubit>(
            create: (_) => ZoneCubit(repository: zRepo)..loadZones(),
          ),
      ],
      child: _UploadFileForm(
        siteId: siteId,
        routeUri: routeUri,
        onClose: onClose,
      ),
    );
  }
}

class _UploadFileForm extends StatefulWidget {
  final String siteId;
  final Uri? routeUri;
  final VoidCallback? onClose;

  const _UploadFileForm({
    required this.siteId,
    this.routeUri,
    this.onClose,
  });

  @override
  State<_UploadFileForm> createState() => _UploadFileFormState();
}

class _UploadFileFormState extends State<_UploadFileForm> {
  // File picker state
  PlatformFile? _selectedFile;
  Uint8List? _fileBytes;
  int? _selectedFileSize;

  // Form fields
  String? _selectedZoneId;
  DateTime? _acquisitionDate;
  final _notesController = TextEditingController();

  // Validation
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      // Pick a single file
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const [
          'shp',
          'tiff',
          'tif',
          'dxf',
          'dwg',
          'csv',
          'kml',
          'kmz',
          'gpx',
          'pdf',
        ],
      );

      if (file == null) return;

      final size = await file.length();
      if (size > _kMaxFileSizeBytes) {
        if (mounted) {
          showFToast(
            context: context,
            variant: FToastVariant.destructive,
            title: const Text('File terlalu besar (maks $_kMaxFileSizeMb MB).'),
          );
        }
        return;
      }

      final bytes = await file.readAsBytes();

      if (mounted) {
        setState(() {
          _selectedFile = file;
          _fileBytes = bytes;
          _selectedFileSize = size;
        });
      }
    } catch (e) {
      if (mounted) {
        showFToast(
          context: context,
          variant: FToastVariant.destructive,
          title: Text('Gagal memilih file: ${e.toString()}'),
        );
      }
    }
  }

  bool get _isDirty =>
      _selectedFile != null ||
      _selectedZoneId != null ||
      _acquisitionDate != null ||
      _notesController.text.trim().isNotEmpty;

  void _handleClose(BuildContext context) {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.dataBucket);
    }
  }

  Future<void> _pickDate() async {
    final picked = await AppCalendarDialog.showSingle(
      context,
      initialDate: _acquisitionDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() {
        _acquisitionDate = picked;
      });
    }
  }

  Future<void> _handleCancelUpload(
    BuildContext context,
    double progress,
  ) async {
    // If bytes may already have transferred, confirm cancellation
    if (progress > 0) {
      final confirmed = await showFDialog<bool>(
        context: context,
        builder: (context, style, animation) => FDialog(
          builder: (context, style) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FAlert(
                variant: FAlertVariant.destructive,
                title: Text('Batalkan Unggahan?'),
                subtitle: Text(
                  'Sebagian berkas mungkin telah terkirim. Yakin ingin membatalkan proses unggah?',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.of(context).pop(false),
                    child: const Text('Lanjutkan Unggah'),
                  ),
                  FButton(
                    variant: FButtonVariant.destructive,
                    onPress: () => Navigator.of(context).pop(true),
                    child: const Text('Batalkan Unggahan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      if (confirmed != true) return;
    }

    if (context.mounted) {
      await context.read<DataBucketUploadCubit>().cancelUpload();
    }
  }

  Future<void> _submitUpload() async {
    if (!_formKey.currentState!.validate()) return;
    // CF-045: zone is required — the ZonePicker is not a FormField, so guard
    // explicitly.
    if (_selectedZoneId == null || _selectedZoneId!.isEmpty) {
      showFToast(
        context: context,
        variant: FToastVariant.destructive,
        title: const Text('Pilih zona terlebih dahulu.'),
      );
      return;
    }
    if (_selectedFile == null) {
      showFToast(
        context: context,
        title: const Text('Silakan pilih file terlebih dahulu.'),
      );
      return;
    }

    final bytes = _fileBytes;
    if (bytes == null || bytes.isEmpty) {
      showFToast(
        context: context,
        variant: FToastVariant.destructive,
        title: const Text('Gagal membaca file. Silakan coba lagi.'),
      );
      return;
    }

    final mimeType = _selectedFile!.extension != null
        ? _mimeTypeForExtension(_selectedFile!.extension!)
        : 'application/octet-stream';

    if (!mounted) return;

    final cubit = context.read<DataBucketUploadCubit>();

    await cubit.uploadFile(
      bytes: bytes,
      fileName: _selectedFile!.name,
      mimeType: mimeType,
      zoneId: _selectedZoneId,
      acquisitionDate: _acquisitionDate,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return BlocConsumer<DataBucketUploadCubit, UploadState>(
      listener: (context, state) {
        if (state is UploadSuccess) {
          showFToast(
            context: context,
            title: Text('File "${state.file.fileName}" berhasil diunggah!'),
          );
          _handleClose(context);
        } else if (state is UploadCancelled) {
          if (state.cleanupFailed) {
            showFToast(
              context: context,
              variant: FToastVariant.destructive,
              title: Text(
                'Unggahan dibatalkan, pembersihan Drive gagal: ${state.cleanupError ?? ""}',
              ),
            );
          } else {
            showFToast(
              context: context,
              title: const Text('Unggahan berhasil dibatalkan.'),
            );
          }
        } else if (state is UploadError) {
          showFToast(
            context: context,
            variant: FToastVariant.destructive,
            title: Text(state.message),
            suffixBuilder: (context, entry) => FButton(
              variant: FButtonVariant.outline,
              onPress: () {
                entry.dismiss();
                _submitUpload();
              },
              child: const Text('Coba Lagi'),
            ),
          );
        }
      },
      builder: (context, state) {
        final isUploading = state is UploadUploading;

        return AppResponsiveSheet(
          routeIdentity:
              widget.routeUri?.toString() ?? AppRoutes.dataBucketUpload,
          title: 'Upload File',
          subtitle: 'Penyimpanan data geospasial',
          mode: AppResponsiveSheetMode.form,
          isDirty: _isDirty,
          isBusy: isUploading,
          onDiscard: () {
            setState(() {
              _selectedFile = null;
              _fileBytes = null;
              _selectedFileSize = null;
              _selectedZoneId = null;
              _acquisitionDate = null;
              _notesController.clear();
            });
          },
          onDismissApproved: () => _handleClose(context),
          footer: SizedBox(
            width: double.infinity,
            child: isUploading
                ? FButton(
                    variant: FButtonVariant.destructive,
                    prefix: const Icon(LucideIcons.x, size: 18),
                    onPress: () => _handleCancelUpload(context, state.progress),
                    child: const Text('Batalkan Unggahan'),
                  )
                : FButton(
                    variant: FButtonVariant.primary,
                    onPress: _selectedFile == null ? null : _submitUpload,
                    prefix: const Icon(LucideIcons.upload, size: 18),
                    child: const Text('Upload ke Drive'),
                  ),
          ),
          body: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // File picker button
                _buildFilePickerSection(theme, isUploading),
                const SizedBox(height: _kSpacing24),

                // Metadata form
                Text('Metadata File', style: theme.typography.body.md),
                const SizedBox(height: _kSpacing12),

                // Zone picker
                Text(
                  'Zona *',
                  style: theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ZonePicker(
                  selectedZoneId: _selectedZoneId,
                  enabled: !isUploading,
                  onZoneSelected: (zoneId) {
                    setState(() {
                      _selectedZoneId = zoneId;
                    });
                  },
                ),
                const SizedBox(height: _kSpacing16),

                // Acquisition date
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Tanggal Akuisisi (opsional)',
                    style: theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FTappable(
                  onPress: isUploading ? null : _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colors.border),
                      borderRadius: BorderRadius.circular(_kCardRadius),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _acquisitionDate != null
                                ? DateFormat('yyyy-MM-dd')
                                    .format(_acquisitionDate!)
                                : 'Pilih tanggal',
                            style: theme.typography.body.md.copyWith(
                              color: _acquisitionDate != null
                                  ? theme.colors.foreground
                                  : theme.colors.mutedForeground,
                            ),
                          ),
                        ),
                        Icon(
                          LucideIcons.calendar,
                          size: 18,
                          color: theme.colors.mutedForeground,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: _kSpacing16),

                // Notes
                FTextField(
                  control: FTextFieldControl.managed(
                    controller: _notesController,
                  ),
                  enabled: !isUploading,
                  label: const Text('Catatan (opsional)'),
                  hint: 'Deskripsi file...',
                  maxLines: 3,
                ),
                const SizedBox(height: _kSpacing24),

                // Upload progress / status
                if (isUploading)
                  _buildUploadProgress(state)
                else if (state is UploadError)
                  _buildErrorCard(state.message, theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilePickerSection(FThemeData theme, bool isUploading) {
    return FTappable(
      onPress: isUploading ? null : _pickFile,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedFile != null
                ? theme.colors.primary
                : theme.colors.border,
          ),
          borderRadius: BorderRadius.circular(_kCardRadius),
        ),
        padding: const EdgeInsets.all(24),
        child: _selectedFile != null
            ? Column(
                children: [
                  Icon(
                    LucideIcons.file,
                    size: 40,
                    color: theme.colors.primary,
                  ),
                  const SizedBox(height: _kSpacing8),
                  Text(
                    _selectedFile!.name,
                    style: theme.typography.body.md.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedFileSize != null && _selectedFileSize! > 0)
                    Text(
                      _formatSize(_selectedFileSize!),
                      style: theme.typography.body.xs.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                ],
              )
            : Column(
                children: [
                  Icon(
                    LucideIcons.fileUp,
                    size: 48,
                    color: theme.colors.mutedForeground,
                  ),
                  const SizedBox(height: _kSpacing8),
                  const Text('Pilih File'),
                  const SizedBox(height: 4),
                  Text(
                    '.shp, .tiff, .dxf, .dwg, .csv, .kml, .gpx, .pdf',
                    style: theme.typography.body.xs.copyWith(
                      color: theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildUploadProgress(UploadUploading state) {
    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: UploadProgressIndicator(
          progress: state.progress,
          fileName: state.fileName,
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message, FThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.destructive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(LucideIcons.alertCircle, color: theme.colors.destructive),
            const SizedBox(width: _kSpacing12),
            Expanded(
              child: Text(
                message,
                style: theme.typography.body.md.copyWith(
                  color: theme.colors.destructive,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _mimeTypeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'shp':
        return 'application/x-esri-shapefile';
      case 'tiff':
      case 'tif':
        return 'image/tiff';
      case 'dxf':
        return 'application/dxf';
      case 'dwg':
        return 'application/acad';
      case 'csv':
        return 'text/csv';
      case 'kml':
        return 'application/vnd.google-earth.kml+xml';
      case 'kmz':
        return 'application/vnd.google-earth.kmz';
      case 'gpx':
        return 'application/gpx+xml';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
