import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/device_constants.dart';
import 'models.dart';

class DeviceManager {
  final List<OmiDevice> _discoveredDevices = [];
  final StreamController<List<OmiDevice>> _devicesController =
      StreamController.broadcast();
  final StreamController<DeviceConnectionState> _connectionStateController =
      StreamController.broadcast();

  BluetoothDevice? _connectedDevice;
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionStateSubscription;
  bool _isScanning = false;
  bool _isInitialized = false;
  Timer? _reconnectionTimer;

  List<OmiDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);
  Stream<List<OmiDevice>> get devicesStream => _devicesController.stream;
  Stream<DeviceConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  DeviceConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == DeviceConnectionState.connected;
  bool get isScanning => _isScanning;
  bool get isInitialized => _isInitialized;

  OmiDevice? get connectedDevice {
    if (_connectedDevice == null) return null;
    return _discoveredDevices.firstWhere(
      (device) => device.id == _connectedDevice!.remoteId.str,
      orElse: () => OmiDevice(
        id: _connectedDevice!.remoteId.str,
        name: _connectedDevice!.platformName,
        type: DeviceType.unknown,
      ),
    );
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check if Bluetooth is supported
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception('Bluetooth not supported by this device');
    }

    // Request Bluetooth permissions
    await _requestBluetoothPermissions();

    // Initialize Bluetooth adapter state monitoring
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.off) {
        _handleBluetoothOff();
      }
    });

    _isInitialized = true;
  }

  Future<void> _requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      // Request Android-specific permissions
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ];

      final statuses = await permissions.request();

      for (final permission in permissions) {
        if (statuses[permission] != PermissionStatus.granted) {
          throw Exception('${permission.toString()} permission is required');
        }
      }
    } else if (Platform.isIOS) {
      final bluetoothStatus = await Permission.bluetooth.request();
      if (!bluetoothStatus.isGranted) {
        throw Exception('Bluetooth permission is required');
      }
    }
  }

  void _handleBluetoothOff() {
    if (_isScanning) {
      _isScanning = false;
    }
    if (_connectionState == DeviceConnectionState.connected) {
      _updateConnectionState(DeviceConnectionState.disconnected);
    }
  }

  Future<void> startScan({Duration? timeout}) async {
    if (!_isInitialized) {
      throw Exception(
          'DeviceManager not initialized. Call initialize() first.');
    }

    if (_isScanning) {
      throw Exception('Scan is already in progress');
    }

    // Ensure Bluetooth is on
    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
        await FlutterBluePlus.adapterState
            .where((state) => state == BluetoothAdapterState.on)
            .first
            .timeout(const Duration(seconds: 10));
      } else {
        throw Exception('Bluetooth is not enabled');
      }
    }

    _discoveredDevices.clear();
    _isScanning = true;

    try {
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _discoveredDevices.clear();
        for (final result in results) {
          if (result.device.platformName.isNotEmpty) {
            _discoveredDevices.add(OmiDevice.fromScanResult(result));
          }
        }
        if (!_devicesController.isClosed) {
          _devicesController.add(List.unmodifiable(_discoveredDevices));
        }
      });

      await FlutterBluePlus.startScan(
        timeout: timeout ?? const Duration(seconds: 10),
        withServices: [
          Guid(DeviceConstants.omiServiceUuid),
          Guid(DeviceConstants.frameServiceUuid),
        ],
      );
    } catch (e) {
      _isScanning = false;
      rethrow;
    } finally {
      _isScanning = false;
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;

    await _scanSubscription?.cancel();
    _scanSubscription = null;

    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      // Ignore stop scan errors
    }

    _isScanning = false;
  }

  Future<void> connectToDevice(String deviceId) async {
    if (!_isInitialized) {
      throw Exception(
          'DeviceManager not initialized. Call initialize() first.');
    }

    if (_connectionState == DeviceConnectionState.connecting) {
      throw Exception('Connection already in progress');
    }
    if (_connectionState == DeviceConnectionState.connected) {
      throw Exception('Device already connected. Disconnect first.');
    }

    _updateConnectionState(DeviceConnectionState.connecting);

    try {
      _connectedDevice = BluetoothDevice.fromId(deviceId);

      _connectionStateSubscription?.cancel();
      _connectionStateSubscription =
          _connectedDevice!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected &&
            _connectionState == DeviceConnectionState.connected) {
          _updateConnectionState(DeviceConnectionState.disconnected);
          _handleUnexpectedDisconnection();
        }
      });

      if (Platform.isAndroid) {
        await _connectedDevice!.connect();
        if (_connectedDevice!.mtuNow < DeviceConstants.defaultMtuSize) {
          await _connectedDevice!.requestMtu(DeviceConstants.defaultMtuSize);
        }
      } else {
        await _connectedDevice!.connect();
      }

      _updateConnectionState(DeviceConnectionState.connected);
    } catch (e) {
      _connectedDevice = null;
      _updateConnectionState(DeviceConnectionState.error);
      rethrow;
    }
  }

  void _handleUnexpectedDisconnection() {
    // Implement auto-reconnection if enabled
    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(const Duration(seconds: 2), () async {
      if (_connectedDevice != null &&
          _connectionState == DeviceConnectionState.disconnected) {
        try {
          await connectToDevice(_connectedDevice!.remoteId.str);
        } catch (e) {
          // Auto-reconnection failed, user needs to manually reconnect
        }
      }
    });
  }

  Future<void> disconnect() async {
    _reconnectionTimer?.cancel();
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        // Ignore disconnect errors
      }
      _connectedDevice = null;
    }
    _updateConnectionState(DeviceConnectionState.disconnected);
  }

  Future<StreamSubscription?> getAudioStream({
    required Function(List<int>) onAudioReceived,
  }) async {
    if (!isConnected || _connectedDevice == null) {
      throw Exception('Device not connected');
    }

    try {
      final services = await _connectedDevice!.discoverServices();
      final audioService = services.firstWhere(
        (s) =>
            s.uuid.str128.toLowerCase() ==
            DeviceConstants.omiServiceUuid.toLowerCase(),
        orElse: () => throw Exception('Audio service not found'),
      );

      final audioCharacteristic = audioService.characteristics.firstWhere(
        (c) =>
            c.uuid.str128.toLowerCase() ==
            DeviceConstants.audioCharacteristicUuid.toLowerCase(),
        orElse: () => throw Exception('Audio characteristic not found'),
      );

      await audioCharacteristic.setNotifyValue(true);

      final subscription = audioCharacteristic.lastValueStream.listen((value) {
        if (value.isNotEmpty &&
            value.length > DeviceConstants.audioHeaderSize) {
          onAudioReceived(value.sublist(DeviceConstants.audioHeaderSize));
        }
      });

      _connectedDevice!.cancelWhenDisconnected(subscription);
      return subscription;
    } catch (e) {
      throw Exception('Failed to setup audio stream: $e');
    }
  }

  Future<AudioCodec> getAudioCodec() async {
    if (!isConnected || _connectedDevice == null) {
      throw Exception('Device not connected');
    }

    try {
      final services = await _connectedDevice!.discoverServices();
      final audioService = services.firstWhere(
        (s) =>
            s.uuid.str128.toLowerCase() ==
            DeviceConstants.omiServiceUuid.toLowerCase(),
        orElse: () => throw Exception('Audio service not found'),
      );

      final codecCharacteristic = audioService.characteristics.firstWhere(
        (c) =>
            c.uuid.str128.toLowerCase() ==
            DeviceConstants.codecCharacteristicUuid.toLowerCase(),
        orElse: () => throw Exception('Audio codec characteristic not found'),
      );

      final codecValue = await codecCharacteristic.read();
      if (codecValue.isNotEmpty) {
        switch (codecValue[0]) {
          case 1:
            return AudioCodec.pcm8;
          case 20:
            return AudioCodec.opus;
          case 21:
            return AudioCodec.opusFS320;
          default:
            return AudioCodec.pcm8;
        }
      }
      return AudioCodec.pcm8;
    } catch (e) {
      throw Exception('Failed to get audio codec: $e');
    }
  }

  Future<int> getBatteryLevel() async {
    if (!isConnected || _connectedDevice == null) {
      throw Exception('Device not connected');
    }

    try {
      final services = await _connectedDevice!.discoverServices();
      final batteryService = services.firstWhere(
        (s) =>
            s.uuid.str128.toLowerCase() ==
            DeviceConstants.batteryServiceUuid.toLowerCase(),
        orElse: () => throw Exception('Battery service not found'),
      );

      final batteryCharacteristic = batteryService.characteristics.firstWhere(
        (c) =>
            c.uuid.str128.toLowerCase() ==
            DeviceConstants.batteryCharacteristicUuid.toLowerCase(),
        orElse: () => throw Exception('Battery characteristic not found'),
      );

      final batteryValue = await batteryCharacteristic.read();
      return batteryValue.isNotEmpty ? batteryValue[0] : -1;
    } catch (e) {
      return -1;
    }
  }

  Future<StreamSubscription?> getBatteryLevelStream({
    required Function(int) onBatteryLevelChanged,
  }) async {
    if (!isConnected || _connectedDevice == null) {
      throw Exception('Device not connected');
    }

    try {
      final services = await _connectedDevice!.discoverServices();
      final batteryService = services.firstWhere(
        (s) =>
            s.uuid.str128.toLowerCase() ==
            '0000180f-0000-1000-8000-00805f9b34fb',
        orElse: () => throw Exception('Battery service not found'),
      );

      final batteryCharacteristic = batteryService.characteristics.firstWhere(
        (c) =>
            c.uuid.str128.toLowerCase() ==
            '00002a19-0000-1000-8000-00805f9b34fb',
        orElse: () => throw Exception('Battery characteristic not found'),
      );
      final currentValue = await batteryCharacteristic.read();
      if (currentValue.isNotEmpty) {
        onBatteryLevelChanged(currentValue[0]);
      }

      await batteryCharacteristic.setNotifyValue(true);

      final subscription =
          batteryCharacteristic.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          onBatteryLevelChanged(value[0]);
        }
      });

      _connectedDevice!.cancelWhenDisconnected(subscription);
      return subscription;
    } catch (e) {
      // Battery service not available on all devices
      return null;
    }
  }

  void _updateConnectionState(DeviceConnectionState state) {
    _connectionState = state;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }

  Future<void> dispose() async {
    _reconnectionTimer?.cancel();
    await stopScan();
    await disconnect();
    if (!_devicesController.isClosed) {
      await _devicesController.close();
    }
    if (!_connectionStateController.isClosed) {
      await _connectionStateController.close();
    }
    _isInitialized = false;
  }
}
