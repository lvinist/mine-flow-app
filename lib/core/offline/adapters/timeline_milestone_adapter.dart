import 'dart:convert';
import 'package:hive_ce/hive_ce.dart';
import 'package:mine_flow/features/timeline/data/models/timeline_milestone_model.dart';

/// Hive TypeAdapter for [TimelineMilestoneModel] (typeId: 14).
///
/// Uses JSON serialization to avoid field-level binary coupling,
/// matching the pattern used by all other model adapters in this project.
class TimelineMilestoneModelAdapter
    extends TypeAdapter<TimelineMilestoneModel> {
  @override
  final int typeId = 14;

  @override
  TimelineMilestoneModel read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return TimelineMilestoneModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, TimelineMilestoneModel obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}
