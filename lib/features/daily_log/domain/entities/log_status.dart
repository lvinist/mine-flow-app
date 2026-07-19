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
}
