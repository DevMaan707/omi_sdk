import 'package:omi_sdk/omi_sdk.dart';

enum AppStatus {
  initializing,
  permissionsRequired,
  ready,
  scanning,
  connecting,
  connected,
  streamingAudio,
  streamingTranscription,
  recording,
  error,
}

class AppState {
  final AppStatus status;
  final String statusMessage;
  final bool hasBluetoothPermissions;
  final bool isInitialized;
  final bool isScanning;
  final bool isConnected;
  final bool isStreamingAudio;
  final bool isStreamingTranscription;
  final bool isRecording;
  final RecordingState recordingState;
  final Duration recordingDuration;
  final List<OmiDevice> allDevices;
  final List<OmiDevice> omiDevices;
  final OmiDevice? connectedDevice;
  final List<String> messages;
  final String transcriptionText;
  final String interimText;
  final List<double> audioLevels; // For audio visualization
  final bool isWebSocketConnected;
  final List<RecordingSession> recordings;

  const AppState({
    this.status = AppStatus.initializing,
    this.statusMessage = 'Initializing...',
    this.hasBluetoothPermissions = false,
    this.isInitialized = false,
    this.isScanning = false,
    this.isConnected = false,
    this.isStreamingAudio = false,
    this.isStreamingTranscription = false,
    this.isRecording = false,
    this.recordingState = RecordingState.idle,
    this.recordingDuration = Duration.zero,
    this.allDevices = const [],
    this.omiDevices = const [],
    this.connectedDevice,
    this.messages = const [],
    this.transcriptionText = '',
    this.interimText = '',
    this.audioLevels = const [],
    this.isWebSocketConnected = false,
    this.recordings = const [],
  });

  AppState copyWith({
    AppStatus? status,
    String? statusMessage,
    bool? hasBluetoothPermissions,
    bool? isInitialized,
    bool? isScanning,
    bool? isConnected,
    bool? isStreamingAudio,
    bool? isStreamingTranscription,
    bool? isRecording,
    RecordingState? recordingState,
    Duration? recordingDuration,
    List<OmiDevice>? allDevices,
    List<OmiDevice>? omiDevices,
    OmiDevice? connectedDevice,
    List<String>? messages,
    String? transcriptionText,
    String? interimText,
    List<double>? audioLevels,
    bool? isWebSocketConnected,
    List<RecordingSession>? recordings,
  }) {
    return AppState(
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      hasBluetoothPermissions:
          hasBluetoothPermissions ?? this.hasBluetoothPermissions,
      isInitialized: isInitialized ?? this.isInitialized,
      isScanning: isScanning ?? this.isScanning,
      isConnected: isConnected ?? this.isConnected,
      isStreamingAudio: isStreamingAudio ?? this.isStreamingAudio,
      isStreamingTranscription:
          isStreamingTranscription ?? this.isStreamingTranscription,
      isRecording: isRecording ?? this.isRecording,
      recordingState: recordingState ?? this.recordingState,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      allDevices: allDevices ?? this.allDevices,
      omiDevices: omiDevices ?? this.omiDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      messages: messages ?? this.messages,
      transcriptionText: transcriptionText ?? this.transcriptionText,
      interimText: interimText ?? this.interimText,
      audioLevels: audioLevels ?? this.audioLevels,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
      recordings: recordings ?? this.recordings,
    );
  }
}
