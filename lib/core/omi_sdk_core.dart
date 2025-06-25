import 'dart:async';
import '../device/device_manager.dart';
import '../audio/audio_manager.dart';
import '../websocket/websocket_manager.dart';
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

  /// Start complete audio streaming workflow
  Future<void> startAudioStreaming({String? userId}) async {
    if (!device.isConnected) {
      throw Exception('No device connected. Connect to a device first.');
    }

    // Get audio codec from device
    final codec = await device.getAudioCodec();

    // Connect WebSocket
    await websocket.connect(
      codec: codec,
      sampleRate: codec.sampleRate,
      userId: userId,
    );

    // Start audio stream from device
    await audio.startAudioStream(
      getAudioStream: device.getAudioStream,
    );

    // Pipe audio data to WebSocket
    audio.audioDataStream.listen((audioData) {
      websocket.sendAudio(audioData);
    });
  }

  /// Stop audio streaming
  Future<void> stopAudioStreaming() async {
    await audio.stopAudioStream();
    await websocket.disconnect();
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
