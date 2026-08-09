import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mine_flow/core/network/google_drive_service.dart';
import 'package:mine_flow/features/data_bucket/domain/entities/geospatial_file.dart';
import 'package:mine_flow/features/data_bucket/domain/repositories/data_bucket_repository.dart';

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

/// Abstract base for upload states.
abstract class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object?> get props => [];
}

/// Cubit is idle, ready for a new upload.
class UploadIdle extends UploadState {
  const UploadIdle();
}

/// File picker is open (user is selecting a file).
class UploadPickingFile extends UploadState {
  const UploadPickingFile();
}

/// File is being uploaded to Drive.
class UploadUploading extends UploadState {
  final double progress; // 0.0 to 1.0
  final String fileName;

  const UploadUploading({required this.progress, required this.fileName});

  @override
  List<Object?> get props => [progress, fileName];
}

/// Upload completed successfully.
class UploadSuccess extends UploadState {
  final GeospatialFile file;

  const UploadSuccess(this.file);

  @override
  List<Object?> get props => [file];
}

/// Upload failed with an error message.
class UploadError extends UploadState {
  final String message;

  const UploadError(this.message);

  @override
  List<Object?> get props => [message];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

/// Cubit managing the single-file upload flow for the Data Bucket feature.
///
/// Handles picking a file, uploading to Google Drive, saving metadata to
/// Supabase, and falling back to offline mode when Drive is unreachable.
class DataBucketUploadCubit extends Cubit<UploadState> {
  final GoogleDriveService _driveService;
  final DataBucketRepository _repository;
  final String _siteId;

  DataBucketUploadCubit({
    required this._driveService,
    required this._repository,
    required this._siteId,
  }) : super(const UploadIdle());

  /// Uploads a file along with its metadata.
  ///
  /// [bytes] — raw file content.
  /// [fileName] — display name with extension.
  /// [mimeType] — MIME type of the file.
  /// [zoneId] — optional zone identifier.
  /// [acquisitionDate] — optional date the file was acquired.
  /// [notes] — optional description.
  /// [uploadedBy] — optional uploader identifier.
  Future<void> uploadFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    String? zoneId,
    DateTime? acquisitionDate,
    String? notes,
    String? uploadedBy,
  }) async {
    emit(UploadUploading(progress: 0.0, fileName: fileName));

    try {
      // Attempt to initialize Drive if not yet done.
      // initialize() is idempotent for our purposes — it re-initializes.
      final driveReady = await _driveService.initialize();

      if (driveReady) {
        final online = await _driveService.isOnline;

        if (online) {
          // --- Online path: upload to Drive, then save metadata ---
          emit(UploadUploading(progress: 0.0, fileName: fileName));

          final driveResult = await _driveService.uploadFile(
            bytes: bytes,
            fileName: fileName,
            mimeType: mimeType,
            onProgress: (sent, total) {
              final progress = total > 0 ? sent / total : 0.0;
              emit(UploadUploading(progress: progress, fileName: fileName));
            },
          );

          emit(UploadUploading(progress: 1.0, fileName: fileName));

          final now = DateTime.now();
          final file = GeospatialFile(
            id: '', // Will be assigned by Supabase
            siteId: _siteId,
            zoneId: zoneId,
            fileName: fileName,
            fileType: _inferFileType(fileName),
            mimeType: mimeType,
            driveFileId: driveResult.fileId,
            driveLink: driveResult.webViewLink,
            fileSizeBytes: driveResult.sizeBytes ?? bytes.length,
            acquisitionDate: acquisitionDate,
            notes: notes,
            uploadedBy: uploadedBy,
            createdAt: now,
            updatedAt: now,
          );

          final saved = await _repository.saveFile(file);
          emit(UploadSuccess(saved));
        } else {
          // --- Offline path (Drive unreachable): save metadata only ---
          await _saveOffline(
            bytes: bytes,
            fileName: fileName,
            mimeType: mimeType,
            zoneId: zoneId,
            acquisitionDate: acquisitionDate,
            notes: notes,
            uploadedBy: uploadedBy,
          );
        }
      } else {
        // --- Drive init failed: save offline ---
        await _saveOffline(
          bytes: bytes,
          fileName: fileName,
          mimeType: mimeType,
          zoneId: zoneId,
          acquisitionDate: acquisitionDate,
          notes: notes,
          uploadedBy: uploadedBy,
        );
      }
    } on DriveUploadException catch (e) {
      emit(UploadError(e.message));
    } catch (e) {
      emit(UploadError('Gagal mengunggah file: ${e.toString()}'));
    }
  }

  /// Resets the cubit back to idle state.
  void reset() {
    emit(const UploadIdle());
  }

  // -----------------------------------------------------------------------
  // Private helpers
  // -----------------------------------------------------------------------

  /// Saves file metadata locally (offline mode) without uploading to Drive.
  ///
  /// The file will be queued for sync by [DataBucketRepository.syncPendingUploads]
  /// when connectivity is restored.
  Future<void> _saveOffline({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    String? zoneId,
    DateTime? acquisitionDate,
    String? notes,
    String? uploadedBy,
  }) async {
    final now = DateTime.now();
    final file = GeospatialFile(
      id: '', // Will be assigned locally / during sync
      siteId: _siteId,
      zoneId: zoneId,
      fileName: fileName,
      fileType: _inferFileType(fileName),
      mimeType: mimeType,
      driveFileId: '',
      driveLink: '',
      fileSizeBytes: bytes.length,
      acquisitionDate: acquisitionDate,
      notes: notes,
      uploadedBy: uploadedBy,
      createdAt: now,
      updatedAt: now,
    );

    final saved = await _repository.saveFile(file);
    emit(UploadSuccess(saved));
  }

  /// Infers the file type extension from [fileName].
  static String _inferFileType(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return 'other';
    final ext = fileName.substring(dot).toLowerCase();
    const known = [
      '.shp',
      '.tiff',
      '.tif',
      '.dxf',
      '.dwg',
      '.csv',
      '.kml',
      '.kmz',
      '.gpx',
      '.pdf',
    ];
    return known.contains(ext) ? ext : 'other';
  }
}
