import 'dart:convert';
import 'package:hive_ce/hive_ce.dart';
import 'package:mine_flow/core/offline/models/sync_queue_item.dart';

/// Hive TypeAdapter for [SyncAction] enum (typeId: 11)
class SyncActionAdapter extends TypeAdapter<SyncAction> {
  @override
  final int typeId = 11;

  @override
  SyncAction read(BinaryReader reader) {
    final index = reader.readByte();
    return SyncAction.values[index % SyncAction.values.length];
  }

  @override
  void write(BinaryWriter writer, SyncAction obj) {
    writer.writeByte(obj.index);
  }
}

/// Hive TypeAdapter for [SyncStatus] enum (typeId: 12)
class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 12;

  @override
  SyncStatus read(BinaryReader reader) {
    final index = reader.readByte();
    return SyncStatus.values[index % SyncStatus.values.length];
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    writer.writeByte(obj.index);
  }
}

/// Hive TypeAdapter for [SyncQueueItem] (typeId: 10)
class SyncQueueItemAdapter extends TypeAdapter<SyncQueueItem> {
  @override
  final int typeId = 10;

  @override
  SyncQueueItem read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return SyncQueueItem.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, SyncQueueItem obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}
