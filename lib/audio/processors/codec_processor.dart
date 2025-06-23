import 'dart:typed_data';
import 'package:opus_dart/opus_dart.dart';
import '../../core/logger/sdk_logger.dart';
import '../models/audio_codec.dart';

class CodecProcessor {
  final SDKLogger _logger;
  final Map<String, SimpleOpusDecoder> _opusDecoders = {};
  final Map<String, SimpleOpusEncoder> _opusEncoders = {};

  CodecProcessor({required SDKLogger logger}) : _logger = logger;

  /// Decode audio data
  Future<Uint8List> decode(
    Uint8List audioData, {
    required String codec,
    required int sampleRate,
    int channels = 1,
  }) async {
    switch (codec.toLowerCase()) {
      case 'opus':
        return _decodeOpus(audioData, sampleRate, channels);
      case 'pcm8':
      case 'pcm16':
        return audioData; // PCM data is already decoded
      case 'mulaw8':
      case 'mulaw16':
        return _decodeMulaw(audioData);
      default:
        throw UnsupportedError('Codec not supported: $codec');
    }
  }

  /// Encode audio data
  Future<Uint8List> encode(
    Uint8List audioData, {
    required String codec,
    required int sampleRate,
    int channels = 1,
  }) async {
    switch (codec.toLowerCase()) {
      case 'opus':
        return _encodeOpus(audioData, sampleRate, channels);
      case 'pcm8':
      case 'pcm16':
        return audioData; // PCM data is already encoded
      case 'mulaw8':
      case 'mulaw16':
        return _encodeMulaw(audioData);
      default:
        throw UnsupportedError('Codec not supported: $codec');
    }
  }

  Uint8List _decodeOpus(Uint8List data, int sampleRate, int channels) {
    final decoderKey = '${sampleRate}_$channels';

    if (!_opusDecoders.containsKey(decoderKey)) {
      _opusDecoders[decoderKey] = SimpleOpusDecoder(
        sampleRate: sampleRate,
        channels: channels,
      );
    }

    try {
      final decoder = _opusDecoders[decoderKey]!;
      final decodedData = decoder.decode(input: data);
      return Uint8List.fromList(decodedData);
    } catch (e) {
      _logger.error('Failed to decode Opus data: $e');
      rethrow;
    }
  }

  Uint8List _encodeOpus(Uint8List data, int sampleRate, int channels) {
    final encoderKey = '${sampleRate}_$channels';

    if (!_opusEncoders.containsKey(encoderKey)) {
      _opusEncoders[encoderKey] = SimpleOpusEncoder(
        sampleRate: sampleRate,
        channels: channels,
      );
    }

    try {
      final encoder = _opusEncoders[encoderKey]!;
      final encodedData = encoder.encode(input: data);
      return Uint8List.fromList(encodedData);
    } catch (e) {
      _logger.error('Failed to encode Opus data: $e');
      rethrow;
    }
  }

  Uint8List _decodeMulaw(Uint8List data) {
    // μ-law decoder implementation
    final decoded = <int>[];
    for (final byte in data) {
      decoded.add(_mulawToLinear(byte));
    }
    return _int16ListToUint8List(Int16List.fromList(decoded));
  }

  Uint8List _encodeMulaw(Uint8List data) {
    // μ-law encoder implementation
    final int16Data = _uint8ListToInt16List(data);
    final encoded = <int>[];
    for (final sample in int16Data) {
      encoded.add(_linearToMulaw(sample));
    }
    return Uint8List.fromList(encoded);
  }

  int _mulawToLinear(int mulaw) {
    // μ-law to linear PCM conversion
    mulaw = ~mulaw;
    final int sign = (mulaw & 0x80) != 0 ? -1 : 1;
    final int exponent = (mulaw >> 4) & 0x07;
    final int mantissa = mulaw & 0x0F;
    int sample = mantissa << (exponent + 3);
    if (exponent != 0) sample += (0x84 << exponent);
    return sign * sample;
  }

  int _linearToMulaw(int sample) {
    // Linear PCM to μ-law conversion
    const int bias = 0x84;
    const int clip = 0x7F7B;

    int sign = (sample >> 8) & 0x80;
    if (sign != 0) sample = -sample;
    if (sample > clip) sample = clip;

    sample += bias;
    int exponent = 7;
    for (int i = 0x4000; (sample & i) == 0 && exponent > 0; i >>= 1) {
      exponent--;
    }

    final int mantissa = (sample >> (exponent + 3)) & 0x0F;
    final int mulaw = ~(sign | (exponent << 4) | mantissa);
    return mulaw & 0xFF;
  }

  Uint8List _int16ListToUint8List(Int16List data) {
    final byteData = ByteData(data.length * 2);
    for (int i = 0; i < data.length; i++) {
      byteData.setInt16(i * 2, data[i], Endian.little);
    }
    return byteData.buffer.asUint8List();
  }

  Int16List _uint8ListToInt16List(Uint8List data) {
    final byteData = ByteData.view(data.buffer);
    final int16Data = Int16List(data.length ~/ 2);
    for (int i = 0; i < int16Data.length; i++) {
      int16Data[i] = byteData.getInt16(i * 2, Endian.little);
    }
    return int16Data;
  }

  void dispose() {
    for (final decoder in _opusDecoders.values) {
      decoder.dispose();
    }
    for (final encoder in _opusEncoders.values) {
      encoder.dispose();
    }
    _opusDecoders.clear();
    _opusEncoders.clear();
  }
}
