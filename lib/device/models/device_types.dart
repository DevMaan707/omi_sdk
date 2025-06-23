enum DeviceType {
  omi,
  frame,
  openglass,
  unknown;

  static DeviceType fromString(String value) {
    return DeviceType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DeviceType.unknown,
    );
  }

  String get displayName {
    switch (this) {
      case DeviceType.omi:
        return 'Omi Device';
      case DeviceType.frame:
        return 'Frame Device';
      case DeviceType.openglass:
        return 'OpenGlass Device';
      case DeviceType.unknown:
        return 'Unknown Device';
    }
  }

  List<String> get supportedServices {
    switch (this) {
      case DeviceType.omi:
      case DeviceType.openglass:
        return [
          '19b10000-e8f2-537e-4f6c-d104768a1214', // Omi service
          '0000180f-0000-1000-8000-00805f9b34fb', // Battery service
        ];
      case DeviceType.frame:
        return [
          '7A230001-5475-A6A4-654C-8431F6AD49C4', // Frame service
        ];
      case DeviceType.unknown:
        return [];
    }
  }
}

enum AudioCodec {
  pcm8,
  pcm16,
  opus,
  opusFS320,
  mulaw8,
  mulaw16;

  static AudioCodec fromString(String value) {
    return AudioCodec.values.firstWhere(
      (codec) => codec.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AudioCodec.opus,
    );
  }

  int get sampleRate {
    switch (this) {
      case AudioCodec.pcm8:
      case AudioCodec.mulaw8:
        return 8000;
      case AudioCodec.pcm16:
      case AudioCodec.mulaw16:
      case AudioCodec.opus:
      case AudioCodec.opusFS320:
        return 16000;
    }
  }

  int get frameSize {
    switch (this) {
      case AudioCodec.pcm8:
      case AudioCodec.mulaw8:
        return 80;
      case AudioCodec.pcm16:
      case AudioCodec.mulaw16:
      case AudioCodec.opus:
      case AudioCodec.opusFS320:
        return 160;
    }
  }

  int get framesPerSecond {
    return sampleRate ~/ frameSize;
  }

  bool get isOpusSupported {
    return this == AudioCodec.opus || this == AudioCodec.opusFS320;
  }
}
