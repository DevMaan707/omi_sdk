import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/config/sdk_config.dart';
import '../../core/logger/sdk_logger.dart';

enum RecorderState { stopped, initializing, recording, paused, error }

class RecorderService {
  final SDKConfig _config;
  final SDKLogger _logger;

  FlutterSoundRecorder? _recorder;
  StreamController<Uint8List>? _audioController;

  RecorderState _state = RecorderState.stopped;
  final StreamController<RecorderState> _stateController =
      StreamController.broadcast();
  final StreamController<Uint8List> _audioDataController =
      StreamController.broadcast();

  RecorderService({required SDKConfig config, required SDKLogger logger})
    : _config = config,
      _logger = logger;

  Future<void> initialize() async {
    _logger.info('Initializing Recorder Service...');

    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();

    _logger.info('Recorder Service initialized');
  }

  /// Current recorder state
  RecorderState get state => _state;

  /// Stream of state changes
  Stream<RecorderState> get stateStream => _stateController.stream;

  /// Stream of audio data
  Stream<Uint8List> get audioDataStream => _audioDataController.stream;

  /// Start recording
  Future<void> startRecording({
    int? sampleRate,
    int? channels,
    String? codec,
  }) async {
    if (_state == RecorderState.recording) {
      _logger.warning('Recording already in progress');
      return;
    }

    try {
      _updateState(RecorderState.initializing);

      // Request microphone permission
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        throw RecorderException('Microphone permission not granted');
      }

      _audioController = StreamController<Uint8List>();

      await _recorder!.startRecorder(
        toStream: _audioController!.sink,
        codec: _getFlutterSoundCodec(codec ?? _config.audio.defaultCodec),
        sampleRate: sampleRate ?? _config.audio.sampleRate,
        numChannels: channels ?? _config.audio.channels,
      );

      // Listen to audio stream
      _audioController!.stream.listen(
        (data) => _audioDataController.add(data),
        onError: (error) {
          _logger.error('Recording stream error: $error');
          _updateState(RecorderState.error);
        },
      );

      _updateState(RecorderState.recording);
      _logger.info('Recording started');
    } catch (e) {
      _logger.error('Failed to start recording: $e');
      _updateState(RecorderState.error);
      rethrow;
    }
  }

  /// Stop recording
  Future<void> stopRecording() async {
    if (_state == RecorderState.stopped) {
      return;
    }

    try {
      await _recorder!.stopRecorder();
      await _audioController?.close();
      _audioController = null;

      _updateState(RecorderState.stopped);
      _logger.info('Recording stopped');
    } catch (e) {
      _logger.error('Failed to stop recording: $e');
      _updateState(RecorderState.error);
      rethrow;
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    if (_state != RecorderState.recording) {
      return;
    }

    try {
      await _recorder!.pauseRecorder();
      _updateState(RecorderState.paused);
      _logger.info('Recording paused');
    } catch (e) {
      _logger.error('Failed to pause recording: $e');
      rethrow;
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    if (_state != RecorderState.paused) {
      return;
    }

    try {
      await _recorder!.resumeRecorder();
      _updateState(RecorderState.recording);
      _logger.info('Recording resumed');
    } catch (e) {
      _logger.error('Failed to resume recording: $e');
      rethrow;
    }
  }

  void _updateState(RecorderState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
    }
  }

  Codec _getFlutterSoundCodec(String codecName) {
    switch (codecName.toLowerCase()) {
      case 'pcm16':
        return Codec.pcm16;
      case 'opus':
        return Codec.opusOGG;
      case 'aac':
        return Codec.aacADTS;
      default:
        return Codec.pcm16;
    }
  }

  Future<void> dispose() async {
    _logger.info('Disposing Recorder Service...');

    await stopRecording();
    await _recorder?.closeRecorder();
    await _stateController.close();
    await _audioDataController.close();
  }
}

class RecorderException implements Exception {
  final String message;
  RecorderException(this.message);

  @override
  String toString() => 'RecorderException: $message';
}
