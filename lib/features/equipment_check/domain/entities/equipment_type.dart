/// Represents types of site equipment requiring SOP condition checks.
enum EquipmentType {
  gnss,
  totalStation,
  drone;

  String toValue() {
    switch (this) {
      case EquipmentType.gnss:
        return 'gnss';
      case EquipmentType.totalStation:
        return 'total_station';
      case EquipmentType.drone:
        return 'drone';
    }
  }

  static EquipmentType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'gnss':
        return EquipmentType.gnss;
      case 'total_station':
      case 'totalstation':
        return EquipmentType.totalStation;
      case 'drone':
      case 'uav':
        return EquipmentType.drone;
      default:
        return EquipmentType.gnss;
    }
  }

  String get displayName {
    switch (this) {
      case EquipmentType.gnss:
        return 'GNSS Receiver';
      case EquipmentType.totalStation:
        return 'Total Station';
      case EquipmentType.drone:
        return 'Drone / UAV';
    }
  }
}
