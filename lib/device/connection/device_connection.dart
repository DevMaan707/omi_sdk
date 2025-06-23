import 'dart:async';
import 'dart:typed_data';
import '../models/device_models.dart';
import 'connection_state.dart';

/// Abstract base class for device connections
abstract class DeviceConnection {
  final OmiDevice device;

  DeviceConnectionState _state = DeviceConnectionState.disconnected;
  final StreamController<DeviceConnectionState> _stateController =
      StreamController.broadcast();
  final StreamController<List<int>> _audioDataController =
      StreamController.broadcast();
  final StreamController<Uint8List> _imageDataController =
      StreamController.broadcast();
  final StreamController<int> _batteryLevelController =
      StreamController.broadcast();

  DeviceConnection(this.device);

  /// Current connection state
  DeviceConnectionState get state => _state;

  /// Stream of connection state changes
  Stream<DeviceConnectionState> get stateStream => _stateController.stream;

  /// Stream of audio data from device
  Stream<List<int>> get audioDataStream => _audioDataController.stream;

  /// Stream of image data from device
  Stream<Uint8List> get imageDataStream => _imageDataController.stream;

  /// Stream of battery level updates
  Stream<int> get batteryLevelStream => _batteryLevelController.stream;

  /// Connect to the device
  Future<void> connect({Duration? timeout});

  /// Disconnect from the device
  Future<void> disconnect();

  /// Check if device is connected
  bool get isConnected => _state == DeviceConnectionState.connected;

  /// Send data to device
  Future<void> sendData(List<int> data);

  /// Get device information
  Future<Map<String, dynamic>> getDeviceInfo();

  /// Start audio streaming
  Future<void> startAudioStream();

  /// Stop audio streaming
  Future<void> stopAudioStream();

  /// Get battery level
  Future<int> getBatteryLevel();

  /// Device-specific capabilities
  Future<List<DeviceCapability>> getCapabilities();

  /// Execute device-specific command
  Future<Map<String, dynamic>> executeCommand(
    String command,
    Map<String, dynamic> parameters,
  );

  /// Update connection state
  void updateState(DeviceConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
    }
  }

  /// Emit audio data
  void emitAudioData(List<int> data) {
    _audioDataController.add(data);
  }

  /// Emit image data
  void emitImageData(Uint8List data) {
    _imageDataController.add(data);
  }

  /// Emit battery level
  void emitBatteryLevel(int level) {
    _batteryLevelController.add(level);
  }

  /// Dispose connection and cleanup resources
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _audioDataController.close();
    await _imageDataController.close();
    await _batteryLevelController.close();
  }
}

/// Device capabilities enum
enum DeviceCapability {
  audioStreaming,
  imageCapture,
  batteryMonitoring,
  firmwareUpdate,
  storageAccess,
  buttonInput,
  accelerometer,
  customCommands,
}

/// Connection exceptions
class DeviceConnectionException implements Exception {
  final String message;
  final String? deviceId;
  final dynamic originalError;

  DeviceConnectionException(this.message, {this.deviceId, this.originalError});

  @override
  String toString() =>
      'DeviceConnectionException: $message${deviceId != null ? ' (Device: $deviceId)' : ''}';
}

class DeviceTimeoutException extends DeviceConnectionException {
  DeviceTimeoutException(String deviceId)
    : super('Connection timeout', deviceId: deviceId);
}

class DeviceNotSupportedException extends DeviceConnectionException {
  DeviceNotSupportedException(String deviceId)
    : super('Device type not supported', deviceId: deviceId);
}
