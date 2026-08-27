import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/core/error/failures.dart';
import 'package:mine_flow/features/auth/domain/entities/user_entity.dart';
import 'package:mine_flow/features/auth/domain/repositories/auth_repository.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:mine_flow/features/auth/presentation/pages/login_page.dart';

/// In-memory [AuthRepository] for widget tests (CF-001/003).
class FakeAuthRepository implements AuthRepository {
  String? lastEmail;
  String? lastPassword;
  bool failSignIn = false;
  bool signedOut = false;
  UserEntity? currentUser;

  @override
  Future<UserEntity?> getCurrentUser() async => currentUser;

  @override
  Future<void> signOut() async {
    signedOut = true;
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    if (failSignIn) {
      throw const ServerFailure('Email atau kata sandi salah.');
    }
    return UserEntity(
      id: 'u1',
      email: email,
      name: 'Budi Santoso',
      role: 'foreman',
      siteId: 's1',
    );
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
    throw UnimplementedError();
  }

  @override
  Stream<UserEntity?> get onAuthStateChanges => const Stream.empty();
}

Widget _wrap(FakeAuthRepository repo) {
  return BlocProvider<AuthCubit>(
    create: (_) => AuthCubit(repository: repo),
    child: FTheme(
      data: FTheme.neutral.light.touch,
      child: const MaterialApp(home: LoginPage()),
    ),
  );
}

void main() {
  late FakeAuthRepository repo;

  setUp(() {
    repo = FakeAuthRepository();
  });

  testWidgets('renders ForUI widgets and corrected tagline (CF-056)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repo));

    expect(find.byType(FCard), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('mine-flow'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    // CF-056: "Manajamen" → "Manajemen".
    expect(find.text('Sistem Monitoring & Manajemen Tambang'), findsOneWidget);
    expect(find.textContaining('Manajamen'), findsNothing);
  });

  testWidgets('fields start empty, no shipped credentials (CF-002)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repo));

    final emailEditable = find.descendant(
      of: find.byType(FTextField).first,
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(emailEditable).controller.text, isEmpty);
  });

  testWidgets('submit disabled on empty fields; enables when both filled', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repo));

    // Button starts disabled.
    final masuk = find.widgetWithText(FButton, 'Masuk');
    expect(tester.widget<FButton>(masuk).onPress, isNull);

    // Email only → still disabled (password empty).
    await tester.enterText(find.byType(EditableText).first, 'a@b.com');
    await tester.pump();
    expect(tester.widget<FButton>(masuk).onPress, isNull);
    expect(repo.lastEmail, isNull);

    // Both fields → enabled.
    await tester.enterText(find.byType(EditableText).last, 'secret123');
    await tester.pump();
    expect(tester.widget<FButton>(masuk).onPress, isNotNull);
  });

  testWidgets('signs in with entered credentials (CF-001)', (tester) async {
    await tester.pumpWidget(_wrap(repo));

    await tester.enterText(find.byType(EditableText).first, 'foreman@x.com');
    await tester.enterText(find.byType(EditableText).last, 'secret123');
    await tester.pump();

    final masuk = find.widgetWithText(FButton, 'Masuk');
    expect(tester.widget<FButton>(masuk).onPress, isNotNull);
    await tester.tap(masuk);
    await tester.pumpAndSettle();

    expect(repo.lastEmail, 'foreman@x.com');
    expect(repo.lastPassword, 'secret123');
  });

  testWidgets('surfaces sign-in failure without navigating (CF-003)', (
    tester,
  ) async {
    repo.failSignIn = true;
    await tester.pumpWidget(_wrap(repo));

    await tester.enterText(find.byType(EditableText).first, 'foreman@x.com');
    await tester.enterText(find.byType(EditableText).last, 'wrong');
    await tester.pump();
    await tester.tap(find.widgetWithText(FButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Email atau kata sandi salah.'), findsOneWidget);
    // Still on the login page.
    expect(find.text('Masuk'), findsOneWidget);
  });
}
