import 'package:equatable/equatable.dart';

/// Domain entity representing a Mine Flow user account.
///
/// Follows Doc 04 & Doc 16 (Identity & Auth).
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String role; // 'supervisor' | 'foreman' | 'crew'
  final String siteId;
  final String? phone;
  final String? nationalId;
  final DateTime? birthdate;
  final String? gender;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.siteId,
    this.phone,
    this.nationalId,
    this.birthdate,
    this.gender,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Helper getter to check if user is a Supervisor.
  bool get isSupervisor => role == 'supervisor';

  /// Helper getter to check if user is a Foreman.
  bool get isForeman => role == 'foreman';

  /// Helper getter to check if user is Crew.
  bool get isCrew => role == 'crew';

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        role,
        siteId,
        phone,
        nationalId,
        birthdate,
        gender,
        emergencyContactName,
        emergencyContactPhone,
        isActive,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
