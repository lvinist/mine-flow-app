// Login page for mine-flow.
//
// Entry point for all users (Supervisor, Foreman, Crew). Authenticates via
// email/password through Supabase Auth (see Doc 16 — Identity & Auth, §1).
//
// This is a skeleton stub. The actual form, BLoC integration, and Supabase
// auth calls are implemented in STEP-3 (Core Data Layer & Authentication).

import 'package:flutter/material.dart';

/// The login screen shown to unauthenticated users.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('mine-flow — Login (implementasi di STEP-3)'),
      ),
    );
  }
}
