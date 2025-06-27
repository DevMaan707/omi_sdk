import 'package:flutter/material.dart';
import 'package:omi_sdk/omi_sdk.dart';
import '../models/app_state.dart';
import '../services/omi_service.dart';
import '../widgets/modern_status_card.dart';
import '../widgets/floating_controls_panel.dart';
import '../widgets/device_grid.dart';
import '../widgets/audio_wave_section.dart';
import '../widgets/recordings_carousel.dart';
import '../widgets/permission_overlay.dart';
import '../theme/app_theme.dart';

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
  late AnimationController _pulseAnimationController;
  late AnimationController _pageAnimationController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _scanAnimationController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
          parent: _pulseAnimationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeOutCubic,
    ));

    if (_appState.isStreamingAudio || _appState.isStreamingTranscription) {
      _pulseAnimationController.repeat(reverse: true);
    }

    _pageAnimationController.forward();
  }

  // ... [Keep all the existing SDK integration methods unchanged] ...
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
    _updateState(
        _appState.copyWith(statusMessage: 'Requesting permissions...'));
    final granted = await _omiService.requestBluetoothPermissions();

    if (granted) {
      _updateState(_appState.copyWith(hasBluetoothPermissions: true));
      await _initializeSDK();
    } else {
      _updateState(_appState.copyWith(
        status: AppStatus.permissionsRequired,
        statusMessage: 'Permissions denied',
      ));
    }
  }

  Future<void> _initializeSDK() async {
    try {
      _updateState(_appState.copyWith(statusMessage: 'Initializing SDK...'));
      await _omiService.initializeSDK();
      _setupStreamListeners();
      _updateState(_appState.copyWith(
        status: AppStatus.ready,
        statusMessage: 'Ready to discover devices',
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

    _omiService.audioLevelsStream.listen((levels) {
      if (mounted) {
        _updateState(_appState.copyWith(audioLevels: levels));
      }
    });

    _omiService.websocketStateStream?.listen((wsState) {
      if (mounted) {
        final isConnected = wsState == WebSocketState.connected;
        _updateState(_appState.copyWith(isWebSocketConnected: isConnected));
      }
    });

    _omiService.transcriptionStream?.listen((message) {
      if (mounted && message is Map<String, dynamic>) {
        _handleTranscriptionMessage(message);
      }
    });

    _omiService.recordingStateStream?.listen((state) {
      if (mounted) {
        final isRecording = state == RecordingState.recording;
        final newStatus = isRecording
            ? AppStatus.recording
            : (_appState.isConnected ? AppStatus.connected : _appState.status);

        _updateState(_appState.copyWith(
          recordingState: state,
          isRecording: isRecording,
          status: newStatus,
        ));

        if (isRecording ||
            _appState.isStreamingAudio ||
            _appState.isStreamingTranscription) {
          _pulseAnimationController.repeat(reverse: true);
        } else {
          _pulseAnimationController.stop();
        }
      }
    });

    _omiService.recordingDurationStream?.listen((duration) {
      if (mounted) {
        _updateState(_appState.copyWith(recordingDuration: duration));
      }
    });
  }

  void _handleTranscriptionMessage(Map<String, dynamic> message) {
    try {
      final messageType = message['type'] as String?;

      switch (messageType) {
        case 'Results':
          _handleResultsMessage(message);
          break;
        case 'SpeechStarted':
          _addMessage('Speech started');
          break;
        case 'UtteranceEnd':
          _addMessage('Utterance ended');
          break;
        case 'Metadata':
          _addMessage('Session metadata received');
          break;
        default:
          _addMessage('Unknown message: $messageType');
      }
    } catch (e) {
      _addMessage('Message processing error: ${e.toString()}');
    }
  }

  void _handleResultsMessage(Map<String, dynamic> message) {
    try {
      final channelData = message['channel'];
      if (channelData == null || channelData is! Map<String, dynamic>) return;

      final channel = channelData as Map<String, dynamic>;
      final alternatives = channel['alternatives'] as List<dynamic>?;

      if (alternatives == null || alternatives.isEmpty) return;

      final firstAlternative = alternatives[0] as Map<String, dynamic>?;
      if (firstAlternative == null) return;

      final transcript = firstAlternative['transcript'] as String?;
      final isFinal = message['is_final'] as bool? ?? false;
      final speechFinal = message['speech_final'] as bool? ?? false;

      if (transcript != null && transcript.trim().isNotEmpty) {
        if (isFinal || speechFinal) {
          setState(() {
            _transcriptionText += transcript + ' ';
          });
          _updateState(_appState.copyWith(
            transcriptionText: _transcriptionText,
            interimText: '',
          ));
          _addMessage('Final: $transcript');
        } else {
          setState(() {
            _interimText = transcript;
          });
          _updateState(_appState.copyWith(interimText: _interimText));
        }
      } else {
        if (_interimText.isNotEmpty) {
          setState(() {
            _interimText = '';
          });
          _updateState(_appState.copyWith(interimText: ''));
        }
      }
    } catch (e) {
      _addMessage('Results processing error: ${e.toString()}');
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
    if (!_appState.canStartRecording) return;
    try {
      await _omiService.startRecording();
      _addMessage('Recording started');
    } catch (e) {
      _showErrorMessage('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_appState.canStopRecording) return;
    try {
      await _omiService.stopRecording();
      _addMessage('Recording stopped');
      await _loadRecordings();
    } catch (e) {
      _showErrorMessage('Failed to stop recording: $e');
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _omiService.pauseRecording();
      _addMessage('Recording paused');
    } catch (e) {
      _showErrorMessage('Failed to pause recording: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _omiService.resumeRecording();
      _addMessage('Recording resumed');
    } catch (e) {
      _showErrorMessage('Failed to resume recording: $e');
    }
  }

  Future<void> _playRecording(String filePath) async {
    try {
      await _omiService.playRecording(filePath);
      _addMessage('Playing recording');
    } catch (e) {
      _showErrorMessage('Failed to play recording: $e');
    }
  }

  Future<void> _stopPlayback() async {
    try {
      await _omiService.stopPlayback();
      _addMessage('Playback stopped');
    } catch (e) {
      _showErrorMessage('Failed to stop playback: $e');
    }
  }

  Future<void> _deleteRecording(String filePath) async {
    try {
      await _omiService.deleteRecording(filePath);
      _addMessage('Recording deleted');
      await _loadRecordings();
    } catch (e) {
      _showErrorMessage('Failed to delete recording: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Streaming methods
  Future<void> _startScan() async {
    if (!_appState.isInitialized ||
        _appState.isScanning ||
        !_appState.hasBluetoothPermissions) return;

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
            : 'Found ${_appState.allDevices.length} device(s)',
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
    if (!_appState.canStartStreaming) return;
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
    if (!_appState.canStartStreaming) return;
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
    if (!_appState.canStopStreaming) return;
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
      _showErrorMessage('Stop streaming failed: $e');
    }
  }

  Future<void> _disconnect() async {
    if (!_appState.isConnected) return;
    try {
      if (_appState.canStopStreaming) await _stopStreaming();
      if (_appState.canStopRecording) await _stopRecording();
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
      _showErrorMessage('Disconnect failed: $e');
    }
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _pulseAnimationController.dispose();
    _pageAnimationController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    _omiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.05),
                  AppTheme.accentColor.withOpacity(0.03),
                  Colors.white,
                ],
              ),
            ),
          ),

          // Main Content
          SlideTransition(
            position: _slideAnimation,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              children: [
                _buildMainPage(),
                _buildDevicesPage(),
                _buildRecordingsPage(),
              ],
            ),
          ),

          // Floating Controls Panel
          if (_appState.hasBluetoothPermissions && _appState.isInitialized)
            FloatingControlsPanel(
              appState: _appState,
              scanAnimation: _scanAnimation,
              pulseAnimation: _pulseAnimation,
              onStartScan: _startScan,
              onStartAudioStream: _startAudioStream,
              onStartTranscriptionStream: _startTranscriptionStream,
              onStopStreaming: _stopStreaming,
              onDisconnect: _disconnect,
              onStartRecording: _startRecording,
              onStopRecording: _stopRecording,
              onPauseRecording: _pauseRecording,
              onResumeRecording: _resumeRecording,
            ),

          // Permission Overlay
          if (!_appState.hasBluetoothPermissions)
            PermissionOverlay(onRequestPermissions: _requestPermissions),

          // Bottom Navigation
          if (_appState.hasBluetoothPermissions && _appState.isInitialized)
            _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildMainPage() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Modern App Bar
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          pinned: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.headset_mic,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Omi Studio',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            centerTitle: false,
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
          ),
        ),

        // Main Content
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Status Card
              ModernStatusCard(appState: _appState),
              const SizedBox(height: 20),

              // Audio Wave Section (when streaming)
              if (_appState.isStreamingAudio ||
                  _appState.isStreamingTranscription) ...[
                AudioWaveSection(
                  appState: _appState,
                  transcriptionText: _appState.transcriptionText,
                  interimText: _appState.interimText,
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 100), // Space for floating controls
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesPage() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Devices'),
          floating: true,
          backgroundColor: Colors.transparent,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              DeviceGrid(
                appState: _appState,
                onConnectToDevice: _connectToDevice,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingsPage() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('Recordings'),
          floating: true,
          backgroundColor: Colors.transparent,
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              RecordingsCarousel(
                appState: _appState,
                onPlayRecording: _playRecording,
                onStopPlayback: _stopPlayback,
                onDeleteRecording: _deleteRecording,
                onRefreshRecordings: _loadRecordings,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home, 'Home', 0),
            _buildNavItem(Icons.devices, 'Devices', 1),
            _buildNavItem(Icons.library_music, 'Recordings', 2),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentPage == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
