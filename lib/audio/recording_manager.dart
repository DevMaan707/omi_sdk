import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:audioplayers/audioplayers.dart';

enum RecordingState { idle, recording, paused, stopped }

class RecordingSession {
  final String id;
  final String filePath;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final int sampleRate;
  final String deviceName;

  const RecordingSession({
    required this.id,
    required this.filePath,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.sampleRate,
    required this.deviceName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration.inMilliseconds,
      'sampleRate': sampleRate,
      'deviceName': deviceName,
    };
  }

  factory RecordingSession.fromJson(Map<String, dynamic> json) {
    return RecordingSession(
      id: json['id'],
      filePath: json['filePath'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      duration: Duration(milliseconds: json['duration']),
      sampleRate: json['sampleRate'],
      deviceName: json['deviceName'],
    );
  }
}

class RecordingManager {
  RecordingState _state = RecordingState.idle;
  StreamSubscription? _audioStreamSubscription;
  File? _currentRecordingFile;
  IOSink? _currentRecordingSink;
  DateTime? _recordingStartTime;
  DateTime? _pauseStartTime;
  Duration _pausedDuration = Duration.zero;
  final List<int> _audioBuffer = [];
  int _sampleRate = 16000;
  String _deviceName = 'Unknown Device';

  final StreamController<RecordingState> _stateController =
      StreamController.broadcast();
  final StreamController<Duration> _durationController =
      StreamController.broadcast();

  AudioPlayer? _audioPlayer;
  Timer? _durationTimer;

  RecordingState get state => _state;
  Stream<RecordingState> get stateStream => _stateController.stream;
  Stream<Duration> get recordingDurationStream => _durationController.stream;

  Duration get currentRecordingDuration {
    if (_recordingStartTime == null) return Duration.zero;

    final now = DateTime.now();
    var elapsed = now.difference(_recordingStartTime!);

    // Subtract paused time
    elapsed = elapsed - _pausedDuration;

    // If currently paused, don't count the current pause time
    if (_state == RecordingState.paused && _pauseStartTime != null) {
      // Duration is frozen at pause time
      return elapsed;
    }

    return elapsed;
  }

  Future<void> initialize() async {
    _audioPlayer = AudioPlayer();
  }

