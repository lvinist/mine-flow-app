import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mine_flow/core/network/google_drive_service.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/bloc/data_bucket_upload_cubit.dart';
import 'package:mine_flow/features/data_bucket/presentation/widgets/upload_progress_indicator.dart';

/// Screen for uploading a geospatial file to the Data Bucket.
///
/// Provides a file picker, metadata form, zone selector, and upload progress
/// tracking. Supports offline fallback when Drive is unreachable.
class UploadFilePage extends StatelessWidget {
  final DataBucketRepository repository;
  final String siteId;
  final GoogleDriveService? driveService;

  const UploadFilePage({
    super.key,
    required this.repository,
    required this.siteId,
    this.driveService,
  });

  @override
  Widget build(BuildContext context) {
    // For dependency injection, use a provided service or create a default one
    // from env values. In STEP-10, this will be wired via the DI container.
    final gDrive =
        driveService ??
        GoogleDriveService(
          serviceAccountEmail: '',
          serviceAccountKey: '',
          driveFolderId: '',
        );

    return BlocProvider(
      create: (_) => DataBucketUploadCubit(
        driveService: gDrive,
        repository: repository,
        siteId: siteId,
      ),
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
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  DateTime? _acquisitionDate;
  final _notesController = TextEditingController();

  // Validation
  final _formKey = GlobalKey<FormState>();

  // Available zones (hardcoded for now; will be loaded from repository in a future STEP)
  static const _availableZones = [
    'PIT Rusia',
    'Soil Bank Sochi',
    'Area Barat',
    'Area Timur',
  ];

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih file: ${e.toString()}'),
            backgroundColor: Colors.red,
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
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih file terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bytes = _fileBytes;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membaca file. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final mimeType = _selectedFile!.extension != null
        ? _mimeTypeForExtension(_selectedFile!.extension!)
        : 'application/octet-stream';

    final lat = double.tryParse(_latitudeController.text.trim());
    final lng = double.tryParse(_longitudeController.text.trim());

    if (!mounted) return;

    // Show offline warning if applicable
    final cubit = context.read<DataBucketUploadCubit>();

    await cubit.uploadFile(
      bytes: bytes,
      fileName: _selectedFile!.name,
      mimeType: mimeType,
      zoneId: _selectedZoneId,
      latitude: lat,
      longitude: lng,
      acquisitionDate: _acquisitionDate,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<DataBucketUploadCubit, UploadState>(
      listener: (context, state) {
        if (state is UploadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File "${state.file.fileName}" berhasil diunggah!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is UploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Coba Lagi',
                textColor: Colors.white,
                onPressed: _submitUpload,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isUploading = state is UploadUploading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Upload File Geospasial'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: isUploading ? null : () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // File picker button
                  _buildFilePickerSection(theme, isUploading),
                  const SizedBox(height: 24),

                  // Metadata form
                  Text('Metadata File', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),

                  // Zone dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedZoneId,
                    decoration: const InputDecoration(
                      labelText: 'Zona *',
                      border: OutlineInputBorder(),
                    ),
                    items: _availableZones
                        .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                        .toList(),
                    onChanged: isUploading
                        ? null
                        : (v) {
                            setState(() {
                              _selectedZoneId = v;
                            });
                          },
                    validator: (v) =>
                        v == null ? 'Pilih zona terlebih dahulu' : null,
                  ),
                  const SizedBox(height: 16),

                  // Latitude
                  TextFormField(
                    controller: _latitudeController,
                    enabled: !isUploading,
                    decoration: const InputDecoration(
                      labelText: 'Latitude (opsional)',
                      hintText: 'Contoh: -7.1234567',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Longitude
                  TextFormField(
                    controller: _longitudeController,
                    enabled: !isUploading,
                    decoration: const InputDecoration(
                      labelText: 'Longitude (opsional)',
                      hintText: 'Contoh: 112.3456789',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Acquisition date
                  InkWell(
                    onTap: isUploading ? null : _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Akuisisi (opsional)',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _acquisitionDate != null
                            ? '${_acquisitionDate!.year}-${_acquisitionDate!.month.toString().padLeft(2, '0')}-${_acquisitionDate!.day.toString().padLeft(2, '0')}'
                            : 'Pilih tanggal',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    enabled: !isUploading,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      hintText: 'Deskripsi file...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Upload progress / status
                  if (isUploading)
                    _buildUploadProgress(state)
                  else if (state is UploadError)
                    _buildErrorCard(state.message, theme),

                  // Submit button
                  if (!isUploading)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Upload ke Drive'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _selectedFile == null ? null : _submitUpload,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilePickerSection(ThemeData theme, bool isUploading) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedFile != null
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isUploading ? null : _pickFile,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _selectedFile != null
              ? Column(
                  children: [
                    Icon(
                      Icons.insert_drive_file,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFile!.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    if (_selectedFile!.size > 0)
                      Text(
                        _formatSize(_selectedFile!.size),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                )
              : Column(
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 48,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(height: 8),
                    const Text('Pilih File'),
                    const SizedBox(height: 4),
                    Text(
                      '.shp, .tiff, .dxf, .dwg, .csv, .kml, .gpx, .pdf',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress(UploadUploading state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: UploadProgressIndicator(
          progress: state.progress,
          fileName: state.fileName,
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message, ThemeData theme) {
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
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
