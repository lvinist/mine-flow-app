// Placeholder Settings page for STEP-31.1 scaffold.
//
// This is a stub branch destination — the full Settings page with language,
// profile, theme, and logout will be implemented in STEP-35.

import 'package:flutter/material.dart';

/// Placeholder settings page shown as the default child of the Settings branch.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Pengaturan',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
