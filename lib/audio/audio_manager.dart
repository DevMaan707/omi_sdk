// omi_sdk/lib/audio/audio_manager.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:opus_dart/opus_dart.dart';
import 'package:opus_flutter/opus_flutter.dart' as opus_flutter;
import '../device/models.dart';

class AudioManager {
  final StreamController<Uint8List> _audioDataController =
      StreamController.broadcast();
  final StreamController<Uint8List> _processedAudioController =
      StreamController.broadcast();

  StreamSubscription? _audioSubscription;
  bool _isStreaming = false;
  bool _isInitialized = false;

  // Audio processing state
  AudioCodec? _currentCodec;
  int _sampleRate = 16000;
  int _packetsReceived = 0;
  int _framesProcessed = 0;

  // Opus decoder - using opus_dart
  SimpleOpusDecoder? _opusDecoder;
  bool _opusInitialized = false;

  // Logging files
  File? _logFile;
  File? _rawDataFile;
  File? _processedDataFile;

  Stream<Uint8List> get audioDataStream => _audioDataController.stream;
  Stream<Uint8List> get processedAudioStream =>
      _processedAudioController.stream;
  bool get isStreaming => _isStreaming;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      throw Exception('Microphone permission is required for audio processing');
    }

    // Initialize Opus
    await _initializeOpus();
    await _initializeLogging();

    _isInitialized = true;
    print('AudioManager initialized successfully');
  }

  Future<void> _initializeOpus() async {
    try {
      // Load opus library using opus_flutter
      final opusLib = await opus_flutter.load();
      initOpus(opusLib);

      print('Opus library loaded successfully');
      print('Opus version: ${getOpusVersion()}');
      _opusInitialized = true;
    } catch (e) {
      print('Failed to initialize Opus: $e');
      _opusInitialized = false;
      throw Exception('Failed to initialize Opus decoder: $e');
    }
  }

  Future<void> _initializeLogging() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/audio_logs');
      if (!logsDir.existsSync()) {
        logsDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _logFile = File('${logsDir.path}/audio_debug_$timestamp.log');
      _rawDataFile = File('${logsDir.path}/raw_audio_data_$timestamp.bin');
      _processedDataFile =
          File('${logsDir.path}/processed_audio_data_$timestamp.bin');

      await _log('=== AUDIO DEBUG SESSION STARTED ===');
      await _log('Timestamp: ${DateTime.now().toIso8601String()}');
      await _log('Opus initialized: $_opusInitialized');
      if (_opusInitialized) {
        await _log('Opus version: ${getOpusVersion()}');
      }
      print('Audio debug log: ${_logFile!.path}');
    } catch (e) {
      print('Failed to initialize logging: $e');
    }
  }

  String? get currentLogFilePath => _logFile?.path;

  // Add the missing allLogFiles getter
  List<String> get allLogFiles {
    final files = <String>[];
    if (_logFile != null) files.add(_logFile!.path);
    if (_rawDataFile != null) files.add(_rawDataFile!.path);
    if (_processedDataFile != null) files.add(_processedDataFile!.path);
    return files;
  }

  Future<void> _log(String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    print(logMessage);

    try {
      if (_logFile != null) {
        await _logFile!.writeAsString('$logMessage\n', mode: FileMode.append);
      }
    } catch (e) {
      print('Failed to write to log: $e');
    }
  }

  Future<void> startAudioStream({
    required Future<StreamSubscription?> Function({
      required Function(List<int>) onAudioReceived,
    }) getAudioStream,
    AudioCodec? codec,
  }) async {
    if (!_isInitialized) {
      throw Exception('AudioManager not initialized. Call initialize() first.');
    }

    if (_isStreaming) {
      await _log('Audio stream already active, stopping existing stream');
      await stopAudioStream();
    }

    try {
      _currentCodec = codec ?? AudioCodec.opus;
      _sampleRate = _currentCodec!.sampleRate;
      _resetProcessing();

      // Initialize Opus decoder for this stream
      if (_currentCodec == AudioCodec.opus ||
          _currentCodec == AudioCodec.opusFS320) {
        if (!_opusInitialized) {
          throw Exception('Opus not initialized. Cannot decode Opus audio.');
        }

        _opusDecoder = SimpleOpusDecoder(
          sampleRate: _sampleRate,
          channels: 1,
        );
        await _log('Opus decoder created for ${_sampleRate}Hz mono');
      }

      await _log('=== STARTING AUDIO STREAM ===');
      await _log('Codec: $_currentCodec');
      await _log('Sample rate: $_sampleRate Hz');
      await _log('=============================');

      _audioSubscription = await getAudioStream(
        onAudioReceived: (data) {
          if (!_audioDataController.isClosed && data.isNotEmpty) {
            try {
              _processAudioPacket(data);
            } catch (e) {
              _log('Error processing audio packet: $e');
            }
          }
        },
      );

      if (_audioSubscription != null) {
        _isStreaming = true;
        await _log('Audio stream started successfully');
      } else {
        throw Exception('Failed to create audio stream subscription');
      }
    } catch (e) {
      _isStreaming = false;
      await _log('Failed to start audio stream: $e');
      rethrow;
    }
  }

  void _resetProcessing() {
    _packetsReceived = 0;
    _framesProcessed = 0;
    _opusDecoder?.destroy();
    _opusDecoder = null;
    _log('Audio processing state reset');
  }

  Future<void> _processAudioPacket(List<int> packet) async {
    _packetsReceived++;

    if (packet.isEmpty) {
      return;
    }

    try {
      Uint8List audioData;

      if (_currentCodec == AudioCodec.opus ||
          _currentCodec == AudioCodec.opusFS320) {
        // Handle Opus decoding
        if (packet.length <= 3) {
          await _log('Packet too short for Opus (${packet.length} bytes)');
          return;
        }

        // Remove 3-byte header (following Python implementation)
        final opusData = packet.sublist(3);

        if (_packetsReceived <= 10) {
          await _log(
              'Opus packet ${_packetsReceived}: ${packet.length} bytes total, ${opusData.length} bytes payload');
          await _log('Header: ${packet.take(3).toList()}');
          await _log('First 10 payload bytes: ${opusData.take(10).toList()}');
        }

        // Decode Opus to PCM using opus_dart
        if (_opusDecoder != null && opusData.isNotEmpty) {
          try {
            final pcmData =
                _opusDecoder!.decode(input: Uint8List.fromList(opusData));
            if (pcmData.isNotEmpty) {
              // FIXED: Convert Int16List to Uint8List properly
              audioData = _convertInt16ListToUint8List(pcmData);
              if (_packetsReceived <= 5) {
                await _log('Decoded PCM: ${audioData.length} bytes');
                await _log(
                    'First 20 PCM bytes: ${audioData.take(20).toList()}');
              }
            } else {
              await _log(
                  'Opus decoding returned empty data for packet $_packetsReceived');
              return;
            }
          } catch (e) {
            await _log('Opus decoding failed for packet $_packetsReceived: $e');
            return;
          }
        } else {
          await _log('Opus decoder not available or empty data');
          return;
        }
      } else {
        // Handle PCM data directly
        audioData = _convertAudioData(packet);
      }

      if (audioData.isNotEmpty) {
        _framesProcessed++;

        if (!_audioDataController.isClosed) {
          _audioDataController.add(audioData);
        }
        if (!_processedAudioController.isClosed) {
          _processedAudioController.add(audioData);
        }
      }
    } catch (e) {
      await _log('Error processing audio packet: $e');
    }
  }

  // FIXED: Add method to convert Int16List to Uint8List
  Uint8List _convertInt16ListToUint8List(Int16List int16Data) {
    final byteData = ByteData(int16Data.length * 2);

    for (int i = 0; i < int16Data.length; i++) {
      // Write as little-endian 16-bit integers
      byteData.setInt16(i * 2, int16Data[i], Endian.little);
    }

    return byteData.buffer.asUint8List();
  }

  Uint8List _convertAudioData(List<int> data) {
    switch (_currentCodec) {
      case AudioCodec.pcm8:
        return _convertFrom8BitPCM(data);
      case AudioCodec.pcm16:
        return Uint8List.fromList(data);
      case AudioCodec.opus:
      case AudioCodec.opusFS320:
        // Should be handled by Opus decoder above
        return Uint8List.fromList(data);
      default:
        return Uint8List.fromList(data);
    }
  }

  Uint8List _convertFrom8BitPCM(List<int> data) {
    final result = <int>[];

    for (int sample in data) {
      // Convert unsigned 8-bit (0-255) to signed 16-bit
      int signed8 = sample - 128;
      int signed16 = signed8 * 256;
      signed16 = signed16.clamp(-32768, 32767);

      // Add as little-endian 16-bit
      result.add(signed16 & 0xFF);
      result.add((signed16 >> 8) & 0xFF);
    }

    return Uint8List.fromList(result);
  }

  // omi_sdk/lib/audio/audio_manager.dart - Add proper cleanup
  Future<void> stopAudioStream() async {
    if (!_isStreaming) return;

    await _log('=== STOPPING AUDIO STREAM ===');
    await _log('Final statistics:');
    await _log('  Packets received: $_packetsReceived');
    await _log('  Frames processed: $_framesProcessed');
    await _log('=============================');

    try {
      // FIXED: Properly cancel the audio subscription
      await _audioSubscription?.cancel();
      _audioSubscription = null;

      _isStreaming = false;
      _resetProcessing();

      // Clear the audio data controllers to stop processing
      if (!_audioDataController.isClosed) {
        // Don't close, just clear any pending data
        _audioDataController.add(Uint8List(0));
      }
      if (!_processedAudioController.isClosed) {
        _processedAudioController.add(Uint8List(0));
      }

      await _log('Audio stream stopped successfully');
    } catch (e) {
      await _log('Error stopping audio stream: $e');
      _isStreaming = false;
    }
  }

  Future<void> dispose() async {
    await stopAudioStream();

    try {
      _opusDecoder?.destroy();
      _opusDecoder = null;

      if (!_audioDataController.isClosed) {
        await _audioDataController.close();
      }
      if (!_processedAudioController.isClosed) {
        await _processedAudioController.close();
      }

      await _log('=== AUDIO DEBUG SESSION ENDED ===');
      if (_logFile != null) {
        print('Audio debug log saved to: ${_logFile!.path}');
      }
    } catch (e) {
      print('Error disposing AudioManager: $e');
    }

    _isInitialized = false;
    print('AudioManager disposed');
  }
}
