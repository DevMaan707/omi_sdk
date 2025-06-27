import '../constants/device_constants.dart';

enum DeviceType { omi, frame, openglass, unknown }

enum DeviceConnectionState { disconnected, connecting, connected, error }

enum StreamingMode {
  audioOnly, // Just stream audio data
  transcriptionOnly, // Stream to WebSocket for transcription
  both // Stream audio + transcription
}

// omi_sdk/lib/device/models.dart - Updated AudioCodec enum

// In omi_sdk/lib/device/models.dart - Update AudioCodec enum
enum AudioCodec {
  pcm8,
  pcm16,
  opus,
  opusFS320;

  int get sampleRate {
    switch (this) {
      case AudioCodec.pcm8:
        return 8000; // Correct for XIAO nRF52840
      case AudioCodec.pcm16:
        return 16000;
      case AudioCodec.opus:
        return 16000;
      case AudioCodec.opusFS320:
        return 16000;
    }
  }

  int get bytesPerSample {
    switch (this) {
      case AudioCodec.pcm8:
        return 1;
      case AudioCodec.pcm16:
        return 2;
      case AudioCodec.opus:
      case AudioCodec.opusFS320:
        return 2;
    }
  }
}

class StreamingConfig {
  final StreamingMode mode;
  final String? websocketUrl;
  final String? apiKey;
  final String? userId;
  final String language;
  final bool includeSpeechProfile;
  final Map<String, String>? customHeaders;
  final Map<String, String>? customParams;

  const StreamingConfig({
    this.mode = StreamingMode.audioOnly,
    this.websocketUrl,
    this.apiKey,
    this.userId,
    this.language = 'en',
    this.includeSpeechProfile = true,
    this.customHeaders,
    this.customParams,
  });

  StreamingConfig copyWith({
    StreamingMode? mode,
    String? websocketUrl,
    String? apiKey,
    String? userId,
    String? language,
    bool? includeSpeechProfile,
    Map<String, String>? customHeaders,
    Map<String, String>? customParams,
  }) {
    return StreamingConfig(
      mode: mode ?? this.mode,
      websocketUrl: websocketUrl ?? this.websocketUrl,
      apiKey: apiKey ?? this.apiKey,
      userId: userId ?? this.userId,
      language: language ?? this.language,
      includeSpeechProfile: includeSpeechProfile ?? this.includeSpeechProfile,
      customHeaders: customHeaders ?? this.customHeaders,
      customParams: customParams ?? this.customParams,
    );
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

    if (serviceStrings.contains(DeviceConstants.omiServiceUuid.toLowerCase())) {
      return DeviceType.omi;
    }
    if (serviceStrings
        .contains(DeviceConstants.frameServiceUuid.toLowerCase())) {
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
