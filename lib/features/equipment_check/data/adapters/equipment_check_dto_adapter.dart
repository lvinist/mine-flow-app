import 'dart:convert';
import 'package:hive_ce/hive_ce.dart';
import 'package:mine_flow/features/equipment_check/data/models/equipment_check_dto.dart';

/// Hive TypeAdapter for [EquipmentCheckDto] (typeId: 23)
class EquipmentCheckDtoAdapter extends TypeAdapter<EquipmentCheckDto> {
  @override
  final int typeId = 23;

  @override
  EquipmentCheckDto read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return EquipmentCheckDto.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, EquipmentCheckDto obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}
