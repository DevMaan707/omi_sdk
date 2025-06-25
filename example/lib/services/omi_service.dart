import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:omi_sdk/omi_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:io';

class DeepgramService {
  static const String apiKey = ''; // Replace with your actual key
  static const String serverUrl = 'wss://api.deepgram.com/v1/listen';

  WebSocketChannel? _channel;
  bool _isConnected = false;
  StreamSubscription? _audioSubscription;

  final StreamController<String> _transcriptionController =
      StreamController.broadcast();
  final StreamController<String> _interimController =
      StreamController.broadcast();
  final StreamController<bool> _connectionController =
      StreamController.broadcast();

  Stream<String> get transcriptionStream => _transcriptionController.stream;
  Stream<String> get interimStream => _interimController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    try {
      final uri = Uri.parse('$serverUrl?'
          'model=nova-2&'
          'language=en-US&'
          'smart_format=true&'
          'interim_results=true&'
          'punctuate=true&'
          'encoding=linear16&'
          'sample_rate=16000&'
          'channels=1');

      _channel = IOWebSocketChannel.connect(
        uri,
        protocols: ['token', apiKey],
      );

      await _channel!.ready;

      _channel!.stream.listen(
        (message) {
          _handleTranscriptionResult(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          _connectionController.add(false);
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          _connectionController.add(false);
        },
      );

      _isConnected = true;
      _connectionController.add(true);
    } catch (e) {
      print('Error connecting to Deepgram: $e');
      _isConnected = false;
      _connectionController.add(false);
      rethrow;
    }
  }

  void _handleTranscriptionResult(String message) {
    try {
      final result = json.decode(message);

      if (result['channel'] != null &&
          result['channel']['alternatives'] != null &&
          result['channel']['alternatives'].isNotEmpty) {
        final transcript = result['channel']['alternatives'][0]['transcript'];
        final isFinal = result['is_final'] ?? false;

        if (transcript.isNotEmpty) {
          if (isFinal) {
            _transcriptionController.add(transcript);
          } else {
            _interimController.add(transcript);
          }
        }
      }
    } catch (e) {
      print('Error parsing transcription result: $e');
    }
  }

  void sendAudio(Uint8List audioData) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(audioData);
    }
  }

  Future<void> disconnect() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _transcriptionController.close();
    _interimController.close();
    _connectionController.close();
  }
}

class OmiService {
  OmiSDK? _sdk;
  DeepgramService? _deepgramService;
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

  // Deepgram streams
  Stream<String>? get transcriptionStream =>
      _deepgramService?.transcriptionStream;
  Stream<String>? get interimStream => _deepgramService?.interimStream;
  Stream<bool>? get deepgramConnectionStream =>
      _deepgramService?.connectionStream;

  Future<bool> checkBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
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
      return bluetoothStatus.isGranted;
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
      final bluetoothStatus = await Permission.bluetooth.request();
      return bluetoothStatus.isGranted;
    }
    return true;
  }

  Future<void> initializeSDK() async {
    _sdk = await OmiSDK.initialize(
      const OmiConfig(
        apiBaseUrl: 'https://api.omi.ai',
        apiKey: 'your-api-key-here',
        connectionTimeout: Duration(seconds: 15),
        scanTimeout: Duration(seconds: 15),
        autoReconnect: true,
        maxReconnectAttempts: 3,
      ),
    );
  }

  Future<void> startAudioOnlyStreaming() async {
    if (_sdk == null) throw Exception('SDK not initialized');

    await _sdk!.startAudioOnlyStreaming();

    _audioStreamSubscription = _sdk!.audio.audioDataStream.listen((audioData) {
      _processAudioForVisualization(audioData);
    });

    // Start audio level simulation timer
    _startAudioLevelTimer();
  }

  Future<void> startTranscriptionStreaming({String? userId}) async {
    if (_sdk == null) throw Exception('SDK not initialized');

    // Initialize Deepgram service
    _deepgramService = DeepgramService();
    await _deepgramService!.connect();

    // Start audio streaming
    await _sdk!.startAudioOnlyStreaming();

    // Listen to audio stream and send to Deepgram
    _audioStreamSubscription = _sdk!.audio.audioDataStream.listen((audioData) {
      _deepgramService!.sendAudio(audioData);
      _processAudioForVisualization(audioData);
    });

    // Start audio level timer
    _startAudioLevelTimer();
  }

  void _processAudioForVisualization(Uint8List audioData) {
    // Convert audio data to levels for visualization
    // This is a simplified approach - in real implementation you'd do proper FFT
    final levels = <double>[];
    const int numBars = 20;
    int samplesPerBar = audioData.length ~/ numBars;

    for (int i = 0; i < numBars; i++) {
      double sum = 0;
      int start = i * samplesPerBar;
      int end = min(start + samplesPerBar, audioData.length);

      for (int j = start; j < end; j++) {
        sum += audioData[j].abs();
      }

      double average = sum / (end - start);
      levels.add((average / 255.0).clamp(0.0, 1.0));
    }

    if (!_audioLevelsController.isClosed) {
      _audioLevelsController.add(levels);
    }
  }

  void _startAudioLevelTimer() {
    _audioLevelTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      // Generate some mock audio levels for demo
      final levels = List.generate(20, (index) => _random.nextDouble() * 0.8);
      if (!_audioLevelsController.isClosed) {
        _audioLevelsController.add(levels);
      }
    });
  }

  Future<void> startDualStreaming({String? userId}) async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.startDualStreaming(
      userId: userId ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> startCustomStreaming({
    required StreamingConfig config,
  }) async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.startAudioStreaming(streamingConfig: config);
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

  Future<void> startAudioStreaming({required String userId}) async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.startAudioStreaming(userId: userId);
  }

  Future<void> stopStreaming() async {
    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    _audioLevelTimer?.cancel();
    _audioLevelTimer = null;

    await _deepgramService?.disconnect();
    _deepgramService = null;

    await _sdk?.stopAudioStreaming();
  }

  Future<void> stopAudioStreaming() async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.stopAudioStreaming();
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
    _deepgramService?.dispose();
    _sdk?.dispose();
  }
}
