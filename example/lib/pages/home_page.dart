import 'package:flutter/material.dart';
import 'package:omi_sdk/omi_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/app_state.dart';
import '../services/omi_service.dart';
import '../widgets/status_section.dart';
import '../widgets/controls_section.dart';
import '../widgets/permission_banner.dart';
import '../widgets/devices_section.dart';
import '../widgets/activity_log.dart';
import '../widgets/permission_dialog.dart';
import '../widgets/transcription_display.dart';
import '../widgets/recordings_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final OmiService _omiService = OmiService();
  AppState _appState = const AppState();
  String _transcriptionText = '';
  String _interimText = '';

  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkPermissions();
    _loadRecordings();
  }

  void _initializeAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _checkPermissions() async {
    _updateState(_appState.copyWith(
      status: AppStatus.initializing,
      statusMessage: 'Checking permissions...',
    ));

    final hasPermissions = await _omiService.checkBluetoothPermissions();

    if (hasPermissions) {
      _updateState(_appState.copyWith(hasBluetoothPermissions: true));
      await _initializeSDK();
    } else {
      _updateState(_appState.copyWith(
        status: AppStatus.permissionsRequired,
        statusMessage: 'Bluetooth permissions required',
        hasBluetoothPermissions: false,
      ));
    }
  }

  Future<void> _loadRecordings() async {
    try {
      final recordings = await _omiService.getRecordings();
      _updateState(_appState.copyWith(recordings: recordings));
    } catch (e) {
      print('Error loading recordings: $e');
    }
  }

  Future<void> _requestPermissions() async {
    _updateState(_appState.copyWith(
      statusMessage: 'Requesting permissions...',
    ));

    final granted = await _omiService.requestBluetoothPermissions();

    if (granted) {
      _updateState(_appState.copyWith(hasBluetoothPermissions: true));
      await _initializeSDK();
    } else {
      _updateState(_appState.copyWith(
        status: AppStatus.permissionsRequired,
        statusMessage: 'Permissions denied',
      ));
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => const PermissionDialog(),
    );
  }

  Future<void> _initializeSDK() async {
    try {
      _updateState(_appState.copyWith(
        statusMessage: 'Initializing SDK...',
      ));

      await _omiService.initializeSDK();
      _setupStreamListeners();

      _updateState(_appState.copyWith(
        status: AppStatus.ready,
        statusMessage: 'Ready to scan',
        isInitialized: true,
      ));
    } catch (e) {
      _updateState(_appState.copyWith(
        status: AppStatus.error,
        statusMessage: 'Failed to initialize: $e',
      ));
    }
  }

  void _setupStreamListeners() {
    _omiService.devicesStream?.listen((devices) {
      if (mounted) {
        final omiDevices = _omiService.filterOmiDevices(devices);
        _updateState(_appState.copyWith(
          allDevices: devices,
          omiDevices: omiDevices,
        ));
      }
    });

    _omiService.connectionStateStream?.listen((state) {
      if (mounted) {
        final isConnected = state == DeviceConnectionState.connected;
        _updateState(_appState.copyWith(
          isConnected: isConnected,
          status: isConnected ? AppStatus.connected : AppStatus.ready,
          statusMessage: isConnected
              ? 'Connected to ${_appState.connectedDevice?.name ?? 'device'}'
              : 'Connection: ${state.name}',
        ));
      }
    });

    _omiService.messageStream?.listen((message) {
      if (mounted) {
        _addMessage('Message: $message');
      }
    });

    _omiService.segmentsStream?.listen((segments) {
      if (mounted) {
        _addMessage('Received ${segments.length} transcript segments');
      }
    });

    _omiService.audioLevelsStream.listen((levels) {
      if (mounted) {
        _updateState(_appState.copyWith(audioLevels: levels));
      }
    });

    // WebSocket state listener
    _omiService.websocketStateStream?.listen((wsState) {
      if (mounted) {
        final isConnected = wsState == WebSocketState.connected;
        _updateState(_appState.copyWith(isWebSocketConnected: isConnected));
      }
    });

    // Transcription message listener
    _omiService.transcriptionStream?.listen((message) {
      if (mounted && message is Map<String, dynamic>) {
        _handleTranscriptionMessage(message);
      }
    });

    // Recording state listener
    _omiService.recordingStateStream?.listen((state) {
      if (mounted) {
        final isRecording = state == RecordingState.recording;
        _updateState(_appState.copyWith(
          recordingState: state,
          isRecording: isRecording,
          status: isRecording ? AppStatus.recording : _appState.status,
        ));
      }
    });

    // Recording duration listener
    _omiService.recordingDurationStream?.listen((duration) {
      if (mounted) {
        _updateState(_appState.copyWith(recordingDuration: duration));
      }
    });
  }

  void _handleTranscriptionMessage(Map<String, dynamic> message) {
    try {
      if (message['channel'] != null &&
          message['channel']['alternatives'] != null &&
          message['channel']['alternatives'].isNotEmpty) {
        final transcript = message['channel']['alternatives'][0]['transcript'];
        final isFinal = message['is_final'] ?? false;

        if (transcript != null && transcript.isNotEmpty) {
          if (isFinal) {
            setState(() {
              _transcriptionText += transcript + ' ';
            });
            _updateState(_appState.copyWith(
              transcriptionText: _transcriptionText,
              interimText: '',
            ));
          } else {
            setState(() {
              _interimText = transcript;
            });
            _updateState(_appState.copyWith(interimText: _interimText));
          }
        }
      }
    } catch (e) {
      print('Error processing transcription message: $e');
    }
  }

  void _addMessage(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final newMessages = ['$timestamp: $message', ..._appState.messages];
    if (newMessages.length > 50) {
      newMessages.removeLast();
    }
    _updateState(_appState.copyWith(messages: newMessages));
  }

  void _updateState(AppState newState) {
    if (mounted) {
      setState(() {
        _appState = newState;
      });
    }
  }

  // Recording methods
  Future<void> _startRecording() async {
    try {
      await _omiService.startRecording();
      _addMessage('Recording started');
    } catch (e) {
      _updateState(_appState.copyWith(
        statusMessage: 'Failed to start recording: $e',
      ));
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _omiService.stopRecording();
      _addMessage('Recording stopped');
      await _loadRecordings(); // Refresh recordings list
    } catch (e) {
      _updateState(_appState.copyWith(
        statusMessage: 'Failed to stop recording: $e',
      ));
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _omiService.pauseRecording();
      _addMessage('Recording paused');
    } catch (e) {
      _updateState(_appState.copyWith(
        statusMessage: 'Failed to pause recording: $e',
      ));
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _omiService.resumeRecording();
      _addMessage('Recording resumed');
    } catch (e) {
      _updateState(_appState.copyWith(
        statusMessage: 'Failed to resume recording: $e',
      ));
    }
  }

  Future<void> _playRecording(String filePath) async {
    try {
      await _omiService.playRecording(filePath);
      _addMessage('Playing recording');
    } catch (e) {
      _updateState(_appState.copyWith(
        statusMessage: 'Failed to play recording: $e',
      ));
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _omiService.stopPlayback();
      _addMessage('Playback stopped');
    } catch (e) {
      _updateState(_appState.copyWith(
        statusMessage: 'Failed to stop playback: $e',
      ));
    }
  }

  Future<void> _deleteRecording(String filePath) async {
    try {
      await _omiService.deleteRecording(filePath);
      _addMessage('Recording deleted');
      await _loadRecordings(); // Refresh recordings list
    } catch (e) {
      _updateState(_appState.copyWith(
        statusMessage: 'Failed to delete recording: $e',
      ));
    }
  }

  // Existing methods (startScan, connectToDevice, etc.) remain the same...
  Future<void> _startScan() async {
    if (!_appState.isInitialized ||
        _appState.isScanning ||
        !_appState.hasBluetoothPermissions) {
      return;
    }

    try {
      _scanAnimationController.repeat();
      _updateState(_appState.copyWith(
        isScanning: true,
        status: AppStatus.scanning,
        statusMessage: 'Scanning for devices...',
        allDevices: [],
        omiDevices: [],
      ));

      await _omiService.startScan(timeout: const Duration(seconds: 15));

      _scanAnimationController.stop();
      _updateState(_appState.copyWith(
        isScanning: false,
        status: AppStatus.ready,
        statusMessage: _appState.allDevices.isEmpty
            ? 'No devices found'
            : 'Found ${_appState.allDevices.length} device(s), ${_appState.omiDevices.length} Omi device(s)',
      ));
    } catch (e) {
      _scanAnimationController.stop();
      _updateState(_appState.copyWith(
        isScanning: false,
        status: AppStatus.error,
        statusMessage: 'Scan failed: $e',
      ));
    }
  }

  Future<void> _connectToDevice(OmiDevice device) async {
    try {
      _updateState(_appState.copyWith(
        status: AppStatus.connecting,
        statusMessage: 'Connecting to ${device.name}...',
        connectedDevice: device,
      ));

      await _omiService.connectToDevice(device.id);
    } catch (e) {
      _updateState(_appState.copyWith(
        status: AppStatus.error,
        statusMessage: 'Connection failed: $e',
        connectedDevice: null,
      ));
    }
  }

  Future<void> _startAudioStream() async {
    if (!_appState.isConnected) return;

    try {
      _updateState(_appState.copyWith(
        isStreamingAudio: true,
        status: AppStatus.streamingAudio,
        statusMessage: 'Streaming audio...',
      ));

      await _omiService.startAudioOnlyStreaming();
      _addMessage('Audio streaming started');
    } catch (e) {
      _updateState(_appState.copyWith(
        isStreamingAudio: false,
        status: AppStatus.connected,
        statusMessage: 'Audio streaming failed: $e',
      ));
    }
  }

  Future<void> _startTranscriptionStream() async {
    if (!_appState.isConnected) return;

    try {
      _updateState(_appState.copyWith(
        isStreamingTranscription: true,
        status: AppStatus.streamingTranscription,
        statusMessage: 'Streaming with transcription...',
      ));

      await _omiService.startTranscriptionStreaming(
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
      );
      _addMessage('Transcription streaming started');
    } catch (e) {
      _updateState(_appState.copyWith(
        isStreamingTranscription: false,
        status: AppStatus.connected,
        statusMessage: 'Transcription streaming failed: $e',
      ));
    }
  }

  Future<void> _stopStreaming() async {
    try {
      await _omiService.stopStreaming();
      setState(() {
        _transcriptionText = '';
        _interimText = '';
      });
      _updateState(_appState.copyWith(
        isStreamingAudio: false,
        isStreamingTranscription: false,
        status: AppStatus.connected,
        statusMessage: 'Streaming stopped',
        audioLevels: [],
        transcriptionText: '',
        interimText: '',
      ));
      _addMessage('Streaming stopped');
    } catch (e) {
      _updateState(_appState.copyWith(
        statusMessage: 'Stop streaming failed: $e',
      ));
    }
  }

  Future<void> _disconnect() async {
    if (!_appState.isConnected) return;

    try {
      if (_appState.isStreamingAudio || _appState.isStreamingTranscription) {
        await _stopStreaming();
      }

      await _omiService.disconnect();

      setState(() {
        _transcriptionText = '';
        _interimText = '';
      });

      _updateState(_appState.copyWith(
        connectedDevice: null,
        isStreamingAudio: false,
        isStreamingTranscription: false,
        isRecording: false,
        recordingState: RecordingState.idle,
        status: AppStatus.ready,
        statusMessage: 'Disconnected',
        audioLevels: [],
        transcriptionText: '',
        interimText: '',
        isWebSocketConnected: false,
      ));

      _addMessage('Disconnected from device');
    } catch (e) {
      _updateState(_appState.copyWith(
        statusMessage: 'Disconnect failed: $e',
      ));
    }
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _omiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _startScan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatusSection(appState: _appState),
              const SizedBox(height: 20),
              if (!_appState.hasBluetoothPermissions) ...[
                PermissionBanner(onRequestPermissions: _requestPermissions),
                const SizedBox(height: 20),
              ],
              ControlsSection(
                appState: _appState,
                scanAnimation: _scanAnimation,
                onStartScan: _startScan,
                onStartAudioStream: _startAudioStream,
                onStartTranscriptionStream: _startTranscriptionStream,
                onStopStreaming: _stopStreaming,
                onDisconnect: _disconnect,
              ),
              const SizedBox(height: 20),
              if (_appState.allDevices.isNotEmpty ||
                  _appState.omiDevices.isNotEmpty) ...[
                DevicesSection(
                  appState: _appState,
                  onConnectToDevice: _connectToDevice,
                ),
                const SizedBox(height: 20),
              ],
              // Recordings Section
              RecordingsSection(
                appState: _appState,
                onStartRecording: _startRecording,
                onStopRecording: _stopRecording,
                onPauseRecording: _pauseRecording,
                onResumeRecording: _resumeRecording,
                onPlayRecording: _playRecording,
                onStopPlayback: _stopPlayback,
                onDeleteRecording: _deleteRecording,
                onRefreshRecordings: _loadRecordings,
              ),
              const SizedBox(height: 20),
              // Transcription display
              if (_appState.isStreamingTranscription) ...[
                TranscriptionDisplay(
                  transcriptionText: _appState.transcriptionText,
                  interimText: _appState.interimText,
                  isConnected: _appState.isWebSocketConnected,
                ),
                const SizedBox(height: 20),
              ],
              if (_appState.messages.isNotEmpty) ...[
                ActivityLog(messages: _appState.messages),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.headset_mic,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Omi SDK',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      actions: [
        if (_appState.status != AppStatus.initializing)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _appState.isScanning ? null : () => _checkPermissions(),
            tooltip: 'Refresh',
          ),
      ],
    );
  }
}
