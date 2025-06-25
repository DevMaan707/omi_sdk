enum DeviceType { omi, frame, openglass, unknown }

enum DeviceConnectionState { disconnected, connecting, connected, error }

enum AudioCodec {
  pcm8,
  pcm16,
  opus,
  opusFS320;

  int get sampleRate {
    switch (this) {
      case AudioCodec.pcm8:
        return 8000;
      case AudioCodec.pcm16:
      case AudioCodec.opus:
      case AudioCodec.opusFS320:
        return 16000;
    }
  }
}

class OmiDevice {
  final String id;
  final String name;
  final DeviceType type;
  final int? rssi;

  const OmiDevice({
    required this.id,
    required this.name,
    required this.type,
    this.rssi,
  });

  factory OmiDevice.fromScanResult(dynamic scanResult) {
    return OmiDevice(
      id: scanResult.device.remoteId.str,
      name: scanResult.device.platformName,
      type: _determineDeviceType(
          scanResult.advertisementData?.serviceUuids ?? []),
      rssi: scanResult.rssi,
    );
  }

  static DeviceType _determineDeviceType(List<dynamic> services) {
    final serviceStrings =
        services.map((s) => s.toString().toLowerCase()).toList();

    if (serviceStrings.contains('19b10000-e8f2-537e-4f6c-d104768a1214')) {
      return DeviceType.omi;
    }
    if (serviceStrings.contains('7a230001-5475-a6a4-654c-8431f6ad49c4')) {
      return DeviceType.frame;
    }
    return DeviceType.unknown;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OmiDevice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'OmiDevice{id: $id, name: $name, type: $type, rssi: $rssi}';
  }
}
