import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as standard_ble;
import 'package:flutter_blue_plus_windows/flutter_blue_plus_windows.dart'
    as windows_ble;

/// Cross-platform Bluetooth adapter
class BluetoothAdapter {
  StreamSubscription? _scanSubscription;
  final StreamController<List<dynamic>> _scanResultsController =
      StreamController.broadcast();

  Future<void> initialize() async {
    // Initialize platform-specific Bluetooth
    if (Platform.isWindows) {
      // Windows-specific initialization if needed
    } else {
      // Standard initialization
    }
  }

  /// Check if Bluetooth is supported
  Future<bool> get isSupported {
    if (Platform.isWindows) {
      return windows_ble.FlutterBluePlus.isSupported;
    } else {
      return standard_ble.FlutterBluePlus.isSupported;
    }
  }

  /// Check if currently scanning
  bool get isScanningNow {
    if (Platform.isWindows) {
      return windows_ble.FlutterBluePlus.isScanningNow;
    } else {
      return standard_ble.FlutterBluePlus.isScanningNow;
    }
  }

  /// Stream of scan results
  Stream<List<dynamic>> get scanResults => _scanResultsController.stream;

  /// Get adapter state stream
  Stream<dynamic> get adapterState {
    if (Platform.isWindows) {
      return windows_ble.FlutterBluePlus.adapterState;
    } else {
      return standard_ble.FlutterBluePlus.adapterState;
    }
  }

  /// Start scanning for devices
  Future<void> startScan({
    Duration? timeout,
    List<String>? withServices,
  }) async {
    final services = withServices?.map(_createGuid).toList() ?? [];

    if (Platform.isWindows) {
      _scanSubscription = windows_ble.FlutterBluePlus.scanResults.listen(
        (results) => _scanResultsController.add(results),
      );

      await windows_ble.FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: services.cast<windows_ble.Guid>(),
      );
    } else {
      _scanSubscription = standard_ble.FlutterBluePlus.scanResults.listen(
        (results) => _scanResultsController.add(results),
      );

      await standard_ble.FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: services.cast<standard_ble.Guid>(),
      );
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    if (Platform.isWindows) {
      await windows_ble.FlutterBluePlus.stopScan();
    } else {
      await standard_ble.FlutterBluePlus.stopScan();
    }
  }

  /// Create a Guid from string
  dynamic _createGuid(String uuid) {
    if (Platform.isWindows) {
      return windows_ble.Guid(uuid);
    } else {
      return standard_ble.Guid(uuid);
    }
  }

  /// Get device by ID
  Future<dynamic> getDevice(String deviceId) async {
    if (Platform.isWindows) {
      return windows_ble.BluetoothDevice.fromId(deviceId);
    } else {
      return standard_ble.BluetoothDevice.fromId(deviceId);
    }
  }

  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await _scanResultsController.close();
  }
}
