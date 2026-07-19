/// Indicates whether condition check is pre-work (start of shift) or post-work (end of shift).
enum CheckType {
  preWork,
  postWork;

  String toValue() {
    switch (this) {
      case CheckType.preWork:
        return 'pre_work';
      case CheckType.postWork:
        return 'post_work';
    }
  }

  static CheckType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'pre_work':
      case 'prework':
        return CheckType.preWork;
      case 'post_work':
      case 'postwork':
        return CheckType.postWork;
      default:
        return CheckType.preWork;
    }
  }

  String get displayName {
    switch (this) {
      case CheckType.preWork:
        return 'Pre-Work Check';
      case CheckType.postWork:
        return 'Post-Work Check';
    }
  }
}
