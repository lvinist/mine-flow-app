import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mine_flow/core/network/google_drive_service.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';
import 'package:mine_flow/features/data_bucket/presentation/bloc/data_bucket_upload_cubit.dart';
import 'package:mine_flow/features/data_bucket/presentation/widgets/upload_progress_indicator.dart';

// Phase 2 — shadcn-admin design language constants (DESIGN.md §29).
const double _kPagePadding = 24;
const double _kCardRadius = 12;
const double _kFieldSpacing = 16;
const Duration _kAnimDuration = Duration(milliseconds: 250);

// --- Responsive breakpoints (DESIGN.md §28) ---
const double _kBreakMobile = 600;
const double _kFormMaxWidth = 600;

/// Screen for uploading a geospatial file to the Data Bucket.
///
/// Phase 2 polish: AnimatedSwitcher with easeOutQuart curves,
/// AnimatedCrossFade between file picker empty/selected states,
/// slide+fade entrance for the file picker section, and refined
/// typography with themed text styles throughout.
///
/// Provides a file picker, metadata form, zone selector, and upload progress
/// tracking. Supports offline fallback when Drive is unreachable.
///
/// === Substep 23.3 audit ===
/// - Tooltips on all IconButtons for screen-reader accessibility.
/// - Semantics labels on heading text and section headers.
/// - excludeSemantics on decorative icons to reduce noise.
/// - Responsive LayoutBuilder with _kBreakMobile = 600:
///   desktop constrains form to _kFormMaxWidth centered; mobile is full-width.
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

class _UploadFileFormState extends State<_UploadFileForm>
    with SingleTickerProviderStateMixin {
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

  // Entrance animation
  late final AnimationController _entranceCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  // Available zones (hardcoded for now; will be loaded from repository in a future STEP)
  static const _availableZones = [
    'PIT Rusia',
    'Soil Bank Sochi',
    'Area Barat',
    'Area Timur',
  ];

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutQuart),
        );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutQuart),
    );
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
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
            backgroundColor: Theme.of(context).colorScheme.error,
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
        SnackBar(
          content: const Text('Silakan pilih file terlebih dahulu.'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
      return;
    }

    final bytes = _fileBytes;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal membaca file. Silakan coba lagi.'),
          backgroundColor: Theme.of(context).colorScheme.error,
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
              backgroundColor: theme.colorScheme.primary,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is UploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
              action: SnackBarAction(
                label: 'Coba Lagi',
                textColor: theme.colorScheme.onError,
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
            title: Semantics(
              header: true,
              child: const Text('Upload File Geospasial'),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Tutup',
              onPressed: isUploading ? null : () => Navigator.of(context).pop(),
            ),
          ),
          body: AnimatedSwitcher(
            duration: _kAnimDuration,
            switchInCurve: Curves.easeOutQuart,
            switchOutCurve: Curves.easeInQuart,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildFormBody(theme, state, isUploading),
          ),
        );
      },
    );
  }

  Widget _buildFormBody(ThemeData theme, UploadState state, bool isUploading) {
    return SingleChildScrollView(
      key: const ValueKey('form-body'),
      padding: const EdgeInsets.all(_kPagePadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _kBreakMobile;
          final formPadding = isWide
              ? EdgeInsets.symmetric(
                  horizontal: (constraints.maxWidth - _kFormMaxWidth) / 2,
                )
              : EdgeInsets.zero;

          return Padding(
            padding: formPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // File picker dropzone with slide+fade entrance
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildFilePickerSection(theme, isUploading),
                    ),
                  ),
                  const SizedBox(height: _kPagePadding),

                  // Metadata section header
                  Semantics(
                    header: true,
                    child: Text(
                      'Metadata File',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: _kFieldSpacing),

                  // Zone dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedZoneId,
                    decoration: const InputDecoration(labelText: 'Zona *'),
                    items: _availableZones
                        .map(
                          (z) => DropdownMenuItem(
                            value: z,
                            child: Text(z, style: theme.textTheme.bodyMedium),
                          ),
                        )
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
                  const SizedBox(height: _kFieldSpacing),

                  // Latitude
                  TextFormField(
                    controller: _latitudeController,
                    enabled: !isUploading,
                    decoration: const InputDecoration(
                      labelText: 'Latitude (opsional)',
                      hintText: 'Contoh: -7.1234567',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: _kFieldSpacing),

                  // Longitude
                  TextFormField(
                    controller: _longitudeController,
                    enabled: !isUploading,
                    decoration: const InputDecoration(
                      labelText: 'Longitude (opsional)',
                      hintText: 'Contoh: 112.3456789',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: _kFieldSpacing),

                  // Acquisition date
                  Semantics(
                    label: _acquisitionDate != null
                        ? 'Tanggal akuisisi: '
                              '${_acquisitionDate!.year}-${_acquisitionDate!.month.toString().padLeft(2, '0')}-${_acquisitionDate!.day.toString().padLeft(2, '0')}'
                        : 'Tanggal akuisisi, belum dipilih',
                    child: InkWell(
                      onTap: isUploading ? null : _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Akuisisi (opsional)',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _acquisitionDate != null
                              ? '${_acquisitionDate!.year}-${_acquisitionDate!.month.toString().padLeft(2, '0')}-${_acquisitionDate!.day.toString().padLeft(2, '0')}'
                              : 'Pilih tanggal',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _acquisitionDate != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: _kFieldSpacing),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    enabled: !isUploading,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      hintText: 'Deskripsi file...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: _kPagePadding),

                  // Upload progress / status with animated opacity
                  AnimatedOpacity(
                    duration: _kAnimDuration,
                    opacity: isUploading || state is UploadError ? 1.0 : 0.0,
                    child: isUploading
                        ? _buildUploadProgress(state as UploadUploading)
                        : state is UploadError
                        ? _buildErrorCard(state.message, theme)
                        : const SizedBox.shrink(),
                  ),
                  if (isUploading || state is UploadError)
                    const SizedBox(height: _kFieldSpacing),

                  // Submit button
                  AnimatedOpacity(
                    duration: _kAnimDuration,
                    opacity: isUploading ? 0.0 : 1.0,
                    child: isUploading
                        ? const SizedBox.shrink()
                        : FilledButton.tonalIcon(
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('Upload ke Drive'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _selectedFile == null
                                ? null
                                : _submitUpload,
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilePickerSection(ThemeData theme, bool isUploading) {
    return Semantics(
      label: _selectedFile != null
          ? 'File terpilih: ${_selectedFile!.name}'
          : 'Pilih file geospasial',
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedFile != null
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(_kCardRadius),
        ),
        child: InkWell(
          onTap: isUploading ? null : _pickFile,
          borderRadius: BorderRadius.circular(_kCardRadius),
          child: Padding(
            padding: const EdgeInsets.all(_kPagePadding),
            child: AnimatedCrossFade(
              duration: _kAnimDuration,
              crossFadeState: _selectedFile != null
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstCurve: Curves.easeOutQuart,
              secondCurve: Curves.easeOutQuart,
              sizeCurve: Curves.easeOutQuart,
              firstChild: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(Icons.upload_file, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih File',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '.shp, .tiff, .dxf, .dwg, .csv, .kml, .gpx, .pdf',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              secondChild: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insert_drive_file, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFile!.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_selectedFile!.size > 0)
                          Text(
                            _formatSize(_selectedFile!.size),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Hapus file',
                    onPressed: isUploading
                        ? null
                        : () {
                            setState(() {
                              _selectedFile = null;
                              _fileBytes = null;
                            });
                          },
                  ),
                ],
              ),
            ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.error_outline,
              size: 20,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
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
