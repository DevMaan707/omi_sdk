import 'dart:async';
import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:omi_sdk/omi_sdk.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class OmiService {
  OmiSDK? _sdk;
  StreamSubscription? _audioStreamSubscription;
  Timer? _audioLevelTimer;
  final Random _random = Random();

  // SDK streams - UPDATED: Removed segmentsStream
  Stream<List<OmiDevice>>? get devicesStream => _sdk?.device.devicesStream;
  Stream<DeviceConnectionState>? get connectionStateStream =>
      _sdk?.device.connectionStateStream;
  Stream<dynamic>? get messageStream => _sdk?.websocket.messageStream;

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
        Permission.microphone,
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
      return statuses.values.every((status) => status.isGranted);
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
        apiBaseUrl: 'https://api.deepgram.com',
        apiKey: 'beaf635d55b04c2e77b852090bd4dd07fb2e9a85',
        connectionTimeout: Duration(seconds: 15),
        scanTimeout: Duration(seconds: 15),
        autoReconnect: true,
        maxReconnectAttempts: 3,
      ),
    );
  }

  // UPDATED: Recording methods with proper log file handling
  Future<String> startRecording({String? customFileName}) async {
    if (_sdk == null) throw Exception('SDK not initialized');

    try {
      return await _sdk!.startRecording(customFileName: customFileName);
    } catch (e) {
      print('Failed to start recording: $e');
      rethrow;
    }
  }

  Future<RecordingSession?> stopRecording() async {
    if (_sdk == null) throw Exception('SDK not initialized');

    try {
      // UPDATED: Get log files using the new allLogFiles getter
      final logFiles = _sdk!.audio.allLogFiles;
      final logFilePath = _sdk!.audio.currentLogFilePath;

      print('Log files to share: $logFiles');
      print('Current log file: $logFilePath');

      // Stop the recording
      final session = await _sdk!.stopRecording();

      // Share logs if available
      if (logFiles.isNotEmpty) {
        await _shareLogsOnWhatsApp(logFiles);
      }

      return session;
    } catch (e) {
      print('Failed to stop recording: $e');
      rethrow;
    }
  }

  Future<void> _shareLogsOnWhatsApp(List<String> logFiles) async {
    try {
      print('Attempting to share ${logFiles.length} log files');

      // Filter existing files
      final existingFiles = logFiles.where((filePath) {
        final exists = File(filePath).existsSync();
        print('File $filePath exists: $exists');
        return exists;
      }).toList();

      if (existingFiles.isEmpty) {
        print('No log files found to share');
        return;
      }

      // Create a combined log file for easier sharing
      final combinedLogFile = await _createCombinedLogFile(existingFiles);

      if (combinedLogFile != null) {
        print('Sharing combined log file: ${combinedLogFile.path}');

        final shareResult = await Share.shareXFiles(
          [XFile(combinedLogFile.path)],
          text: 'Omi Audio Debug Logs - ${DateTime.now().toString()}',
          subject: 'Omi Audio Debug Session',
        );

        print('Share result: $shareResult');
        await _cleanupLogFiles([...existingFiles, combinedLogFile.path]);
      }
    } catch (e) {
      print('Error sharing logs: $e');
      await _cleanupLogFiles(logFiles);
    }
  }

  Future<File?> _createCombinedLogFile(List<String> logFiles) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final combinedFile =
          File('${directory.path}/omi_combined_logs_$timestamp.txt');

      final sink = combinedFile.openWrite();

      // Write header
      sink.writeln('='.padRight(80, '='));
      sink.writeln('OMI AUDIO DEBUG LOGS');
      sink.writeln('Generated: ${DateTime.now().toIso8601String()}');
      sink.writeln('Total files: ${logFiles.length}');
      sink.writeln('='.padRight(80, '='));
      sink.writeln();

      for (final logFilePath in logFiles) {
        final file = File(logFilePath);
        if (file.existsSync()) {
          final fileName = path.basename(logFilePath);
          final fileSize = await file.length();

          sink.writeln('-'.padRight(80, '-'));
          sink.writeln('FILE: $fileName');
          sink.writeln('SIZE: $fileSize bytes');
          sink.writeln('PATH: $logFilePath');
          sink.writeln('-'.padRight(80, '-'));

          if (fileName.endsWith('.log') || fileName.endsWith('.txt')) {
            try {
              final content = await file.readAsString();
              sink.writeln(content);
            } catch (e) {
              sink.writeln('Error reading file content: $e');
            }
          } else {
            sink.writeln('Binary file - content not displayed');
            sink.writeln('File type: ${fileName.split('.').last}');
          }

          sink.writeln();
          sink.writeln();
        }
      }

      sink.writeln('='.padRight(80, '='));
      sink.writeln('END OF LOG SESSION');
      sink.writeln('='.padRight(80, '='));

      await sink.close();
      return combinedFile;
    } catch (e) {
      print('Error creating combined log file: $e');
      return null;
    }
  }

  Future<void> _cleanupLogFiles(List<String> logFiles) async {
    print('Cleaning up ${logFiles.length} log files');

    for (final logFilePath in logFiles) {
      try {
        final file = File(logFilePath);
        if (file.existsSync()) {
          await file.delete();
          print('Deleted log file: $logFilePath');
        }
      } catch (e) {
        print('Error deleting log file $logFilePath: $e');
      }
    }
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

    try {
      return await _sdk!.getRecordings();
    } catch (e) {
      print('Failed to get recordings: $e');
      return [];
    }
  }

  Future<void> deleteRecording(String filePath) async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.deleteRecording(filePath);
  }

  // UPDATED: Audio streaming with proper codec detection
  Future<void> startAudioOnlyStreaming() async {
    if (_sdk == null) throw Exception('SDK not initialized');

    try {
      // Get the actual codec from the device
      final codec = await _sdk!.device.getAudioCodec();
      print('Starting audio stream with detected codec: $codec');

      await _sdk!.startAudioOnlyStreaming();

      // Listen to processed audio stream (after Opus decoding)
      _audioStreamSubscription =
          _sdk!.audio.processedAudioStream.listen((audioData) {
        _processAudioForVisualization(audioData);
      });
    } catch (e) {
      print('Failed to start audio streaming: $e');
      rethrow;
    }
  }

  // omi_sdk/example/lib/services/omi_service.dart - Update transcription method
  Future<void> startTranscriptionStreaming({String? userId}) async {
    if (_sdk == null) throw Exception('SDK not initialized');

    try {
      final codec = await _sdk!.device.getAudioCodec();
      print(
          'Starting transcription with codec: $codec (${codec.sampleRate} Hz)');

      await _sdk!.startTranscriptionStreaming(
        websocketUrl: 'wss://api.deepgram.com/v1/listen', // FIXED: Correct URL
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
          'endpointing': '300',
          'vad_events': 'true',
          'numerals': 'true',
          'search': 'true',
          'replace': 'true',
        },
      );

      // Listen to processed audio stream for visualization
      _audioStreamSubscription =
          _sdk!.audio.processedAudioStream.listen((audioData) {
        _processAudioForVisualization(audioData);
      });
    } catch (e) {
      print('Failed to start transcription streaming: $e');
      rethrow;
    }
  }

  // FIXED: Properly stop streaming to prevent log spam
  Future<void> stopStreaming() async {
    if (_sdk == null) return;

    print('Stopping all streaming...');

    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    _audioLevelTimer?.cancel();
    _audioLevelTimer = null;

    try {
      await _sdk!.stopAudioStreaming();
      print('Audio streaming stopped');
    } catch (e) {
      print('Error stopping streaming: $e');
    }
  }

  // UPDATED: Better audio visualization processing
  void _processAudioForVisualization(Uint8List audioData) {
    if (audioData.isEmpty) return;

    try {
      const int numBars = 20;
      const int bytesPerSample = 2; // 16-bit samples

      if (audioData.length < bytesPerSample) return;

      final levels = <double>[];
      final samplesPerBar = (audioData.length ~/ bytesPerSample ~/ numBars)
          .clamp(1, audioData.length ~/ bytesPerSample);

      for (int i = 0; i < numBars; i++) {
        double sum = 0;
        int sampleCount = 0;

        for (int j = 0; j < samplesPerBar; j++) {
          final sampleIndex = (i * samplesPerBar + j) * bytesPerSample;
          if (sampleIndex + 1 < audioData.length) {
            // Proper 16-bit sample extraction (little-endian)
            final sample =
                (audioData[sampleIndex + 1] << 8) | audioData[sampleIndex];
            final signedSample = sample > 32767 ? sample - 65536 : sample;

            sum += (signedSample * signedSample).toDouble();
            sampleCount++;
          }
        }

        if (sampleCount > 0) {
          final rms = math.sqrt(sum / sampleCount);
          final normalizedLevel = (rms / 32768.0).clamp(0.0, 1.0);
          final visualLevel = normalizedLevel > 0.001
              ? math.pow(normalizedLevel, 0.5).clamp(0.0, 1.0)
              : 0.0;

          levels.add(visualLevel.toDouble());
        } else {
          levels.add(0.0);
        }
      }

      if (!_audioLevelsController.isClosed) {
        _audioLevelsController.add(levels);
      }
    } catch (e) {
      print('Error processing audio for visualization: $e');
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
