import 'package:mine_flow/features/auth/domain/entities/user_entity.dart';

/// Abstract contract for authentication and user account management.
///
/// Follows Clean Architecture layer separation.
/// See Doc 16 — Identity & Auth for specifications.
abstract class AuthRepository {
  /// Authenticates user using email and password against Supabase Auth.
  /// Persists JWT tokens to secure storage.
  /// Throws [Failure] on error.
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Signs out the active user, revokes Supabase session, and clears secure storage.
  Future<void> signOut();

  /// Retrieves the currently authenticated user from active session or cached secure storage.
  /// Returns null if unauthenticated.
  Future<UserEntity?> getCurrentUser();

  /// Invokes `create-user` Edge Function to create a user account.
  /// Restricted to authenticated Supervisors.
  /// Throws [Failure] if caller is unauthorized or validation fails.
  Future<UserEntity> createUser({
    required String email,
    required String password,
    required String role,
    required String fullName,
    String? siteId,
    String? phone,
    String? nationalId,
    String? birthdate,
    String? gender,
    String? emergencyContactName,
    String? emergencyContactPhone,
  });

  /// Stream emitting user state changes (signed in, signed out, session refreshed).
  Stream<UserEntity?> get onAuthStateChanges;
}
