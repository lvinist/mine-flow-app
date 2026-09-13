/// Status of a daily operations log entry.
enum LogStatus {
  draft,
  submitted,
  approved;

  /// Parses string value into [LogStatus]. Defaults to [LogStatus.draft].
  static LogStatus fromString(String? value) {
    if (value == null) return LogStatus.draft;
    switch (value.toLowerCase().trim()) {
      case 'submitted':
        return LogStatus.submitted;
      case 'approved':
        return LogStatus.approved;
      case 'draft':
      default:
        return LogStatus.draft;
    }
  }

  /// Converts [LogStatus] into string value for database serialization.
  String toValue() {
    switch (this) {
      case LogStatus.submitted:
        return 'submitted';
      case LogStatus.approved:
        return 'approved';
      case LogStatus.draft:
        return 'draft';
    }
  }

  /// Whether a log may move from `this` to [next] (STEP-55.6, spec §4.5).
  ///
  /// The review workflow is a strict forward machine — no Kanban, no
  /// arbitrary jumps, no un-approval:
  ///   draft     -> draft | submitted   (foreman edits, then submits)
  ///   submitted -> submitted | approved (supervisor inspects, then approves)
  ///   approved  -> approved             (immutable in this workflow)
  ///
  /// The same rule is enforced server-side by
  /// `public.enforce_daily_log_transition()` in the 55.6 migration, so a
  /// client that skips this guard still cannot persist an illegal jump.
  bool canTransitionTo(LogStatus next) {
    switch (this) {
      case LogStatus.draft:
        return next == LogStatus.draft || next == LogStatus.submitted;
      case LogStatus.submitted:
        return next == LogStatus.submitted || next == LogStatus.approved;
      case LogStatus.approved:
        return next == LogStatus.approved;
    }
  }

  /// Whether a foreman may still edit the record's content.
  bool get isEditable => this == LogStatus.draft;

  /// Whether the record is approved and therefore immutable.
  bool get isImmutable => this == LogStatus.approved;
}
