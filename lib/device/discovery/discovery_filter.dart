import '../models/device_types.dart';
import '../models/device_models.dart';

class DeviceDiscoveryFilter {
  final List<DeviceType>? deviceTypes;
  final String? namePattern;
  final int? minRssi;
  final bool Function(OmiDevice device)? customFilter;

  const DeviceDiscoveryFilter({
    this.deviceTypes,
    this.namePattern,
    this.minRssi,
    this.customFilter,
  });

  DeviceDiscoveryFilter copyWith({
    List<DeviceType>? deviceTypes,
    String? namePattern,
    int? minRssi,
    bool Function(OmiDevice device)? customFilter,
  }) {
    return DeviceDiscoveryFilter(
      deviceTypes: deviceTypes ?? this.deviceTypes,
      namePattern: namePattern ?? this.namePattern,
      minRssi: minRssi ?? this.minRssi,
      customFilter: customFilter ?? this.customFilter,
    );
  }

  /// Filter for Omi devices only
  static const omiOnly = DeviceDiscoveryFilter(
    deviceTypes: [DeviceType.omi, DeviceType.openglass],
  );

  /// Filter for Frame devices only
  static const frameOnly = DeviceDiscoveryFilter(
    deviceTypes: [DeviceType.frame],
  );

  /// Filter for devices with good signal strength
  static const strongSignalOnly = DeviceDiscoveryFilter(minRssi: -70);
}
