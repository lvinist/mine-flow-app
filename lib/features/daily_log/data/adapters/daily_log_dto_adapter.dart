import 'dart:convert';
import 'package:hive_ce/hive_ce.dart';
import 'package:mine_flow/features/daily_log/data/models/daily_log_dto.dart';

/// Hive TypeAdapter for [DailyLogDto] (typeId: 22)
class DailyLogDtoAdapter extends TypeAdapter<DailyLogDto> {
  @override
  final int typeId = 22;

  @override
  DailyLogDto read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return DailyLogDto.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, DailyLogDto obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}
