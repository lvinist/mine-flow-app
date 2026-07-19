/// Represents the overall status of an equipment condition check.
enum CheckStatus {
  passed,
  failed,
  flagged;

  String toValue() {
    switch (this) {
      case CheckStatus.passed:
        return 'passed';
      case CheckStatus.failed:
        return 'failed';
      case CheckStatus.flagged:
        return 'flagged';
    }
  }

  static CheckStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'passed':
      case 'pass':
        return CheckStatus.passed;
      case 'failed':
      case 'fail':
        return CheckStatus.failed;
      case 'flagged':
      case 'flag':
        return CheckStatus.flagged;
      default:
        return CheckStatus.passed;
    }
  }

  String get displayName {
    switch (this) {
      case CheckStatus.passed:
        return 'Passed';
      case CheckStatus.failed:
        return 'Failed';
      case CheckStatus.flagged:
        return 'Flagged';
    }
  }
}
