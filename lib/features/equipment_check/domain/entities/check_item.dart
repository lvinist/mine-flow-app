import 'package:equatable/equatable.dart';

/// Single item within an SOP checklist (e.g. Battery Level, Calibration, Optical Lens).
///
/// [isPassed] is nullable (CF-017): `null` means the item has not yet been
/// answered, so a fresh form can never silently default to "all pass".
class CheckItem extends Equatable {
  final String id;
  final String label;
  final bool? isPassed;
  final String? remarks;

  const CheckItem({
    required this.id,
    required this.label,
    required this.isPassed,
    this.remarks,
  });

  /// Whether this item has been given an explicit pass/fail verdict.
  bool get isAnswered => isPassed != null;

  CheckItem copyWith({
    String? id,
    String? label,
    bool? isPassed,
    String? remarks,
  }) {
    return CheckItem(
      id: id ?? this.id,
      label: label ?? this.label,
      isPassed: isPassed ?? this.isPassed,
      remarks: remarks ?? this.remarks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'is_passed': isPassed,
      if (remarks != null) 'remarks': remarks,
    };
  }

  factory CheckItem.fromJson(Map<String, dynamic> json) {
    return CheckItem(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      isPassed: json['is_passed'] as bool?,
      remarks: json['remarks'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, label, isPassed, remarks];
}
