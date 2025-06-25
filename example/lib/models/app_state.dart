import 'package:omi_sdk/omi_sdk.dart';

enum AppStatus {
  initializing,
  permissionsRequired,
  ready,
  scanning,
  connecting,
  connected,
  streaming,
  error,
}

class AppState {
  final AppStatus status;
  final String statusMessage;
  final bool hasBluetoothPermissions;
  final bool isInitialized;
  final bool isScanning;
  final bool isConnected;
  final bool isStreaming;
  final List<OmiDevice> allDevices;
  final List<OmiDevice> omiDevices;
  final OmiDevice? connectedDevice;
  final List<String> messages;

  const AppState({
    this.status = AppStatus.initializing,
    this.statusMessage = 'Initializing...',
    this.hasBluetoothPermissions = false,
    this.isInitialized = false,
    this.isScanning = false,
    this.isConnected = false,
    this.isStreaming = false,
    this.allDevices = const [],
    this.omiDevices = const [],
    this.connectedDevice,
    this.messages = const [],
  });

  AppState copyWith({
    AppStatus? status,
    String? statusMessage,
    bool? hasBluetoothPermissions,
    bool? isInitialized,
    bool? isScanning,
    bool? isConnected,
    bool? isStreaming,
    List<OmiDevice>? allDevices,
    List<OmiDevice>? omiDevices,
    OmiDevice? connectedDevice,
    List<String>? messages,
  }) {
    return AppState(
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      hasBluetoothPermissions:
          hasBluetoothPermissions ?? this.hasBluetoothPermissions,
      isInitialized: isInitialized ?? this.isInitialized,
      isScanning: isScanning ?? this.isScanning,
      isConnected: isConnected ?? this.isConnected,
      isStreaming: isStreaming ?? this.isStreaming,
      allDevices: allDevices ?? this.allDevices,
      omiDevices: omiDevices ?? this.omiDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      messages: messages ?? this.messages,
    );
  }
}
