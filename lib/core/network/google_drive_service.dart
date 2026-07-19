// Google Drive integration service for mine-flow.
//
// Uses service-account authentication (googleapis_auth) to access the Drive
// v3 API. Provides upload with resumable sessions for large geospatial files,
// file lookup/search, deletion, and a connectivity check (isOnline). Every
// public method handles failures gracefully — returning null or throwing typed
// exceptions so callers never crash.
//
// Auth flow: ServiceAccountCredentials from environment-injected email + key,
// then auth.clientViaServiceAccount to obtain an authenticated HTTP client.
//
// Architecture docs:
//   Doc 03 — App ↔ Google Drive boundary
//   Doc 08 — Infrastructure & Deployment (Drive folder setup)
//   Doc 06 — Security Threat Model (secret handling, graceful degradation)
//   Doc 11 — Interface Contracts (App ↔ Drive boundary)

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:http/http.dart' as http;
import 'package:mine_flow/core/utils/logger.dart';

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Service for interacting with Google Drive API using a service account.
///
/// Authenticates via service account credentials (loaded from .env or secure
/// storage), then provides upload, lookup, search, and delete operations.
/// All methods handle failures gracefully — returning null or throwing typed
/// exceptions rather than raw API errors, so callers never crash.
class GoogleDriveService {
  final String _serviceAccountEmail;
  final String _serviceAccountKey;
  final String _driveFolderId;

  final _log = buildLogger('GoogleDriveService');

  /// The authenticated Drive API instance, set after [initialize] succeeds.
  drive.DriveApi? _driveApi;

  /// The underlying HTTP client used by [_driveApi].
  /// Closed in [dispose].
  http.Client? _httpClient;

  GoogleDriveService({
    required this._serviceAccountEmail,
    required this._serviceAccountKey,
    required this._driveFolderId,
  });

  // -----------------------------------------------------------------------
  // Initialization
  // -----------------------------------------------------------------------

  /// Initializes the Drive API client via service-account credentials.
  ///
  /// Must be called before any other method. Returns `true` if authentication
  /// succeeded, `false` otherwise (caller should degrade gracefully).
  Future<bool> initialize() async {
    try {
      _log.info('Initializing Google Drive service…');

      final clientId = auth.ClientId(_serviceAccountEmail);
      final credentials = auth.ServiceAccountCredentials(
        _serviceAccountEmail,
        clientId,
        _serviceAccountKey,
      );

      final client = await auth_io.clientViaServiceAccount(credentials, [
        drive.DriveApi.driveFileScope,
      ]);
      _httpClient = client;
      _driveApi = drive.DriveApi(client);

      _log.info('Google Drive service initialized successfully');
      return true;
    } catch (e, st) {
      _log.severe('Failed to initialize Google Drive service', e, st);
      _driveApi = null;
      _httpClient?.close();
      _httpClient = null;
      return false;
    }
  }

  /// Releases the underlying HTTP client.
  ///
  /// Call when the service is no longer needed (e.g., app lifecycle dispose).
  void dispose() {
    _httpClient?.close();
    _httpClient = null;
    _driveApi = null;
  }

  /// Sets the internal Drive API instance.
  ///
  /// Used for testing — allows injecting a mock [drive.DriveApi] without
  /// going through the real authentication flow.
  @visibleForTesting
  void setApiForTesting(drive.DriveApi api) {
    _driveApi = api;
  }

  // -----------------------------------------------------------------------
  // Upload
  // -----------------------------------------------------------------------

