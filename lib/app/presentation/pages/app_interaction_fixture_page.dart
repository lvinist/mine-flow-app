/// Minimal route fixture for shared sheet behavior.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_flow/core/presentation/widgets/app_interaction_primitives.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

/// A list-and-sheet fixture used to verify direct URL reconstruction.
class AppInteractionFixturePage extends StatelessWidget {
  /// Creates the shared interaction fixture from the active route state.
  const AppInteractionFixturePage({super.key, required this.routeUri});

  /// The current durable URL, including preserved list query state.
  final Uri routeUri;

  bool get _isFormOpen =>
      routeUri.pathSegments.isNotEmpty && routeUri.pathSegments.last == 'form';

  void _close(BuildContext context) {
    context.go(closeSheetUri(routeUri).toString());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.interactionFixtureTitle)),
      body: Stack(
        children: [
          Center(child: Text(l10n.interactionFixtureList)),
          if (_isFormOpen)
            AppResponsiveSheet(
              routeIdentity: routeUri.toString(),
              title: l10n.interactionFixtureTitle,
              mode: AppResponsiveSheetMode.form,
              body: Text(l10n.interactionFixtureSheet),
              onDismissApproved: () => _close(context),
            ),
        ],
      ),
      floatingActionButton: _isFormOpen
          ? null
          : FloatingActionButton(
              onPressed: () => context.go('${routeUri.path}/form'),
              child: const Icon(Icons.add),
            ),
    );
  }
}
