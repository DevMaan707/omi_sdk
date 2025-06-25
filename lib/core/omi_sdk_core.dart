import 'dart:async';
import '../device/device_manager.dart';
import '../audio/audio_manager.dart';
import '../websocket/websocket_manager.dart';
import '../device/models.dart';
import 'config.dart';

class OmiSDK {
  static OmiSDK? _instance;
  static OmiSDK get instance =>
      _instance ?? (throw Exception('SDK not initialized'));

  late final OmiConfig _config;
  late final DeviceManager _deviceManager;
  late final AudioManager _audioManager;
  late final WebSocketManager _websocketManager;

  bool _isInitialized = false;
  StreamingMode? _currentStreamingMode;
  StreamSubscription? _audioStreamSubscription;

  OmiSDK._();

  static Future<OmiSDK> initialize(OmiConfig config) async {
    if (_instance != null) {
      throw Exception('SDK already initialized');
    }

    _instance = OmiSDK._();
    await _instance!._init(config);
    return _instance!;
  }

  Future<void> _init(OmiConfig config) async {
    _config = config;

    _deviceManager = DeviceManager();
    _audioManager = AudioManager();
    _websocketManager = WebSocketManager(config);

    // Initialize all managers
    await _deviceManager.initialize();
    await _audioManager.initialize();

    _isInitialized = true;
  }

  DeviceManager get device => _deviceManager;
  AudioManager get audio => _audioManager;
  WebSocketManager get websocket => _websocketManager;
  OmiConfig get config => _config;

  bool get isInitialized => _isInitialized;
  StreamingMode? get currentStreamingMode => _currentStreamingMode;

  /// Start audio streaming with flexible configuration
  Future<void> startAudioStreaming({
    StreamingConfig? streamingConfig,
    String? userId, // Deprecated: use streamingConfig.userId
  }) async {
    if (!device.isConnected) {
      throw Exception('No device connected. Connect to a device first.');
    }

    // Handle backward compatibility
    final config = streamingConfig ??
        StreamingConfig(
          mode: StreamingMode.transcriptionOnly,
          userId: userId,
          apiKey: _config.apiKey,
          websocketUrl: _config.apiBaseUrl,
        );

    _currentStreamingMode = config.mode;

    // Get audio codec from device
    final codec = await device.getAudioCodec();

    // Connect WebSocket if needed
    if (config.mode == StreamingMode.transcriptionOnly ||
        config.mode == StreamingMode.both) {
      await websocket.connect(
        codec: codec,
        sampleRate: codec.sampleRate,
        language: config.language,
        userId: config.userId,
        includeSpeechProfile: config.includeSpeechProfile,
        websocketUrl: config.websocketUrl,
        apiKey: config.apiKey,
        customHeaders: config.customHeaders,
        customParams: config.customParams,
      );
    }

    // Start audio stream from device
    await audio.startAudioStream(
      getAudioStream: device.getAudioStream,
    );

    // Handle audio data based on streaming mode
    _audioStreamSubscription = audio.audioDataStream.listen((audioData) {
      switch (config.mode) {
        case StreamingMode.audioOnly:
          // Audio data is available via audio.audioDataStream
          break;
        case StreamingMode.transcriptionOnly:
          websocket.sendAudio(audioData);
          break;
        case StreamingMode.both:
          websocket.sendAudio(audioData);
          // Audio data is also available via audio.audioDataStream
          break;
      }
    });
  }

  /// Start audio-only streaming (no WebSocket)
  Future<void> startAudioOnlyStreaming() async {
    await startAudioStreaming(
      streamingConfig: const StreamingConfig(mode: StreamingMode.audioOnly),
    );
  }

  /// Start transcription-only streaming
  Future<void> startTranscriptionStreaming({
    String? websocketUrl,
    String? apiKey,
    String? userId,
    String language = 'en',
    bool includeSpeechProfile = true,
    Map<String, String>? customHeaders,
    Map<String, String>? customParams,
  }) async {
    await startAudioStreaming(
      streamingConfig: StreamingConfig(
        mode: StreamingMode.transcriptionOnly,
        websocketUrl: websocketUrl ?? _config.apiBaseUrl,
        apiKey: apiKey ?? _config.apiKey,
        userId: userId,
        language: language,
        includeSpeechProfile: includeSpeechProfile,
        customHeaders: customHeaders,
        customParams: customParams,
      ),
    );
  }

  /// Start both audio and transcription streaming
  Future<void> startDualStreaming({
    String? websocketUrl,
    String? apiKey,
    String? userId,
    String language = 'en',
    bool includeSpeechProfile = true,
    Map<String, String>? customHeaders,
    Map<String, String>? customParams,
  }) async {
    await startAudioStreaming(
      streamingConfig: StreamingConfig(
        mode: StreamingMode.both,
        websocketUrl: websocketUrl ?? _config.apiBaseUrl,
        apiKey: apiKey ?? _config.apiKey,
        userId: userId,
        language: language,
        includeSpeechProfile: includeSpeechProfile,
        customHeaders: customHeaders,
        customParams: customParams,
      ),
    );
  }

  /// Stop audio streaming
  Future<void> stopAudioStreaming() async {
    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    await audio.stopAudioStream();

    if (_currentStreamingMode == StreamingMode.transcriptionOnly ||
        _currentStreamingMode == StreamingMode.both) {
      await websocket.disconnect();
    }

    _currentStreamingMode = null;
  }

  Future<void> dispose() async {
    await stopAudioStreaming();
    await _deviceManager.dispose();
    await _audioManager.dispose();
    await _websocketManager.dispose();
    _instance = null;
    _isInitialized = false;
  }

  /// Reset SDK instance (for testing)
  static Future<void> reset() async {
    if (_instance != null) {
      await _instance!.dispose();
    }
    _instance = null;
  }
}
