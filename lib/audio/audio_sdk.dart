import 'dart:async';
import 'dart:typed_data';
import '../core/config/sdk_config.dart';
import '../core/logger/sdk_logger.dart';
import 'processors/audio_processor.dart';
import 'processors/codec_processor.dart';
import 'streaming/audio_stream.dart';
import 'formats/wav_converter.dart';

/// Audio processing subsystem
class AudioSDK {
  final SDKConfig _config;
  final SDKLogger _logger;

  late final AudioProcessor _processor;
  late final CodecProcessor _codecProcessor;
  late final WavConverter _wavConverter;

  final Map<String, AudioStream> _streams = {};

  AudioSDK({required SDKConfig config, required SDKLogger logger})
    : _config = config,
      _logger = logger;

  Future<void> initialize() async {
    _logger.info('Initializing Audio SDK...');

    _processor = AudioProcessor(config: _config.audio, logger: _logger);
    _codecProcessor = CodecProcessor(logger: _logger);
    _wavConverter = WavConverter(logger: _logger);

    await _processor.initialize();

    _logger.info('Audio SDK initialized');
  }

  /// Create audio stream
  AudioStream createStream(
    String streamId, {
    int? sampleRate,
    int? channels,
    String? codec,
  }) {
    _logger.info('Creating audio stream: $streamId');

    final stream = AudioStream(
      streamId: streamId,
      sampleRate: sampleRate ?? _config.audio.sampleRate,
      channels: channels ?? _config.audio.channels,
      codec: codec ?? _config.audio.defaultCodec,
      processor: _processor,
      logger: _logger,
    );

    _streams[streamId] = stream;
    return stream;
  }

  /// Get existing stream
  AudioStream? getStream(String streamId) {
    return _streams[streamId];
  }

  /// Remove stream
  Future<void> removeStream(String streamId) async {
    final stream = _streams[streamId];
    if (stream != null) {
      await stream.dispose();
      _streams.remove(streamId);
    }
  }

  Future<Uint8List> processAudio(
    Uint8List audioData, {
    String inputCodec = 'opus',
    String outputCodec = 'wav',
    int? sampleRate,
  }) async {
    // Decode input
    final decodedData = await _codecProcessor.decode(
      audioData,
      codec: inputCodec,
      sampleRate: sampleRate ?? _config.audio.sampleRate,
    );

    // Process if enabled
    final processedData =
        _config.audio.enableProcessing
            ? await _processor.process(decodedData)
            : decodedData;

    // Encode output
    if (outputCodec == 'wav') {
      return _wavConverter.createWavFile(
        processedData,
        sampleRate: sampleRate ?? _config.audio.sampleRate,
        channels: _config.audio.channels,
      );
    } else {
      return await _codecProcessor.encode(
        processedData,
        codec: outputCodec,
        sampleRate: sampleRate ?? _config.audio.sampleRate,
      );
    }
  }

  /// Convert audio format
  Future<Uint8List> convertAudio(
    Uint8List audioData, {
    required String fromCodec,
    required String toCodec,
    int? sampleRate,
  }) async {
    return processAudio(
      audioData,
      inputCodec: fromCodec,
      outputCodec: toCodec,
      sampleRate: sampleRate,
    );
  }

  /// Get all active streams
  List<AudioStream> get activeStreams => _streams.values.toList();

  Future<void> dispose() async {
    _logger.info('Disposing Audio SDK...');

    // Dispose all streams
    for (final stream in _streams.values) {
      await stream.dispose();
    }
    _streams.clear();

    await _processor.dispose();
  }
}
