import 'dart:async';
import 'dart:typed_data';
import '../../core/logger/sdk_logger.dart';
import '../processors/audio_processor.dart';

/// Audio stream handler
class AudioStream {
  final String streamId;
  final int sampleRate;
  final int channels;
  final String codec;
  final AudioProcessor _processor;
  final SDKLogger _logger;

  final StreamController<Uint8List> _dataController =
      StreamController.broadcast();
  final StreamController<AudioStreamEvent> _eventController =
      StreamController.broadcast();

  bool _isActive = false;
  int _bytesProcessed = 0;
  DateTime? _startTime;

  AudioStream({
    required this.streamId,
    required this.sampleRate,
    required this.channels,
    required this.codec,
    required AudioProcessor processor,
    required SDKLogger logger,
  }) : _processor = processor,
       _logger = logger;

  /// Stream of processed audio data
  Stream<Uint8List> get dataStream => _dataController.stream;

  /// Stream of stream events
  Stream<AudioStreamEvent> get eventStream => _eventController.stream;

  /// Check if stream is active
  bool get isActive => _isActive;

  /// Get stream statistics
  AudioStreamStats get stats => AudioStreamStats(
    streamId: streamId,
    bytesProcessed: _bytesProcessed,
    duration:
        _startTime != null
            ? DateTime.now().difference(_startTime!)
            : Duration.zero,
    sampleRate: sampleRate,
    channels: channels,
    codec: codec,
  );

  /// Start the stream
  Future<void> start() async {
    if (_isActive) return;

    _logger.info('Starting audio stream: $streamId');

    _isActive = true;
    _startTime = DateTime.now();
    _bytesProcessed = 0;

    _eventController.add(AudioStreamEvent.started(streamId));
  }

  /// Stop the stream
  Future<void> stop() async {
    if (!_isActive) return;

    _logger.info('Stopping audio stream: $streamId');

    _isActive = false;
    _eventController.add(AudioStreamEvent.stopped(streamId));
  }

  /// Process and emit audio data
  Future<void> processData(Uint8List audioData) async {
    if (!_isActive) return;

    try {
      final processedData = await _processor.process(audioData);
      _bytesProcessed += processedData.length;
      _dataController.add(processedData);
    } catch (e, stackTrace) {
      _logger.error('Error processing audio data: $e', stackTrace);
      _eventController.add(AudioStreamEvent.error(streamId, e.toString()));
    }
  }

  /// Pause the stream
  Future<void> pause() async {
    if (!_isActive) return;

    _isActive = false;
    _eventController.add(AudioStreamEvent.paused(streamId));
  }

  /// Resume the stream
  Future<void> resume() async {
    if (_isActive) return;

    _isActive = true;
    _eventController.add(AudioStreamEvent.resumed(streamId));
  }

  Future<void> dispose() async {
    await stop();
    await _dataController.close();
    await _eventController.close();
  }
}

/// Audio stream events
class AudioStreamEvent {
  final String streamId;
  final AudioStreamEventType type;
  final String? message;
  final DateTime timestamp;

  AudioStreamEvent._({
    required this.streamId,
    required this.type,
    this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AudioStreamEvent.started(String streamId) => AudioStreamEvent._(
    streamId: streamId,
    type: AudioStreamEventType.started,
  );

  factory AudioStreamEvent.stopped(String streamId) => AudioStreamEvent._(
    streamId: streamId,
    type: AudioStreamEventType.stopped,
  );

  factory AudioStreamEvent.paused(String streamId) =>
      AudioStreamEvent._(streamId: streamId, type: AudioStreamEventType.paused);

  factory AudioStreamEvent.resumed(String streamId) => AudioStreamEvent._(
    streamId: streamId,
    type: AudioStreamEventType.resumed,
  );

  factory AudioStreamEvent.error(String streamId, String message) =>
      AudioStreamEvent._(
        streamId: streamId,
        type: AudioStreamEventType.error,
        message: message,
      );
}

enum AudioStreamEventType { started, stopped, paused, resumed, error }

/// Audio stream statistics
class AudioStreamStats {
  final String streamId;
  final int bytesProcessed;
  final Duration duration;
  final int sampleRate;
  final int channels;
  final String codec;

  const AudioStreamStats({
    required this.streamId,
    required this.bytesProcessed,
    required this.duration,
    required this.sampleRate,
    required this.channels,
    required this.codec,
  });

  double get dataRateKbps =>
      duration.inMilliseconds > 0
          ? (bytesProcessed * 8) / duration.inMilliseconds
          : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'streamId': streamId,
      'bytesProcessed': bytesProcessed,
      'durationMs': duration.inMilliseconds,
      'sampleRate': sampleRate,
      'channels': channels,
      'codec': codec,
      'dataRateKbps': dataRateKbps,
    };
  }
}
