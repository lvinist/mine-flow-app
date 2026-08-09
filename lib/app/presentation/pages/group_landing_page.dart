import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

/// Configuration for a single feature tile on a landing page.
class FeatureTileConfig {
  final String label;
  final String description;
  final IconData icon;
  final String route;

  const FeatureTileConfig({
    required this.label,
    required this.description,
    required this.icon,
    required this.route,
  });
}

/// A landing page for a navigation branch that contains multiple features.
///
/// Displays a title, description, and a grid of cards for each feature.
class GroupLandingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<FeatureTileConfig> features;

  const GroupLandingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: theme.typography.display.xl.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.typography.body.md.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: features.map((config) {
                return _FeatureTileCard(
                  config: config,
                  color: theme.colors.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single quick-access feature tile.
class _FeatureTileCard extends StatelessWidget {
  final FeatureTileConfig config;
  final Color color;

  const _FeatureTileCard({
    required this.config,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);

    return Semantics(
      label: config.label,
      button: true,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            context.push(config.route); // Navigate to branch route
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: () => context.push(config.route),
          child: SizedBox(
            width: 260,
            child: FCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Semantics(
                      excludeSemantics: true,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(config.icon, size: 22, color: color),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.label,
                            style: theme.typography.body.sm.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            config.description,
                            style: theme.typography.body.xs.copyWith(
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: theme.colors.mutedForeground,
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
