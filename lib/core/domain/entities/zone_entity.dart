import 'package:equatable/equatable.dart';

/// Domain entity representing a site Zone (e.g., PIT Rusia, Soil Bank Sochi).
///
/// Follows Doc 04 — Data Model, Ownership & Retention.
class ZoneEntity extends Equatable {
  final String id;
  final String siteId;
  final String name;
  final String? category;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const ZoneEntity({
    required this.id,
    required this.siteId,
    required this.name,
    this.category,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
        id,
        siteId,
        name,
        category,
        description,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
