import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mine_flow/features/daily_log/domain/entities/hazard_assessment.dart';
import 'package:mine_flow/features/daily_log/presentation/bloc/daily_log_event.dart';
import 'package:mine_flow/l10n/app_localizations.dart';

/// Structured hazard assessment editor (STEP-55.6, spec §4.5 item 7 /
/// FC-54.6-002).
///
/// The foreman must answer the hazard question explicitly before submit:
/// an explicit "Tidak ada bahaya" (none) state exists so absence is a
/// recorded answer, not a missing field. When a hazard is present, severity
/// (4 user-approved levels) is required and notes/corrective action become
/// editable. Weather stays single-select and lives in [WeatherSelector];
/// this widget owns the hazard dimension only.
class HazardAssessmentField extends StatelessWidget {
  final HazardAssessment hazard;
  final bool enabled;
  final ValueChanged<HazardAssessmentChange> onChanged;

  const HazardAssessmentField({
    super.key,
    required this.hazard,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final isPresent = hazard.state == HazardState.present;

    return Semantics(
      container: true,
      label: 'Penilaian bahaya K3',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).dailyLogHazardRequiredLabel,
            style: theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),

          // State: explicit three-way answer (not-assessed is never a valid
          // submit state — the user-resolved policy, 2026-09-12).
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (state, label, icon) in [
                (
                  HazardState.none,
                  AppLocalizations.of(context).dailyLogHazardNone,
                  LucideIcons.shieldCheck,
                ),
                (
                  HazardState.present,
                  AppLocalizations.of(context).dailyLogHazardPresent,
                  LucideIcons.alertTriangle,
                ),
              ])
                FButton(
                  key: ValueKey('hazard_state_${state.toValue()}'),
                  variant: hazard.state == state
                      ? FButtonVariant.primary
                      : FButtonVariant.outline,
                  onPress: enabled && hazard.state != state
                      ? () => onChanged(HazardAssessmentChange(state: state))
                      : null,
                  prefix: Icon(
                    icon,
                    size: 18,
                    color: hazard.state == state
                        ? theme.colors.primaryForeground
                        : (state == HazardState.present
                              ? theme.colors.destructive
                              : theme.colors.primary),
                  ),
                  child: Semantics(
                    label:
                        '$label'
                        '${hazard.state == state ? ', terpilih' : ''}',
                    excludeSemantics: true,
                    child: Text(label),
                  ),
                ),
            ],
          ),

          if (isPresent) ...[
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).dailyLogHazardSeverityLabel,
              style: theme.typography.body.sm.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (severity, label) in [
                  (
                    HazardSeverity.low,
                    AppLocalizations.of(context).dailyLogHazardSeverityLow,
                  ),
                  (
                    HazardSeverity.medium,
                    AppLocalizations.of(context).dailyLogHazardSeverityMedium,
                  ),
                  (
                    HazardSeverity.high,
                    AppLocalizations.of(context).dailyLogHazardSeverityHigh,
                  ),
                  (
                    HazardSeverity.critical,
                    AppLocalizations.of(context).dailyLogHazardSeverityCritical,
                  ),
                ])
                  FButton(
                    key: ValueKey('hazard_severity_${severity.toValue()}'),
                    variant: hazard.severity == severity
                        ? FButtonVariant.primary
                        : FButtonVariant.outline,
                    onPress: enabled && hazard.severity != severity
                        ? () => onChanged(
                            HazardAssessmentChange(severity: severity),
                          )
                        : null,
                    child: Semantics(
                      label:
                          'Keparahan $label'
                          '${hazard.severity == severity ? ', terpilih' : ''}',
                      excludeSemantics: true,
                      child: Text(label),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            _HazardTextField(
              key: const Key('hazard_notes_field'),
              label: AppLocalizations.of(context).dailyLogHazardNotesLabel,
              hint: AppLocalizations.of(context).dailyLogHazardNotesHint,
              initialText: hazard.notes,
              enabled: enabled,
              maxLines: 3,
              onChanged: (text) =>
                  onChanged(HazardAssessmentChange(notes: text)),
            ),
            const SizedBox(height: 12),
            _HazardTextField(
              key: const Key('hazard_action_field'),
              label: AppLocalizations.of(context).dailyLogHazardActionLabel,
              hint: AppLocalizations.of(context).dailyLogHazardActionHint,
              initialText: hazard.correctiveAction,
              enabled: enabled,
              maxLines: 3,
              onChanged: (text) =>
                  onChanged(HazardAssessmentChange(correctiveAction: text)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Local text field that reports only user edits, so the bloc never loops
/// on its own echo (pattern of the summary/notes fields in the form sheet).
class _HazardTextField extends StatefulWidget {
  final String label;
  final String hint;
  final String? initialText;
  final bool enabled;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _HazardTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.initialText,
    required this.enabled,
    required this.maxLines,
    required this.onChanged,
  });

  @override
  State<_HazardTextField> createState() => _HazardTextFieldState();
}

class _HazardTextFieldState extends State<_HazardTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.typography.body.sm.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          decoration: InputDecoration(hintText: widget.hint),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
