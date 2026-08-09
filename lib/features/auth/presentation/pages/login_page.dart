import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/app/router.dart';

/// The login screen shown to users.
///
/// Rebuilt in Substep 30.1 with ForUI components (FCard, FButton, FTextField)
/// and FTheme typography/color tokens.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: 'admin@mineflow.id');
  final _passwordController = TextEditingController(text: 'password123');

  void _login() {
    context.go(AppRoutes.dashboard);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: FCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Branding ---
                    const Center(
                      child: Icon(Icons.terrain, size: 64),
                    ),
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
                      'Sistem Monitoring & Manajamen Tambang',
                      textAlign: TextAlign.center,
                      style: theme.typography.body.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Email field ---
                    FTextField(
                      control: FTextFieldControl.managed(
                        controller: _emailController,
                      ),
                      label: const Text('Email'),
                      hint: 'admin@mineflow.id',
                    ),
                    const SizedBox(height: 16),

                    // --- Password field ---
                    FTextField.password(
                      control: FTextFieldControl.managed(
                        controller: _passwordController,
                      ),
                      label: const Text('Kata Sandi'),
                    ),
                    const SizedBox(height: 24),

                    // --- Submit button ---
                    FButton(
                      onPress: _login,
                      child: const Text('Masuk'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
