/// Represents the attendance status of a crew member.
enum AttendanceStatus {
  present,
  absent,
  sick,
  leave;

  /// Parses string value into [AttendanceStatus] with fallback to [present].
  static AttendanceStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'absent':
        return AttendanceStatus.absent;
      case 'sick':
        return AttendanceStatus.sick;
      case 'leave':
        return AttendanceStatus.leave;
      case 'present':
      default:
        return AttendanceStatus.present;
    }
  }

  /// String representation stored in database/JSON.
  String toValue() => name;
}
