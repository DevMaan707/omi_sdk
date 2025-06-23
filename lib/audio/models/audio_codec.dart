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

  String get displayName {
    switch (this) {
      case AudioCodec.pcm8:
        return 'PCM 8kHz';
      case AudioCodec.pcm16:
        return 'PCM 16kHz';
      case AudioCodec.opus:
        return 'Opus';
      case AudioCodec.opusFS320:
        return 'Opus FS320';
      case AudioCodec.mulaw8:
        return 'μ-law 8kHz';
      case AudioCodec.mulaw16:
        return 'μ-law 16kHz';
    }
  }
}
