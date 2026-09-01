import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_flow/core/error/failures.dart';
import 'package:mine_flow/core/security/secure_storage_service.dart';
import 'package:mine_flow/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilderList extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  final T _data;

  FakePostgrestTransformBuilder(this._data);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return Future.value(_data).then(onValue, onError: onError);
  }
}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockFunctionsClient mockFunctionsClient;
  late MockFlutterSecureStorage mockSecureStorage;
  late SecureStorageService secureStorageService;
  late AuthRepositoryImpl authRepository;

  const tUserId = 'user-uuid-1234';
  const tEmail = 'foreman@mineflow.com';
  const tPassword = 'Password123!';
  const tRole = 'foreman';
  const tName = 'Budi Santoso';
  const tSiteId = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';

  final tUserJson = <String, dynamic>{
    'id': tUserId,
    'email': tEmail,
    'name': tName,
    'role': tRole,
    'site_id': tSiteId,
    'phone': '08123456789',
    'is_active': true,
    'created_at': '2026-07-18T10:00:00.000Z',
    'updated_at': '2026-07-18T10:00:00.000Z',
  };

  setUpAll(() {
    registerFallbackValue('fallback_string');
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockFunctionsClient = MockFunctionsClient();
    mockSecureStorage = MockFlutterSecureStorage();

    secureStorageService = SecureStorageService(storage: mockSecureStorage);

    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(() => mockSupabaseClient.functions).thenReturn(mockFunctionsClient);

    // Secure storage stubs
    when(
      () => mockSecureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockSecureStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
    when(
      () => mockSecureStorage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});
    when(() => mockSecureStorage.deleteAll()).thenAnswer((_) async {});
    when(() => mockGoTrueClient.signOut()).thenAnswer((_) async {});

    authRepository = AuthRepositoryImpl(
      supabaseClient: mockSupabaseClient,
      secureStorageService: secureStorageService,
    );
  });

  group('signInWithEmailAndPassword', () {
    test(
      'returns UserEntity and saves session on successful sign-in',
      () async {
        final mockUser = MockUser();
        final mockSession = MockSession();
        final mockQueryBuilder = MockSupabaseQueryBuilder();
        final mockFilterBuilderList = MockPostgrestFilterBuilderList();

        when(() => mockUser.id).thenReturn(tUserId);
        when(() => mockUser.userMetadata).thenReturn({'role': tRole});
        when(() => mockSession.accessToken).thenReturn('access-token-xyz');
        when(() => mockSession.refreshToken).thenReturn('refresh-token-xyz');

        when(
          () => mockGoTrueClient.signInWithPassword(
            email: tEmail,
            password: tPassword,
          ),
        ).thenAnswer(
          (_) async => AuthResponse(session: mockSession, user: mockUser),
        );

        when(
          () => mockSupabaseClient.from('users'),
        ).thenAnswer((_) => mockQueryBuilder);
        when(
          () => mockQueryBuilder.select(),
        ).thenAnswer((_) => mockFilterBuilderList);
        when(
          () => mockFilterBuilderList.eq('id', tUserId),
        ).thenAnswer((_) => mockFilterBuilderList);
        when(
          () => mockFilterBuilderList.single(),
        ).thenAnswer((_) => FakePostgrestTransformBuilder(tUserJson));

        final result = await authRepository.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        );

        expect(result.id, equals(tUserId));
        expect(result.email, equals(tEmail));
        expect(result.role, equals(tRole));
        expect(result.name, equals(tName));

        verify(
          () => mockSecureStorage.write(
            key: SecureStorageService.keyAuthToken,
            value: 'access-token-xyz',
          ),
        ).called(1);
      },
    );

    test('throws ServerFailure when credentials are invalid', () async {
      when(
        () => mockGoTrueClient.signInWithPassword(
          email: tEmail,
          password: tPassword,
        ),
      ).thenThrow(const AuthException('Invalid login credentials'));

      expect(
        () => authRepository.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        ),
        throwsA(
          isA<ServerFailure>().having(
            (f) => f.message,
            'message',
            contains('Email atau kata sandi salah'),
          ),
        ),
      );
    });
  });

  group('signOut', () {
    test('clears secure storage and revokes Supabase session', () async {
      await authRepository.signOut();

      verify(() => mockGoTrueClient.signOut()).called(1);
      verify(() => mockSecureStorage.deleteAll()).called(1);
    });
  });

  group('createUser (Supervisor Edge Function)', () {
    test('returns created UserEntity on HTTP 201 response', () async {
      final FunctionResponse functionResponse = FunctionResponse(
        status: 201,
        data: {'user': tUserJson},
      );

      when(
        () =>
            mockFunctionsClient.invoke('create-user', body: any(named: 'body')),
      ).thenAnswer((_) async => functionResponse);

      final result = await authRepository.createUser(
        email: tEmail,
        password: tPassword,
        role: tRole,
        fullName: tName,
      );

      expect(result.id, equals(tUserId));
      expect(result.name, equals(tName));
      expect(result.role, equals(tRole));
    });

    test('throws UnauthorizedFailure on HTTP 403 response', () async {
      const FunctionResponse functionResponse = FunctionResponse(
        status: 403,
        data: {
          'error':
              'Forbidden. Only active supervisors can create user accounts.',
        },
      );

      when(
        () =>
            mockFunctionsClient.invoke('create-user', body: any(named: 'body')),
      ).thenAnswer((_) async => functionResponse);

      expect(
        () => authRepository.createUser(
          email: tEmail,
          password: tPassword,
          role: tRole,
          fullName: tName,
        ),
        throwsA(isA<UnauthorizedFailure>()),
      );
    });
  });

  group('getCurrentUser', () {
    test('returns UserEntity when session exists', () async {
      final mockUser = MockUser();
      final mockSession = MockSession();
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilderList = MockPostgrestFilterBuilderList();

      when(() => mockUser.id).thenReturn(tUserId);
      when(() => mockSession.user).thenReturn(mockUser);
      when(() => mockGoTrueClient.currentSession).thenReturn(mockSession);

      when(
        () => mockSupabaseClient.from('users'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.select(),
      ).thenAnswer((_) => mockFilterBuilderList);
      when(
        () => mockFilterBuilderList.eq('id', tUserId),
      ).thenAnswer((_) => mockFilterBuilderList);
      when(
        () => mockFilterBuilderList.single(),
      ).thenAnswer((_) => FakePostgrestTransformBuilder(tUserJson));

      final result = await authRepository.getCurrentUser();

      expect(result, isNotNull);
      expect(result!.id, equals(tUserId));
    });

    test('returns null when no active session or stored user data', () async {
      when(() => mockGoTrueClient.currentSession).thenReturn(null);

      final result = await authRepository.getCurrentUser();

      expect(result, isNull);
    });
  });
}
