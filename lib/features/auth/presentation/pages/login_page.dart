import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:mine_flow/features/auth/presentation/bloc/auth_cubit.dart';

/// The login screen shown to users.
///
/// Rebuilt in Substep 30.1 with ForUI components, then wired to the real
/// [AuthCubit] in STEP-46.4 (CF-001/003): it now authenticates against
/// Supabase via `AuthCubit.signIn` instead of navigating straight through, and
/// surfaces submitting/error state.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  // CF-002: no pre-filled credentials — controllers start empty.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // Recompute button enabled-ness as the user types.
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  /// Validates the two fields and, if valid, signs in via [AuthCubit].
  void _login(AuthCubit cubit) {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = email.isEmpty ? 'Email wajib diisi.' : null;
      _passwordError = password.isEmpty ? 'Kata sandi wajib diisi.' : null;
    });

    if (email.isEmpty || password.isEmpty) return;

    cubit.signIn(email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final cubit = context.watch<AuthCubit>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: FCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Branding ---
                      const Center(child: Icon(Icons.terrain, size: 64)),
                      const SizedBox(height: 16),
                      Text(
                        'mine-flow',
                        textAlign: TextAlign.center,
                        style: theme.typography.display.xl2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sistem Monitoring & Manajemen Tambang',
                        textAlign: TextAlign.center,
                        style: theme.typography.body.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- Sign-in error banner ---
                      if (cubit.state.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colors.destructive.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cubit.state.errorMessage!,
                            style: theme.typography.body.sm.copyWith(
                              color: theme.colors.destructive,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // --- Email field ---
                      FTextField(
                        control: FTextFieldControl.managed(
                          controller: _emailController,
                        ),
                        label: const Text('Email'),
                        hint: 'admin@mineflow.id',
                        keyboardType: TextInputType.emailAddress,
                        error: _emailError == null ? null : Text(_emailError!),
                      ),
                      const SizedBox(height: 16),

                      // --- Password field ---
                      FTextField.password(
                        control: FTextFieldControl.managed(
                          controller: _passwordController,
                        ),
                        label: const Text('Kata Sandi'),
                        error: _passwordError == null
                            ? null
                            : Text(_passwordError!),
                      ),
                      const SizedBox(height: 24),

                      // --- Submit button ---
                      FButton(
                        onPress: (cubit.state.isSubmitting || !_canSubmit)
                            ? null
                            : () => _login(cubit),
                        child: cubit.state.isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Masuk'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