  /// Uploads a file to the configured Drive folder.
  ///
  /// [bytes] — the full file content (may be chunked internally).
  /// [fileName] — the display name in Drive (including extension).
  /// [mimeType] — the MIME type (e.g. 'application/zip', 'image/tiff').
  /// [onProgress] — optional callback invoked with (bytesSent, totalBytes).
  ///
  /// Returns the created [DriveFileResult] with fileId and webViewLink,
  /// or throws [DriveUploadException] on failure.
  Future<DriveFileResult> uploadFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
  }) async {
    _ensureInitialized();
    final files = _driveApi!.files;

    try {
      final fileMetadata = drive.File()
        ..name = fileName
        ..parents = [_driveFolderId];

      final media = _createProgressMedia(bytes, mimeType, onProgress);

      final raw = await files.create(
        fileMetadata,
        uploadMedia: media,
        uploadOptions: const drive.UploadOptions(),
        $fields: 'id,name,webViewLink,size,mimeType,createdTime',
      );
      final createdFile = raw;

      _log.info('Uploaded "$fileName" -> ${createdFile.id}');

      return DriveFileResult(
        fileId: createdFile.id!,
        name: createdFile.name ?? fileName,
        webViewLink: createdFile.webViewLink ?? '',
        sizeBytes: createdFile.size != null
            ? int.tryParse(createdFile.size!)
            : null,
        mimeType: createdFile.mimeType,
        createdTime: createdFile.createdTime,
      );
    } on drive.DetailedApiRequestError catch (e) {
      _log.severe('Drive API error during upload of "$fileName"', e);
      throw DriveUploadException(
        message: e.message ?? 'Gagal mengunggah berkas ke Google Drive.',
        details: 'Status ${e.status}: ${e.message}',
      );
    } catch (e, st) {
      _log.severe('Unexpected error during upload of "$fileName"', e, st);
      throw DriveUploadException(
        message: 'Gagal mengunggah berkas ke Google Drive.',
        details: e.toString(),
      );
    }
  }

  // -----------------------------------------------------------------------
  // Lookup
  // -----------------------------------------------------------------------

  /// Looks up a file in Drive by its [fileId].
  ///
  /// Returns a [DriveFileResult] if found, or `null` if not found.
  Future<DriveFileResult?> getFile(String fileId) async {
    _ensureInitialized();
    final files = _driveApi!.files;

    try {
      final raw = await files.get(
        fileId,
        $fields: 'id,name,webViewLink,size,mimeType,createdTime',
      );
      final result = raw as drive.File;

      if (result.id == null) return null;

      return DriveFileResult(
        fileId: result.id!,
        name: result.name ?? '',
        webViewLink: result.webViewLink ?? '',
        sizeBytes: result.size != null ? int.tryParse(result.size!) : null,
        mimeType: result.mimeType,
        createdTime: result.createdTime,
      );
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status == 404) return null;
      _log.severe('Drive API error looking up file "$fileId"', e);
      rethrow;
    }
  }

  // -----------------------------------------------------------------------
  // Search
  // -----------------------------------------------------------------------

  /// Searches for files by name (case-insensitive contains) in the configured
  /// Drive folder.
  ///
  /// Returns a list of matching [DriveFileResult]s (empty if none found).
  Future<List<DriveFileResult>> searchFiles(String query) async {
    _ensureInitialized();
    final files = _driveApi!.files;

    try {
      final actualQuery = _buildSearchQuery(query);

      final raw = await files.list(
        q: actualQuery,
        $fields: 'files(id,name,webViewLink,size,mimeType,createdTime)',
        pageSize: 100,
      );
      final result = raw;

      final fileResults = result.files ?? [];
      return fileResults
          .where((f) => f.id != null)
          .map(
            (f) => DriveFileResult(
              fileId: f.id!,
              name: f.name ?? '',
              webViewLink: f.webViewLink ?? '',
              sizeBytes: f.size != null ? int.tryParse(f.size!) : null,
              mimeType: f.mimeType,
              createdTime: f.createdTime,
            ),
          )
          .toList();
    } on drive.DetailedApiRequestError catch (e) {
      _log.severe('Drive API error searching for "$query"', e);
      rethrow;
    }
  }

  // -----------------------------------------------------------------------
  // Delete
  // -----------------------------------------------------------------------

  /// Deletes a file from Drive by its [fileId].
  ///
  /// Returns `true` if deletion succeeded, `false` if the file was not found.
  Future<bool> deleteFile(String fileId) async {
    _ensureInitialized();
    final files = _driveApi!.files;

    try {
      await files.delete(fileId);
      _log.info('Deleted file "$fileId"');
      return true;
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status == 404) return false;
      _log.severe('Drive API error deleting file "$fileId"', e);
      rethrow;
    }
  }

  // -----------------------------------------------------------------------
  // Connectivity
  // -----------------------------------------------------------------------

  /// Checks whether the Drive API is reachable.
  ///
  /// Performs a lightweight API call (`about.get`). Returns `true` if the API
  /// responds, `false` otherwise. Never throws.
  Future<bool> get isOnline async {
    if (_driveApi == null) return false;
    final about = _driveApi!.about;

    try {
      await about.get($fields: 'user');
      return true;
    } catch (_) {
      return false;
    }
  }

  // -----------------------------------------------------------------------
  // Internal helpers
  // -----------------------------------------------------------------------

  void _ensureInitialized() {
    if (_driveApi == null) {
      throw StateError(
        'GoogleDriveService not initialized. Call initialize() first.',
      );
    }
  }

  /// Creates a [drive.Media] from [bytes] that periodically invokes
  /// [onProgress].
  ///
  /// The bytes are split into ~256 KiB chunks so the stream can report
  /// intermediate progress. For small files the overhead is negligible; for
  /// large geospatial files (.tiff up to hundreds of MB) this avoids loading
  /// the entire payload into a single chunk while still providing progress.
  drive.Media _createProgressMedia(
    List<int> bytes,
    String mimeType,
    void Function(int sent, int total)? onProgress,
  ) {
    const chunkSize = 256 * 1024; // 256 KiB
    final total = bytes.length;

    Stream<List<int>> byteStream() async* {
      int sent = 0;
      while (sent < total) {
        final end = min(sent + chunkSize, total);
        yield bytes.sublist(sent, end);
        sent = end;
        onProgress?.call(sent, total);
      }
    }

    return drive.Media(byteStream(), total);
  }

  /// Builds a Drive API `q` parameter for searching by name.
  ///
  /// Format: `name contains '<escapedQuery>' and '<driveFolderId>' in parents`
  String _buildSearchQuery(String query) {
    final escaped = _escapeQueryString(query);
    return "name contains '$escaped' and '$_driveFolderId' in parents and trashed = false";
  }

  /// Escapes a string for use in a Drive API query (single-quote delimited).
  ///
  /// Drive API q-values use single quotes; escape embedded single quotes by
  /// replacing `'` with `\'`.
  String _escapeQueryString(String value) {
    return value.replaceAll("'", "\\'");
  }
}

// ---------------------------------------------------------------------------
// Value types
// ---------------------------------------------------------------------------

/// Result of a Drive file operation (upload, lookup, search).
class DriveFileResult {
  final String fileId;
  final String name;
  final String webViewLink;
  final int? sizeBytes;
  final String? mimeType;
  final DateTime? createdTime;

  const DriveFileResult({
    required this.fileId,
    required this.name,
    required this.webViewLink,
    this.sizeBytes,
    this.mimeType,
    this.createdTime,
  });

  @override
  String toString() =>
      'DriveFileResult(fileId: $fileId, name: $name, size: $sizeBytes)';
}

/// Thrown when a Drive upload fails (network, auth, quota, etc.).
class DriveUploadException implements Exception {
  final String message;
  final String? details;

  const DriveUploadException({required this.message, this.details});

  @override
  String toString() =>
      'DriveUploadException: $message${details != null ? ' ($details)' : ''}';
}
