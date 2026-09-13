import 'package:equatable/equatable.dart';

/// Explicit assessment state for safety hazards on a Daily Log.
enum HazardState { notAssessed, none, present }

extension HazardStateValue on HazardState {
  String toValue() => switch (this) {
    HazardState.notAssessed => 'not_assessed',
    HazardState.none => 'none',
    HazardState.present => 'present',
  };

  static HazardState fromString(String? value) => switch (value) {
    'none' => HazardState.none,
    'present' => HazardState.present,
    _ => HazardState.notAssessed,
  };
}

/// Severity is meaningful only when [HazardState.present] is selected.
enum HazardSeverity { low, medium, high, critical }

extension HazardSeverityValue on HazardSeverity {
  String toValue() => name;

  static HazardSeverity? fromString(String? value) => switch (value) {
    'low' => HazardSeverity.low,
    'medium' => HazardSeverity.medium,
    'high' => HazardSeverity.high,
    'critical' => HazardSeverity.critical,
    _ => null,
  };
}

/// One aggregate hazard assessment belongs to each Daily Log.
class HazardAssessment extends Equatable {
  final HazardState state;
  final HazardSeverity? severity;
  final String? notes;
  final String? correctiveAction;

  const HazardAssessment({
    this.state = HazardState.notAssessed,
    this.severity,
    this.notes,
    this.correctiveAction,
  });

  const HazardAssessment.notAssessed()
    : state = HazardState.notAssessed,
      severity = null,
      notes = null,
      correctiveAction = null;

  const HazardAssessment.none()
    : state = HazardState.none,
      severity = null,
      notes = null,
      correctiveAction = null;

  /// Copies with selective replacement; callers pass a full new assessment
  /// or rely on [normalized] to drop fields meaningless for the state.
  HazardAssessment copyWith({
    HazardState? state,
    HazardSeverity? severity,
    String? notes,
    String? correctiveAction,
  }) {
    return HazardAssessment(
      state: state ?? this.state,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      correctiveAction: correctiveAction ?? this.correctiveAction,
    );
  }

  bool get isValid => switch (state) {
    HazardState.present => severity != null,
    HazardState.none || HazardState.notAssessed =>
      severity == null &&
          (notes == null || notes!.trim().isEmpty) &&
          (correctiveAction == null || correctiveAction!.trim().isEmpty),
  };

  HazardAssessment normalized() => HazardAssessment(
    state: state,
    severity: state == HazardState.present ? severity : null,
    notes: state == HazardState.present ? _trimOrNull(notes) : null,
    correctiveAction: state == HazardState.present
        ? _trimOrNull(correctiveAction)
        : null,
  );

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  List<Object?> get props => [state, severity, notes, correctiveAction];
}
