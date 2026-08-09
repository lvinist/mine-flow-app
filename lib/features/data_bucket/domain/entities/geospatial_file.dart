import 'package:equatable/equatable.dart';

/// Domain entity representing a geospatial file (survey data) stored on Google Drive.
///
/// Follows Doc 04 — Data Model, Ownership & Retention.
/// This is the feature-scoped entity for the Data Bucket domain,
/// extending the core entity definition with Data Bucket-specific fields.
class GeospatialFile extends Equatable {
  final String id;
  final String siteId;
  final String? zoneId;
  final String fileName;
  // Allowed values: '.shp', '.tiff', '.tif', '.dxf', '.dwg', '.csv', '.kml', '.kmz', '.gpx', '.pdf', 'other'
  final String fileType;
  final String? mimeType;
  final String driveFileId;
  final String driveLink;
  final int? fileSizeBytes;
  final DateTime? acquisitionDate;
  final String? notes;
  final String? uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GeospatialFile({
    required this.id,
    required this.siteId,
    this.zoneId,
    required this.fileName,
    required this.fileType,
    this.mimeType,
    required this.driveFileId,
    required this.driveLink,
    this.fileSizeBytes,
    this.acquisitionDate,
    this.notes,
    this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this [GeospatialFile] with the given fields replaced.
  GeospatialFile copyWith({
    String? id,
    String? siteId,
    String? zoneId,
    String? fileName,
    String? fileType,
    String? mimeType,
    String? driveFileId,
    String? driveLink,
    int? fileSizeBytes,
    DateTime? acquisitionDate,
    String? notes,
    String? uploadedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GeospatialFile(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      zoneId: zoneId ?? this.zoneId,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      mimeType: mimeType ?? this.mimeType,
      driveFileId: driveFileId ?? this.driveFileId,
      driveLink: driveLink ?? this.driveLink,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      acquisitionDate: acquisitionDate ?? this.acquisitionDate,
      notes: notes ?? this.notes,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    siteId,
    zoneId,
    fileName,
    fileType,
    mimeType,
    driveFileId,
    driveLink,
    fileSizeBytes,
    acquisitionDate,
    notes,
    uploadedBy,
    createdAt,
    updatedAt,
  ];
}
