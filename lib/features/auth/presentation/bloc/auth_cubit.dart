import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mine_flow/core/error/failures.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_state.dart';

/// Global auth revision signal the router listens to so it re-evaluates its
/// redirect whenever the session changes.
///
/// Kept as a [ValueNotifier] (not the cubit itself) so the router can attach a
/// [Listenable] at construction time, before the cubit exists.
final ValueNotifier<int> authRevision = ValueNotifier<int>(0);

/// Process-wide [AuthCubit], set during startup in `main.dart` and consumed by
/// the router redirect and [MineFlowApp].
AuthCubit? authCubit;

/// Manages authentication state for the whole app.
///
/// Wraps [AuthRepository] so the presentation layer (login page, router
/// redirect, settings profile/logout) observes one source of truth for the
/// signed-in user.
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit({required this.repository}) : super(const AuthState());

  /// Resolves the current session on startup.
  ///
  /// Emits [AuthStatus.authenticated] if a user session exists (Supabase or
  /// cached secure storage), otherwise [AuthStatus.unauthenticated].
  Future<void> initialize() async {
    try {
      final user = await repository.getCurrentUser();
      emit(
        AuthState(
          status: user != null
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
          user: user,
        ),
      );
    } catch (_) {
      // Any failure resolving the session is treated as signed-out.
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
    authRevision.value++;
  }

  /// Signs in with [email]/[password]; on failure emits an [errorMessage].
  Future<void> signIn({required String email, required String password}) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    try {
      final user = await repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on Failure catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Terjadi kesalahan saat masuk.',
        ),
      );
    }
    authRevision.value++;
  }

  /// Signs out, clears the session, and emits unauthenticated.
  Future<void> signOut() async {
    await repository.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
    authRevision.value++;
  }
}
