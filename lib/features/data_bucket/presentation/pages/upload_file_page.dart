// Upload File Page — geospatial file upload form in ForUI aesthetic.
//
// Phase 2 Tier 2 rebuild (STEP-30.4): Replaced hardcoded Colors.red/Colors.green/
// Colors.orange snackbar backgrounds and icons with FTheme semantic tokens.
// No logic, state, or data-fetching changes.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:mine_flow/core/network/google_drive_service.dart';
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

  const UploadFilePage({
    super.key,
    required this.repository,
    required this.siteId,
    this.driveService,
    this.zoneRepository,
  });

  @override
  Widget build(BuildContext context) {
    // CF-018: resolve the Drive service from DI / app services; throw when
    // unwired rather than fabricating an empty-credential client.
    final gDrive =
        driveService ??
        appServices?.driveService ??
        (throw UnimplementedError(
          'GoogleDriveService not wired and no driveService provided.',
        ));

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
      child: _UploadFileForm(siteId: siteId),
    );
  }
}

class _UploadFileForm extends StatefulWidget {
  final String siteId;

  const _UploadFileForm({required this.siteId});

  @override
  State<_UploadFileForm> createState() => _UploadFileFormState();
}

class _UploadFileFormState extends State<_UploadFileForm> {
  // File picker state
  PlatformFile? _selectedFile;
  List<int>? _fileBytes;

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
      // CF-078: pass 1 reads metadata only so we can enforce a size cap before
      // loading the whole file into memory.
      final meta = await FilePicker.pickFiles(
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
        withData: false,
      );

      if (meta == null || meta.files.isEmpty) return;

      if (meta.files.first.size > _kMaxFileSizeBytes) {
        if (mounted) {
          final theme = FTheme.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'File terlalu besar (maks $_kMaxFileSizeMb MB).',
              ),
              backgroundColor: theme.colors.destructive,
            ),
          );
        }
        return;
      }

      final result = await FilePicker.pickFiles(
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
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _fileBytes = _selectedFile!.bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        final theme = FTheme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih file: ${e.toString()}'),
            backgroundColor: theme.colors.destructive,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _acquisitionDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _acquisitionDate = picked;
      });
    }
  }

  Future<void> _submitUpload() async {
    if (!_formKey.currentState!.validate()) return;
    // CF-045: zone is required — the ZonePicker is not a FormField, so guard
    // explicitly.
    if (_selectedZoneId == null || _selectedZoneId!.isEmpty) {
      final theme = FTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih zona terlebih dahulu.'),
          backgroundColor: theme.colors.destructive,
        ),
      );
      return;
    }
    if (_selectedFile == null) {
      final theme = FTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan pilih file terlebih dahulu.'),
          backgroundColor: theme.colors.mutedForeground,
        ),
      );
      return;
    }

    final bytes = _fileBytes;
    if (bytes == null || bytes.isEmpty) {
      final theme = FTheme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal membaca file. Silakan coba lagi.'),
          backgroundColor: theme.colors.destructive,
        ),
      );
      return;
    }

    final mimeType = _selectedFile!.extension != null
        ? _mimeTypeForExtension(_selectedFile!.extension!)
        : 'application/octet-stream';

    if (!mounted) return;

    // Show offline warning if applicable
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
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return BlocConsumer<DataBucketUploadCubit, UploadState>(
      listener: (context, state) {
        if (state is UploadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File "${state.file.fileName}" berhasil diunggah!'),
              backgroundColor: theme.colors.primary,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is UploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colors.destructive,
              action: SnackBarAction(
                label: 'Coba Lagi',
                textColor: theme.colors.primaryForeground,
                onPressed: _submitUpload,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isUploading = state is UploadUploading;

        return Scaffold(
          appBar: isDesktop
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: FHeader.nested(
                    title: Semantics(
                      header: true,
                      child: Text(
                        'Upload File',
                        style: theme.typography.display.sm.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    prefixes: [
                      FButton(
                        variant: FButtonVariant.ghost,
                        onPress: isUploading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Icon(LucideIcons.arrowLeft),
                      ),
                    ],
                  ),
                ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(_kPagePadding),
            child: Form(
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

                  // Zone picker (CF-045: required label always visible in the
                  // editable state, not just while uploading)
                  Text(
                    'Zona *',
                    style: theme.typography.body.sm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ZonePicker(
                    selectedZoneId: _selectedZoneId,
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
                  InkWell(
                    onTap: isUploading ? null : _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_kCardRadius),
                        ),
                        suffixIcon: const Icon(LucideIcons.calendar),
                      ),
                      child: Text(
                        _acquisitionDate != null
                            ? DateFormat('yyyy-MM-dd').format(_acquisitionDate!)
                            : 'Pilih tanggal',
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

                  // Submit button
                  if (!isUploading)
                    FButton(
                      // CF-076: primary variant + theme foreground tokens so the
                      // disabled state is legible (was a hardcoded light label on
                      // a grey disabled block).
                      variant: FButtonVariant.primary,
                      onPress: _selectedFile == null ? null : _submitUpload,
                      prefix: const Icon(LucideIcons.upload, size: 18),
                      child: const Text('Upload ke Drive'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilePickerSection(FThemeData theme, bool isUploading) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedFile != null
              ? theme.colors.primary
              : theme.colors.border,
        ),
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      child: InkWell(
        onTap: isUploading ? null : _pickFile,
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: Padding(
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
                    if (_selectedFile!.size > 0)
                      Text(
                        _formatSize(_selectedFile!.size),
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
