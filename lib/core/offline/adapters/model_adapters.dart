import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:mine_flow/core/data/models/models.dart';

/// Hive TypeAdapter for [AttendanceRecordModel] (typeId: 1)
class AttendanceRecordModelAdapter extends TypeAdapter<AttendanceRecordModel> {
  @override
  final int typeId = 1;

  @override
  AttendanceRecordModel read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return AttendanceRecordModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, AttendanceRecordModel obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

/// Hive TypeAdapter for [EquipmentCheckModel] (typeId: 2)
class EquipmentCheckModelAdapter extends TypeAdapter<EquipmentCheckModel> {
  @override
  final int typeId = 2;

  @override
  EquipmentCheckModel read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return EquipmentCheckModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, EquipmentCheckModel obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

/// Hive TypeAdapter for [DailyLogModel] (typeId: 3)
class DailyLogModelAdapter extends TypeAdapter<DailyLogModel> {
  @override
  final int typeId = 3;

  @override
  DailyLogModel read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return DailyLogModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, DailyLogModel obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

/// Hive TypeAdapter for [CutFillRecordModel] (typeId: 4)
class CutFillRecordModelAdapter extends TypeAdapter<CutFillRecordModel> {
  @override
  final int typeId = 4;

  @override
  CutFillRecordModel read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return CutFillRecordModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, CutFillRecordModel obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

/// Hive TypeAdapter for [LandClearingRecordModel] (typeId: 5)
class LandClearingRecordModelAdapter extends TypeAdapter<LandClearingRecordModel> {
  @override
  final int typeId = 5;

  @override
  LandClearingRecordModel read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return LandClearingRecordModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, LandClearingRecordModel obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

/// Hive TypeAdapter for [InventoryItemModel] (typeId: 6)
class InventoryItemModelAdapter extends TypeAdapter<InventoryItemModel> {
  @override
  final int typeId = 6;

  @override
  InventoryItemModel read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return InventoryItemModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, InventoryItemModel obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

/// Hive TypeAdapter for [GeospatialFileModel] (typeId: 7)
class GeospatialFileModelAdapter extends TypeAdapter<GeospatialFileModel> {
  @override
  final int typeId = 7;

  @override
  GeospatialFileModel read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return GeospatialFileModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, GeospatialFileModel obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

/// Hive TypeAdapter for [UserModel] (typeId: 8)
class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 8;

  @override
  UserModel read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return UserModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

/// Hive TypeAdapter for [ZoneModel] (typeId: 9)
class ZoneModelAdapter extends TypeAdapter<ZoneModel> {
  @override
  final int typeId = 9;

  @override
  ZoneModel read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return ZoneModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, ZoneModel obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}
