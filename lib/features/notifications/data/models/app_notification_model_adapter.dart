/// Hive TypeAdapter for [AppNotificationModel] (typeId: 15).
library;

import 'dart:convert';
import 'package:hive_ce/hive_ce.dart';
import 'package:mine_flow/features/notifications/data/models/app_notification_model.dart';

class AppNotificationModelAdapter extends TypeAdapter<AppNotificationModel> {
  @override
  final int typeId = 15;

  @override
  AppNotificationModel read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return AppNotificationModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, AppNotificationModel obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}
