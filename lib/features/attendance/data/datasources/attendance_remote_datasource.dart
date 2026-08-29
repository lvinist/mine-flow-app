import 'package:mine_flow/features/attendance/data/models/attendance_record_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Contract for remote Supabase interactions for attendance records.
abstract class AttendanceRemoteDataSource {
  Future<List<AttendanceRecordDto>> fetchAllAttendance();
  Future<AttendanceRecordDto?> fetchAttendanceById(String id);
  Future<void> upsertAttendance(AttendanceRecordDto dto);
  Future<void> deleteAttendance(String id);
}

/// Implementation of [AttendanceRemoteDataSource] backed by Supabase.
class SupabaseAttendanceRemoteDataSource implements AttendanceRemoteDataSource {
  final SupabaseClient supabaseClient;

  SupabaseAttendanceRemoteDataSource(this.supabaseClient);

  @override
  Future<List<AttendanceRecordDto>> fetchAllAttendance() async {
    final response = await supabaseClient
        .from('attendance_records')
        .select('*, users!attendance_records_user_id_fkey(name)')
        .filter('deleted_at', 'is', null);

    return (response as List<dynamic>)
        .map(
          (json) => AttendanceRecordDto.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<AttendanceRecordDto?> fetchAttendanceById(String id) async {
    final response = await supabaseClient
        .from('attendance_records')
        .select('*, users!attendance_records_user_id_fkey(name)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return AttendanceRecordDto.fromJson(response);
  }

  @override
  Future<void> upsertAttendance(AttendanceRecordDto dto) async {
    await supabaseClient.from('attendance_records').upsert(dto.toJson());
  }

  @override
  Future<void> deleteAttendance(String id) async {
    await supabaseClient
        .from('attendance_records')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }
}
