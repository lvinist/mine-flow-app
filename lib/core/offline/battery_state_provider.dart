import 'package:battery_plus/battery_plus.dart';

/// Provides battery state information. Injectable to allow for testing
/// without platform channel calls.
abstract class BatteryStateProvider {
  /// Returns the current battery level (0-100).
  Future<int> get batteryLevel;

  /// Returns true if the device is in battery save mode.
  Future<bool> get isInBatterySaveMode;

  /// Returns true if the device is currently charging or fully charged/connected.
  Future<bool> get isCharging;
}

/// Default implementation utilizing the battery_plus package.
class DefaultBatteryStateProvider implements BatteryStateProvider {
  final Battery _battery = Battery();

  @override
  Future<int> get batteryLevel async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      // Fallback: Battery level unavailable -> Treat as 100% (Healthy)
      return 100;
    }
  }

  @override
  Future<bool> get isInBatterySaveMode async {
    try {
      return await _battery.isInBatterySaveMode;
    } catch (_) {
      // Fallback: OS saver unavailable -> Treat as false (OFF)
      return false;
    }
  }

  @override
  Future<bool> get isCharging async {
    try {
      final state = await _battery.batteryState;
      return state == BatteryState.charging ||
          state == BatteryState.connectedNotCharging ||
          state == BatteryState.full;
    } catch (_) {
      // Fallback: treat as not charging if we don't know, to respect the level/saver limits.
      return false;
    }
  }
}
