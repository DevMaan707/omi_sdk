import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:omi_sdk/omi_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class OmiService {
  OmiSDK? _sdk;
  StreamSubscription? _audioStreamSubscription;
  Timer? _audioLevelTimer;
  final Random _random = Random();

  Stream<List<OmiDevice>>? get devicesStream => _sdk?.device.devicesStream;
  Stream<DeviceConnectionState>? get connectionStateStream =>
      _sdk?.device.connectionStateStream;
  Stream<dynamic>? get messageStream => _sdk?.websocket.messageStream;
  Stream<List<dynamic>>? get segmentsStream => _sdk?.websocket.segmentsStream;

  // Audio level stream for visualization
  final StreamController<List<double>> _audioLevelsController =
      StreamController.broadcast();
  Stream<List<double>> get audioLevelsStream => _audioLevelsController.stream;

  // WebSocket streams from SDK
  Stream<dynamic>? get transcriptionStream => _sdk?.websocket.messageStream;
  Stream<WebSocketState>? get websocketStateStream =>
      _sdk?.websocket.stateStream;

  // Recording streams
  Stream<RecordingState>? get recordingStateStream =>
      _sdk?.recording.stateStream;
  Stream<Duration>? get recordingDurationStream =>
      _sdk?.recording.recordingDurationStream;

  Future<bool> checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
        Permission.microphone, // Add microphone permission for recording
      ];

      for (final permission in permissions) {
        final status = await permission.status;
        if (!status.isGranted) {
          return false;
        }
      }
      return true;
    } else if (Platform.isIOS) {
      final bluetoothStatus = await Permission.bluetooth.status;
      final microphoneStatus = await Permission.microphone.status;
      return bluetoothStatus.isGranted && microphoneStatus.isGranted;
    }
    return true;
  }

  Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
        Permission.microphone,
      ];

      final statuses = await permissions.request();

      for (final permission in permissions) {
        final status = statuses[permission];
        if (status != PermissionStatus.granted) {
          return false;
        }
      }
      return true;
    } else if (Platform.isIOS) {
      final permissions = [Permission.bluetooth, Permission.microphone];
      final statuses = await permissions.request();

      return statuses.values.every((status) => status.isGranted);
    }
    return true;
  }

  Future<void> initializeSDK() async {
    _sdk = await OmiSDK.initialize(
      const OmiConfig(
        apiBaseUrl: 'https://api.deepgram.com', // Use Deepgram URL
        apiKey: '', // Your Deepgram API key
        connectionTimeout: Duration(seconds: 15),
        scanTimeout: Duration(seconds: 15),
        autoReconnect: true,
        maxReconnectAttempts: 3,
      ),
    );
  }

  // Recording methods
  Future<String> startRecording({String? customFileName}) async {
    if (_sdk == null) throw Exception('SDK not initialized');
    return await _sdk!.startRecording(customFileName: customFileName);
  }

  Future<RecordingSession?> stopRecording() async {
    if (_sdk == null) throw Exception('SDK not initialized');
    return await _sdk!.stopRecording();
  }

  Future<void> pauseRecording() async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.pauseRecording();
  }

  Future<void> resumeRecording() async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.resumeRecording();
  }

  Future<void> playRecording(String filePath) async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.playRecording(filePath);
  }

  Future<void> pausePlayback() async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.pausePlayback();
  }

  Future<void> resumePlayback() async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.resumePlayback();
  }

  Future<void> stopPlayback() async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.stopPlayback();
  }

  Future<List<RecordingSession>> getRecordings() async {
    if (_sdk == null) throw Exception('SDK not initialized');
    return await _sdk!.getRecordings();
  }

  Future<void> deleteRecording(String filePath) async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.deleteRecording(filePath);
  }

  Future<void> startAudioOnlyStreaming() async {
    if (_sdk == null) throw Exception('SDK not initialized');

    await _sdk!.startAudioOnlyStreaming();

    _audioStreamSubscription = _sdk!.audio.audioDataStream.listen((audioData) {
      _processAudioForVisualization(audioData);
    });
  }

  Future<void> startTranscriptionStreaming({String? userId}) async {
    if (_sdk == null) throw Exception('SDK not initialized');

    // Use the SDK's transcription streaming with Deepgram parameters
    await _sdk!.startTranscriptionStreaming(
      websocketUrl: 'wss://api.deepgram.com',
      apiKey: 'beaf635d55b04c2e77b852090bd4dd07fb2e9a85',
      userId: userId,
      language: 'en-US',
      customParams: {
        'model': 'nova-2',
        'smart_format': 'true',
        'interim_results': 'true',
        'punctuate': 'true',
        'encoding': 'linear16',
        'sample_rate': '16000',
        'channels': '1',
      },
    );

    // Listen to audio stream for visualization
    _audioStreamSubscription = _sdk!.audio.audioDataStream.listen((audioData) {
      _processAudioForVisualization(audioData);
    });
  }

  void _processAudioForVisualization(Uint8List audioData) {
    if (audioData.isEmpty) return;

    final levels = <double>[];
    const int numBars = 20;
    int samplesPerBar =
        (audioData.length ~/ numBars).clamp(1, audioData.length);

    for (int i = 0; i < numBars; i++) {
      double sum = 0;
      int start = i * samplesPerBar;
      int end = min(start + samplesPerBar, audioData.length);

      // Calculate RMS (Root Mean Square) for better audio level representation
      for (int j = start; j < end; j++) {
        // Convert to signed 16-bit value
        int sample = audioData[j];
        if (sample > 127) sample = sample - 256;
        sum += sample * sample;
      }

      double rms = sqrt(sum / (end - start));
      // Normalize to 0.0 - 1.0 range and apply some scaling
      double level = (rms / 128.0).clamp(0.0, 1.0);

      // Apply some smoothing and boost lower levels for better visualization
      level = pow(level, 0.5)
          .toDouble(); // Square root for better visual distribution
      levels.add(level);
    }

    if (!_audioLevelsController.isClosed) {
      _audioLevelsController.add(levels);
    }
  }

  Future<void> startScan({Duration? timeout}) async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.device
        .startScan(timeout: timeout ?? const Duration(seconds: 15));
  }

  Future<void> stopScan() async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.device.stopScan();
  }

  Future<void> connectToDevice(String deviceId) async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.device.connectToDevice(deviceId);
  }

  Future<void> disconnect() async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.device.disconnect();
  }

  Future<void> stopStreaming() async {
    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    _audioLevelTimer?.cancel();
    _audioLevelTimer = null;

    await _sdk?.stopAudioStreaming();
  }

  List<OmiDevice> filterOmiDevices(List<OmiDevice> allDevices) {
    return allDevices
        .where((device) =>
            device.name.toLowerCase().contains('omi') ||
            device.type == DeviceType.omi)
        .toList();
  }

  void dispose() {
    stopStreaming();
    _audioLevelsController.close();
    _sdk?.dispose();
  }
}
