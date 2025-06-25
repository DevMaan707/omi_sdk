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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final OmiService _omiService = OmiService();
  AppState _appState = const AppState();

  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkPermissions();
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

  Future<void> _startStreaming() async {
    if (!_appState.isConnected || _appState.isStreaming) return;

    try {
      _updateState(_appState.copyWith(
        isStreaming: true,
        status: AppStatus.streaming,
        statusMessage: 'Starting audio stream...',
      ));

      await _omiService.startAudioStreaming(
          userId: 'user_${DateTime.now().millisecondsSinceEpoch}');

      _updateState(_appState.copyWith(
        statusMessage: 'Audio streaming active',
      ));
    } catch (e) {
      _updateState(_appState.copyWith(
        isStreaming: false,
        status: AppStatus.connected,
        statusMessage: 'Streaming failed: $e',
      ));
    }
  }

  Future<void> _stopStreaming() async {
    if (!_appState.isStreaming) return;

    try {
      await _omiService.stopAudioStreaming();
      _updateState(_appState.copyWith(
        isStreaming: false,
        status: AppStatus.connected,
        statusMessage: 'Audio streaming stopped',
      ));
    } catch (e) {
      _updateState(_appState.copyWith(
        statusMessage: 'Stop streaming failed: $e',
      ));
    }
  }

  Future<void> _disconnect() async {
    if (!_appState.isConnected) return;

    try {
      await _omiService.disconnect();
      _updateState(_appState.copyWith(
        connectedDevice: null,
        isStreaming: false,
        status: AppStatus.ready,
        statusMessage: 'Disconnected',
      ));
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
                onStartStreaming: _startStreaming,
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
