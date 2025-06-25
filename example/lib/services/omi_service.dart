import 'package:omi_sdk/omi_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class OmiService {
  OmiSDK? _sdk;

  Stream<List<OmiDevice>>? get devicesStream => _sdk?.device.devicesStream;
  Stream<DeviceConnectionState>? get connectionStateStream =>
      _sdk?.device.connectionStateStream;

  // Change this to match the WebSocket's dynamic type
  Stream<dynamic>? get messageStream => _sdk?.websocket.messageStream;
  Stream<List<dynamic>>? get segmentsStream => _sdk?.websocket.segmentsStream;

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

  Future<void> stopAudioStreaming() async {
    if (_sdk == null) throw Exception('SDK not initialized');
    await _sdk!.stopAudioStreaming();
  }

  void dispose() {
    _sdk?.dispose();
    _sdk = null;
  }

  List<OmiDevice> filterOmiDevices(List<OmiDevice> allDevices) {
    return allDevices
        .where((device) =>
            device.name.toLowerCase().contains('omi') ||
            device.type == DeviceType.omi)
        .toList();
  }
}
