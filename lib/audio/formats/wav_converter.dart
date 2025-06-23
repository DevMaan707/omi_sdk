import 'dart:typed_data';
import '../../core/logger/sdk_logger.dart';

class WavConverter {
  final SDKLogger _logger;

  WavConverter({required SDKLogger logger}) : _logger = logger;

  /// Create WAV file from PCM data
  Uint8List createWavFile(
    Uint8List pcmData, {
    required int sampleRate,
    required int channels,
    int bitsPerSample = 16,
  }) {
    try {
      final wavHeader = _createWavHeader(
        dataLength: pcmData.length,
        sampleRate: sampleRate,
        channels: channels,
        bitsPerSample: bitsPerSample,
      );

      // Combine header and data
      final wavFile = BytesBuilder();
      wavFile.add(wavHeader);
      wavFile.add(pcmData);

      return wavFile.toBytes();
    } catch (e) {
      _logger.error('Failed to create WAV file: $e');
      rethrow;
    }
  }

  /// Parse WAV file and extract PCM data
  WavFileInfo parseWavFile(Uint8List wavData) {
    try {
      if (wavData.length < 44) {
        throw FormatException('Invalid WAV file: too short');
      }

      final byteData = ByteData.view(wavData.buffer);

      // Check RIFF header
      final riffHeader = String.fromCharCodes(wavData.sublist(0, 4));
      if (riffHeader != 'RIFF') {
        throw FormatException('Invalid WAV file: missing RIFF header');
      }

      // Check WAVE format
      final waveHeader = String.fromCharCodes(wavData.sublist(8, 12));
      if (waveHeader != 'WAVE') {
        throw FormatException('Invalid WAV file: not WAVE format');
      }

      // Read format chunk
      final audioFormat = byteData.getUint16(20, Endian.little);
      final channels = byteData.getUint16(22, Endian.little);
      final sampleRate = byteData.getUint32(24, Endian.little);
      final bitsPerSample = byteData.getUint16(34, Endian.little);

      // Find data chunk
      int dataStart = 44;
      while (dataStart < wavData.length - 8) {
        final chunkId = String.fromCharCodes(
          wavData.sublist(dataStart, dataStart + 4),
        );
        final chunkSize = byteData.getUint32(dataStart + 4, Endian.little);

        if (chunkId == 'data') {
          dataStart += 8;
          break;
        }

        dataStart += 8 + chunkSize;
      }

      if (dataStart >= wavData.length) {
        throw FormatException('Invalid WAV file: no data chunk found');
      }

      final pcmData = wavData.sublist(dataStart);

      return WavFileInfo(
        sampleRate: sampleRate,
        channels: channels,
        bitsPerSample: bitsPerSample,
        audioFormat: audioFormat,
        pcmData: pcmData,
      );
    } catch (e) {
      _logger.error('Failed to parse WAV file: $e');
      rethrow;
    }
  }

  Uint8List _createWavHeader({
    required int dataLength,
    required int sampleRate,
    required int channels,
    required int bitsPerSample,
  }) {
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final chunkSize = 36 + dataLength;

    final header = ByteData(44);

    // RIFF chunk
    header.setUint8(0, 0x52); // 'R'
    header.setUint8(1, 0x49); // 'I'
    header.setUint8(2, 0x46); // 'F'
    header.setUint8(3, 0x46); // 'F'
    header.setUint32(4, chunkSize, Endian.little);
    header.setUint8(8, 0x57); // 'W'
    header.setUint8(9, 0x41); // 'A'
    header.setUint8(10, 0x56); // 'V'
    header.setUint8(11, 0x45); // 'E'

    // fmt chunk
    header.setUint8(12, 0x66); // 'f'
    header.setUint8(13, 0x6D); // 'm'
    header.setUint8(14, 0x74); // 't'
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // Subchunk1Size
    header.setUint16(20, 1, Endian.little); // AudioFormat (PCM)
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);

    // data chunk
    header.setUint8(36, 0x64); // 'd'
    header.setUint8(37, 0x61); // 'a'
    header.setUint8(38, 0x74); // 't'
    header.setUint8(39, 0x61); // 'a'
    header.setUint32(40, dataLength, Endian.little);

    return header.buffer.asUint8List();
  }
}

class WavFileInfo {
  final int sampleRate;
  final int channels;
  final int bitsPerSample;
  final int audioFormat;
  final Uint8List pcmData;

  const WavFileInfo({
    required this.sampleRate,
    required this.channels,
    required this.bitsPerSample,
    required this.audioFormat,
    required this.pcmData,
  });

  Duration get duration {
    final bytesPerSample = bitsPerSample ~/ 8;
    final totalSamples = pcmData.length ~/ (channels * bytesPerSample);
    final durationSeconds = totalSamples / sampleRate;
    return Duration(milliseconds: (durationSeconds * 1000).round());
  }

  @override
  String toString() {
    return 'WavFileInfo(sampleRate: $sampleRate, channels: $channels, '
        'bitsPerSample: $bitsPerSample, duration: $duration)';
  }
}
