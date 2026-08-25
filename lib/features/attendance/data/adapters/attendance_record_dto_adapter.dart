import 'dart:convert';
import 'package:hive_ce/hive_ce.dart';
import 'package:mine_flow/features/attendance/data/models/attendance_record_dto.dart';

/// Hive TypeAdapter for [AttendanceRecordDto] (typeId: 21)
class AttendanceRecordDtoAdapter extends TypeAdapter<AttendanceRecordDto> {
  @override
  final int typeId = 21;

  @override
  AttendanceRecordDto read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return AttendanceRecordDto.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, AttendanceRecordDto obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}
