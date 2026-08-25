import 'dart:convert';
import 'package:hive_ce/hive_ce.dart';
import 'package:mine_flow/features/data_bucket/data/models/geospatial_file_model.dart';

/// Hive TypeAdapter for [GeospatialFileModel] (typeId: 13)
///
/// Note: typeId 7 is used by the core [GeospatialFileModelAdapter] in
/// `lib/core/offline/adapters/model_adapters.dart`. This feature-scoped
/// adapter uses typeId 13, which is not in the reserved set (4, 5, 6, 10, 11, 12).
class GeospatialFileModelAdapter extends TypeAdapter<GeospatialFileModel> {
  @override
  final int typeId = 13;

  @override
  GeospatialFileModel read(BinaryReader reader) {
    final jsonStr = reader.readString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return GeospatialFileModel.fromHiveJson(json);
  }

  @override
  void write(BinaryWriter writer, GeospatialFileModel obj) {
    writer.writeString(jsonEncode(obj.toHiveJson()));
  }
}
