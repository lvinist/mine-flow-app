// Base failure types for the mine-flow domain layer.
//
// Clean Architecture pattern: use cases and repositories return Failure
// subtypes (not raw exceptions) so the presentation layer can map them to
// user-friendly messages without knowing the underlying cause.

/// Abstract base class for all domain-layer failures.
abstract class Failure {
  /// Human-readable message. May be shown in error states.
  final String message;

  const Failure(this.message);
}

/// The device has no internet connection and the operation cannot be completed
/// from local cache alone.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Tidak ada koneksi internet. Coba lagi nanti.',
  ]);
}

/// Supabase returned an error (auth failure, RLS violation, server error).
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Terjadi kesalahan pada server.']);
}

/// A requested record was not found in local cache or the remote database.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Data tidak ditemukan.']);
}

/// The user does not have permission to perform the requested action.
/// Tied to RBAC/RLS enforcement (see Doc 16 — Identity & Auth, §4).
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Anda tidak memiliki izin untuk melakukan tindakan ini.',
  ]);
}

/// The provided input data failed validation before being sent to the server.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// An unexpected failure that does not fit any of the above categories.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Terjadi kesalahan yang tidak terduga.']);
}
