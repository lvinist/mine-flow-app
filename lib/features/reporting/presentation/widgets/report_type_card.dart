import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mine_flow/features/reporting/domain/entities/report_type.dart';

// Phase 2 — shadcn-admin design language constants (DESIGN.md §29).
const double _kCardRadius = 12;
const double _kSpacing12 = 12;
const double _kSpacing16 = 16;
const double _kSpacing20 = 20;
const double _kSpacing24 = 24;

/// Brand primary — Steel Blue / Navy (#0f172a), the restrained foundation.
const Color _kBrandPrimary = Color(0xFF0F172A);

/// Accent — Cyan / Teal, used sparingly for interactive elements.
const Color _kAccent = Color(0xFF0891B2);

/// A card widget that represents a report type for selection on the dashboard.
///
/// Displays an icon, the report type's display name, and a "Pilih" button.
/// Tapping anywhere on the card triggers [onTap].
///
/// Phase 2 Polish (substep 25.2): micro-interactions with easeOutQuart curves,
/// AnimatedContainer hover/focus border/background changes, brand colours,
/// keyboard accessibility (Focus + Enter/Space), and refined spacing.
class ReportTypeCard extends StatefulWidget {
  final ReportType type;
  final IconData icon;
  final VoidCallback onTap;

  const ReportTypeCard({
    super.key,
    required this.type,
    required this.icon,
    required this.onTap,
  });

  @override
  State<ReportTypeCard> createState() => _ReportTypeCardState();
}

class _ReportTypeCardState extends State<ReportTypeCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Merge hover and focus states for visual feedback.
    final isActive = _isHovered || _isFocused;

    return Semantics(
      label: widget.type.displayName,
      button: true,
      child: Focus(
        onKeyEvent: (node, event) {
          // Activate on Enter or Space key.
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)) {
            widget.onTap();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        onFocusChange: (isFocused) {
          setState(() => _isFocused = isFocused);
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutQuart,
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(_kCardRadius),
              border: Border.all(
                color: isActive
                    ? colorScheme.outlineVariant
                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(_kCardRadius),
                focusColor: colorScheme.primary.withValues(alpha: 0.08),
                hoverColor: Colors.transparent,
                splashColor: colorScheme.primary.withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.all(_kSpacing20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon in brand-primary container
                      Semantics(
                        excludeSemantics: true,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _kBrandPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(_kSpacing12),
                          ),
                          child: Icon(widget.icon, size: 28, color: _kAccent),
                        ),
                      ),
                      const SizedBox(height: _kSpacing16),
                      Text(
                        widget.type.displayName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: _kSpacing24),
                      // Exclude from semantics: the outer Sematis(button: true)
                      // already exposes the card as a single interactive element.
                      Semantics(
                        excludeSemantics: true,
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: widget.onTap,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide(
                                color: _isHovered || _isFocused
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                              ),
                            ),
                            child: const Text('Pilih'),
                          ),
                        ),
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
