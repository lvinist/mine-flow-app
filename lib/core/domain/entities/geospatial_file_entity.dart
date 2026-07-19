import 'package:equatable/equatable.dart';

/// Domain entity representing heavy geospatial file metadata linked to Google Drive.
///
/// Follows Doc 04 — Data Model, Ownership & Retention.
class GeospatialFileEntity extends Equatable {
  final String id;
  final String siteId;
  final String? zoneId;
  final String fileName;
  final String fileType; // '.shp', '.tiff', etc.
  final String driveFileId;
  final String? driveWebViewLink;
  final DateTime? acquisitionDate;
  final String? uploadedBy;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const GeospatialFileEntity({
    required this.id,
    required this.siteId,
    this.zoneId,
    required this.fileName,
    required this.fileType,
    required this.driveFileId,
    this.driveWebViewLink,
    this.acquisitionDate,
    this.uploadedBy,
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
        id,
        siteId,
        zoneId,
        fileName,
        fileType,
        driveFileId,
        driveWebViewLink,
        acquisitionDate,
        uploadedBy,
        metadata,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
