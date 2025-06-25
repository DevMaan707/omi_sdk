import 'dart:async';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';

class AudioManager {
  final StreamController<Uint8List> _audioDataController =
      StreamController.broadcast();
  StreamSubscription? _audioSubscription;
  bool _isStreaming = false;
  bool _isInitialized = false;

  Stream<Uint8List> get audioDataStream => _audioDataController.stream;
  bool get isStreaming => _isStreaming;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request microphone permission
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception('Microphone permission is required for audio processing');
    }

    // Initialize audio processing components
    _isInitialized = true;
  }

  Future<void> startAudioStream({
    required Future<StreamSubscription?> Function(
            {required Function(List<int>) onAudioReceived})
        getAudioStream,
  }) async {
    if (!_isInitialized) {
      throw Exception('AudioManager not initialized. Call initialize() first.');
    }

    if (_isStreaming) {
      throw Exception('Audio stream is already active');
    }

    try {
      _audioSubscription = await getAudioStream(
        onAudioReceived: (data) {
          if (!_audioDataController.isClosed && data.isNotEmpty) {
            _audioDataController.add(Uint8List.fromList(data));
          }
        },
      );

      if (_audioSubscription != null) {
        _isStreaming = true;
      } else {
        throw Exception('Failed to create audio stream subscription');
      }
    } catch (e) {
      _isStreaming = false;
      rethrow;
    }
  }

  Future<void> stopAudioStream() async {
    if (!_isStreaming) return;

    await _audioSubscription?.cancel();
    _audioSubscription = null;
    _isStreaming = false;
  }

  /// Process raw audio data (placeholder for future enhancements)
  Uint8List processAudioData(Uint8List audioData) {
    // Add any audio processing logic here (noise reduction, filtering, etc.)
    return audioData;
  }

  Future<void> dispose() async {
    await stopAudioStream();
    if (!_audioDataController.isClosed) {
      await _audioDataController.close();
    }
    _isInitialized = false;
  }
}
