import 'package:equatable/equatable.dart';
import 'package:mine_flow/features/auth/domain/entities/user_entity.dart';

/// Authentication lifecycle status for the [AuthCubit].
enum AuthStatus {
  /// Auth state has not yet been resolved (startup).
  unknown,

  /// A user is signed in.
  authenticated,

  /// No user is signed in.
  unauthenticated,
}

/// Immutable authentication state emitted by [AuthCubit].
class AuthState extends Equatable {
  /// Current lifecycle status.
  final AuthStatus status;

  /// The signed-in user, or null when unauthenticated/unknown.
  final UserEntity? user;

  /// Whether a sign-in request is in flight.
  final bool isSubmitting;

  /// Human-readable error from the last failed sign-in, if any.
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// Whether the app currently has a signed-in user.
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Copies this state, replacing only the provided fields.
  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, isSubmitting, errorMessage];
}
