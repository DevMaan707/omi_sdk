import 'device_types.dart';

/// Base device model
abstract class OmiDevice {
  final String id;
  final String name;
  final DeviceType type;
  final int? rssi;
  final Map<String, dynamic> metadata;
  final DateTime discoveredAt;

  const OmiDevice({
    required this.id,
    required this.name,
    required this.type,
    this.rssi,
    this.metadata = const {},
    DateTime? discoveredAt,
  }) : discoveredAt =
           discoveredAt ?? const Duration().inMicroseconds != 0
               ? DateTime.now()
               : DateTime.fromMicrosecondsSinceEpoch(0);

  /// Create device from scan result
  factory OmiDevice.fromScanResult(Map<String, dynamic> scanData) {
    final typeStr = scanData['type'] as String? ?? 'unknown';
    final type = DeviceType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => DeviceType.unknown,
    );

    switch (type) {
      case DeviceType.omi:
        return OmiHardwareDevice.fromScanResult(scanData);
      case DeviceType.frame:
        return FrameDevice.fromScanResult(scanData);
      case DeviceType.openglass:
        return OpenGlassDevice.fromScanResult(scanData);
      default:
        return UnknownDevice.fromScanResult(scanData);
    }
  }

  Map<String, dynamic> toJson();
}

/// Omi hardware device
class OmiHardwareDevice extends OmiDevice {
  final String? firmwareVersion;
  final String? hardwareVersion;
  final String? modelNumber;
  final int? batteryLevel;

  const OmiHardwareDevice({
    required super.id,
    required super.name,
    super.rssi,
    super.metadata,
    super.discoveredAt,
    this.firmwareVersion,
    this.hardwareVersion,
    this.modelNumber,
    this.batteryLevel,
  }) : super(type: DeviceType.omi);

  factory OmiHardwareDevice.fromScanResult(Map<String, dynamic> scanData) {
    return OmiHardwareDevice(
      id: scanData['id'] as String,
      name: scanData['name'] as String,
      rssi: scanData['rssi'] as int?,
      firmwareVersion: scanData['firmwareVersion'] as String?,
      hardwareVersion: scanData['hardwareVersion'] as String?,
      modelNumber: scanData['modelNumber'] as String?,
      batteryLevel: scanData['batteryLevel'] as int?,
      metadata: Map<String, dynamic>.from(scanData['metadata'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'rssi': rssi,
      'firmwareVersion': firmwareVersion,
      'hardwareVersion': hardwareVersion,
      'modelNumber': modelNumber,
      'batteryLevel': batteryLevel,
      'metadata': metadata,
      'discoveredAt': discoveredAt.toIso8601String(),
    };
  }

  OmiHardwareDevice copyWith({
    String? id,
    String? name,
    int? rssi,
    String? firmwareVersion,
    String? hardwareVersion,
    String? modelNumber,
    int? batteryLevel,
    Map<String, dynamic>? metadata,
  }) {
    return OmiHardwareDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      hardwareVersion: hardwareVersion ?? this.hardwareVersion,
      modelNumber: modelNumber ?? this.modelNumber,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Frame device
class FrameDevice extends OmiDevice {
  final String? frameLibHash;
  final bool? isLooping;

  const FrameDevice({
    required super.id,
    required super.name,
    super.rssi,
    super.metadata,
    super.discoveredAt,
    this.frameLibHash,
    this.isLooping,
  }) : super(type: DeviceType.frame);

  factory FrameDevice.fromScanResult(Map<String, dynamic> scanData) {
    return FrameDevice(
      id: scanData['id'] as String,
      name: scanData['name'] as String,
      rssi: scanData['rssi'] as int?,
      frameLibHash: scanData['frameLibHash'] as String?,
      isLooping: scanData['isLooping'] as bool?,
      metadata: Map<String, dynamic>.from(scanData['metadata'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'rssi': rssi,
      'frameLibHash': frameLibHash,
      'isLooping': isLooping,
      'metadata': metadata,
      'discoveredAt': discoveredAt.toIso8601String(),
    };
  }
}

/// OpenGlass device
class OpenGlassDevice extends OmiDevice {
  const OpenGlassDevice({
    required super.id,
    required super.name,
    super.rssi,
    super.metadata,
    super.discoveredAt,
  }) : super(type: DeviceType.openglass);

  factory OpenGlassDevice.fromScanResult(Map<String, dynamic> scanData) {
    return OpenGlassDevice(
      id: scanData['id'] as String,
      name: scanData['name'] as String,
      rssi: scanData['rssi'] as int?,
      metadata: Map<String, dynamic>.from(scanData['metadata'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'rssi': rssi,
      'metadata': metadata,
      'discoveredAt': discoveredAt.toIso8601String(),
    };
  }
}

/// Unknown device type
class UnknownDevice extends OmiDevice {
  const UnknownDevice({
    required super.id,
    required super.name,
    super.rssi,
    super.metadata,
    super.discoveredAt,
  }) : super(type: DeviceType.unknown);

  factory UnknownDevice.fromScanResult(Map<String, dynamic> scanData) {
    return UnknownDevice(
      id: scanData['id'] as String,
      name: scanData['name'] as String? ?? 'Unknown Device',
      rssi: scanData['rssi'] as int?,
      metadata: Map<String, dynamic>.from(scanData['metadata'] ?? {}),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'rssi': rssi,
      'metadata': metadata,
      'discoveredAt': discoveredAt.toIso8601String(),
    };
  }
}
