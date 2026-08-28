import 'package:mine_flow/core/error/failures.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/auth/data/models/user_model.dart';
import 'package:mine_flow/features/auth/domain/entities/user_entity.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementation of [AuthRepository] interacting with Supabase Auth,
/// Supabase Edge Functions, and encrypted [SecureStorageService].
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabaseClient;
  final SecureStorageService secureStorageService;

  AuthRepositoryImpl({
    required this.supabaseClient,
    required this.secureStorageService,
  });

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await supabaseClient.auth
          .signInWithPassword(email: email, password: password);

      if (response.session == null || response.user == null) {
        throw const ServerFailure('Sesi otentikasi tidak valid.');
      }

      // Persist token and initial user metadata
      await secureStorageService.saveSessionData(
        userId: response.user!.id,
        role: response.user!.userMetadata?['role'] as String? ?? 'crew',
        token: response.session!.accessToken,
        refreshToken: response.session!.refreshToken,
      );

      // Fetch user profile from public.users table
      final Map<String, dynamic> profileData = await supabaseClient
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      final userModel = UserModel.fromJson(profileData);

      // Update stored session data with DB role and site_id
      await secureStorageService.saveSessionData(
        userId: userModel.id,
        role: userModel.role,
        siteId: userModel.siteId,
      );

      return userModel.toEntity();
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw const ServerFailure('Email atau kata sandi salah.');
      }
      throw ServerFailure(e.message);
    } on PostgrestException catch (e) {
      throw ServerFailure('Gagal memuat profil pengguna: ${e.message}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Terjadi kesalahan saat masuk: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (_) {
      // Best-effort remote sign out
    } finally {
      await secureStorageService.clearAll();
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final session = supabaseClient.auth.currentSession;
      if (session != null) {
        final Map<String, dynamic> profileData = await supabaseClient
            .from('users')
            .select()
            .eq('id', session.user.id)
            .single();
        return UserModel.fromJson(profileData).toEntity();
      }

      // Try fallback from secure storage
      final sessionData = await secureStorageService.getSessionData();
      final userId = sessionData['userId'];
      if (userId != null && userId.isNotEmpty) {
        final Map<String, dynamic> profileData = await supabaseClient
            .from('users')
            .select()
            .eq('id', userId)
            .single();
        return UserModel.fromJson(profileData).toEntity();
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  @override
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
  }) async {
    try {
      final FunctionResponse response = await supabaseClient.functions.invoke(
        'create-user',
        body: {
          'email': email,
          'password': password,
          'role': role,
          'name': fullName,
          'site_id': ?siteId,
          'phone': ?phone,
          'national_id': ?nationalId,
          'birthdate': ?birthdate,
          'gender': ?gender,
          'emergency_contact_name': ?emergencyContactName,
          'emergency_contact_phone': ?emergencyContactPhone,
        },
      );

      if (response.status != 201 && response.status != 200) {
        final data = response.data;
        final errorMessage = (data is Map && data.containsKey('error'))
            ? data['error'].toString()
            : 'Gagal membuat akun pengguna.';
        if (response.status == 403) {
          throw UnauthorizedFailure(errorMessage);
        }
        throw ServerFailure(errorMessage);
      }

      final data = response.data;
      if (data is Map && data.containsKey('user')) {
        final userMap = Map<String, dynamic>.from(data['user'] as Map);
        return UserModel.fromJson(userMap).toEntity();
      }

      throw const ServerFailure('Format balasan server tidak valid.');
    } on FunctionException catch (e) {
      throw ServerFailure(
        'Gagal memanggil fungsi server: ${e.details ?? e.status}',
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(
        'Terjadi kesalahan saat membuat akun: ${e.toString()}',
      );
    }
  }

  @override
  Stream<UserEntity?> get onAuthStateChanges {
    return supabaseClient.auth.onAuthStateChange.asyncMap((data) async {
      final session = data.session;
      if (session == null) {
        return null;
      }
      try {
        final Map<String, dynamic> profileData = await supabaseClient
            .from('users')
            .select()
            .eq('id', session.user.id)
            .single();
        return UserModel.fromJson(profileData).toEntity();
      } catch (_) {
        return null;
      }
    });
  }
}