  Future<String> startRecording({
    required Stream<Uint8List> audioStream,
    required int sampleRate,
    required String deviceName,
    String? customFileName,
  }) async {
    if (_state == RecordingState.recording) {
      throw Exception('Recording already in progress');
    }

    // Reset state
    _sampleRate = sampleRate;
    _deviceName = deviceName;
    _recordingStartTime = DateTime.now();
    _pauseStartTime = null;
    _pausedDuration = Duration.zero;

    // Create recording file
    final directory = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory(path.join(directory.path, 'recordings'));
    if (!recordingsDir.existsSync()) {
      recordingsDir.createSync(recursive: true);
    }

    final fileName = customFileName ??
        'recording_${DateTime.now().millisecondsSinceEpoch}.wav';
    _currentRecordingFile = File(path.join(recordingsDir.path, fileName));
    _currentRecordingSink = _currentRecordingFile!.openWrite();

    // Write WAV header (will be updated when recording stops)
    await _writeWavHeader(_currentRecordingSink!, 0, sampleRate);

    _audioBuffer.clear();

    // Listen to audio stream
    _audioStreamSubscription = audioStream.listen(
      (audioData) {
        if (_state == RecordingState.recording) {
          _audioBuffer.addAll(audioData);
          _currentRecordingSink?.add(audioData);
        }
      },
      onError: (error) {
        print('Audio stream error in recording: $error');
        _stopRecordingInternal();
        _updateState(RecordingState.idle);
      },
      onDone: () {
        print('Audio stream ended');
        _stopRecordingInternal();
        _updateState(RecordingState.idle);
      },
    );

    _updateState(RecordingState.recording);

    // Start duration timer
    _startDurationTimer();

    return _currentRecordingFile!.path;
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if ((_state == RecordingState.recording ||
              _state == RecordingState.paused) &&
          _recordingStartTime != null) {
        final duration = currentRecordingDuration;
        if (!_durationController.isClosed) {
          _durationController.add(duration);
        }
      }
    });
  }

  Future<void> pauseRecording() async {
    if (_state != RecordingState.recording) return;

    _pauseStartTime = DateTime.now();
    _updateState(RecordingState.paused);
  }

  Future<void> resumeRecording() async {
    if (_state != RecordingState.paused) return;

    if (_pauseStartTime != null) {
      _pausedDuration += DateTime.now().difference(_pauseStartTime!);
      _pauseStartTime = null;
    }

    _updateState(RecordingState.recording);
  }

  Future<RecordingSession?> stopRecording() async {
    if (_state == RecordingState.idle) return null;

    final endTime = DateTime.now();
    final duration = currentRecordingDuration;

    await _stopRecordingInternal();

    if (_currentRecordingFile != null && _currentRecordingFile!.existsSync()) {
      // Update WAV header with correct file size
      await _updateWavHeader(_currentRecordingFile!, _audioBuffer.length);

      final session = RecordingSession(
        id: path.basenameWithoutExtension(_currentRecordingFile!.path),
        filePath: _currentRecordingFile!.path,
        startTime: _recordingStartTime ?? DateTime.now(),
        endTime: endTime,
        duration: duration,
        sampleRate: _sampleRate,
        deviceName: _deviceName,
      );

      _resetRecordingState();
      return session;
    }

    _resetRecordingState();
    return null;
  }

  Future<void> _stopRecordingInternal() async {
    _durationTimer?.cancel();
    _durationTimer = null;

    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    await _currentRecordingSink?.flush();
    await _currentRecordingSink?.close();
    _currentRecordingSink = null;
  }

  void _resetRecordingState() {
    _currentRecordingFile = null;
    _recordingStartTime = null;
    _pauseStartTime = null;
    _pausedDuration = Duration.zero;
    _audioBuffer.clear();
    _updateState(RecordingState.idle);
  }

  Future<void> playRecording(String filePath) async {
    if (_audioPlayer == null) {
      throw Exception('RecordingManager not initialized');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Recording file not found: $filePath');
    }

    await _audioPlayer!.play(DeviceFileSource(filePath));
  }

  Future<void> pausePlayback() async {
    await _audioPlayer?.pause();
  }

  Future<void> resumePlayback() async {
    await _audioPlayer?.resume();
  }

  Future<void> stopPlayback() async {
    await _audioPlayer?.stop();
  }

  Future<List<RecordingSession>> getRecordings() async {
    final directory = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory(path.join(directory.path, 'recordings'));

    if (!recordingsDir.existsSync()) {
      return [];
    }

    final recordings = <RecordingSession>[];
    final files = recordingsDir
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.wav'))
        .cast<File>();

    for (final file in files) {
      try {
        final stat = file.statSync();
        final session = RecordingSession(
          id: path.basenameWithoutExtension(file.path),
          filePath: file.path,
          startTime: stat.modified,
          duration: Duration
              .zero, // Would need to parse WAV header for exact duration
          sampleRate: _sampleRate,
          deviceName: 'Unknown',
        );
        recordings.add(session);
      } catch (e) {
        print('Error processing recording file: $e');
        // Skip invalid files
      }
    }

    recordings.sort((a, b) => b.startTime.compareTo(a.startTime));
    return recordings;
  }

  Future<void> deleteRecording(String filePath) async {
    final file = File(filePath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<void> _writeWavHeader(
      IOSink sink, int dataSize, int sampleRate) async {
    final header = BytesBuilder();

    // RIFF header
    header.add('RIFF'.codeUnits);
    header.add(_int32ToBytes(36 + dataSize)); // File size - 8
    header.add('WAVE'.codeUnits);

    // Format chunk
    header.add('fmt '.codeUnits);
    header.add(_int32ToBytes(16)); // Format chunk size
    header.add(_int16ToBytes(1)); // Audio format (PCM)
    header.add(_int16ToBytes(1)); // Number of channels
    header.add(_int32ToBytes(sampleRate)); // Sample rate
    header.add(_int32ToBytes(sampleRate * 2)); // Byte rate
    header.add(_int16ToBytes(2)); // Block align
    header.add(_int16ToBytes(16)); // Bits per sample

    // Data chunk
    header.add('data'.codeUnits);
    header.add(_int32ToBytes(dataSize)); // Data size

    sink.add(header.toBytes());
  }

  Future<void> _updateWavHeader(File file, int dataSize) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length < 44) return;

      // Update file size at offset 4
      final fileSize = bytes.length - 8;
      bytes[4] = fileSize & 0xFF;
      bytes[5] = (fileSize >> 8) & 0xFF;
      bytes[6] = (fileSize >> 16) & 0xFF;
      bytes[7] = (fileSize >> 24) & 0xFF;

      // Update data size at offset 40
      final actualDataSize = bytes.length - 44;
      bytes[40] = actualDataSize & 0xFF;
      bytes[41] = (actualDataSize >> 8) & 0xFF;
      bytes[42] = (actualDataSize >> 16) & 0xFF;
      bytes[43] = (actualDataSize >> 24) & 0xFF;

      await file.writeAsBytes(bytes);
    } catch (e) {
      print('Error updating WAV header: $e');
    }
  }

  List<int> _int32ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  List<int> _int16ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
    ];
  }

  void _updateState(RecordingState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  Future<void> dispose() async {
    _durationTimer?.cancel();
    await _stopRecordingInternal();
    await _audioPlayer?.dispose();
    _audioPlayer = null;

    if (!_stateController.isClosed) {
      await _stateController.close();
    }
    if (!_durationController.isClosed) {
      await _durationController.close();
    }
  }
}
