import 'dart:async';
import '../core/config/sdk_config.dart';
import '../core/logger/sdk_logger.dart';
import 'models/device_models.dart';
import 'connection/device_connection.dart';
import 'connection/connection_factory.dart';
import 'discovery/device_discovery.dart';

/// Device management subsystem
class DeviceSDK {
  final SDKConfig _config;
  final SDKLogger _logger;

  late final DeviceDiscovery _discovery;
  late final DeviceConnectionFactory _connectionFactory;

  final Map<String, DeviceConnection> _connections = {};
  final StreamController<List<OmiDevice>> _devicesController =
      StreamController.broadcast();
  final StreamController<DeviceConnectionEvent> _connectionEventsController =
      StreamController.broadcast();

  DeviceSDK({required SDKConfig config, required SDKLogger logger})
    : _config = config,
      _logger = logger;

  Future<void> initialize() async {
    _logger.info('Initializing Device SDK...');

    _discovery = DeviceDiscovery(config: _config, logger: _logger);
    _connectionFactory = DeviceConnectionFactory(
      config: _config,
      logger: _logger,
    );

    await _discovery.initialize();

    // Listen to discovery events
    _discovery.devicesStream.listen(_onDevicesDiscovered);

    _logger.info('Device SDK initialized');
  }

  /// Start scanning for devices
  Future<void> startScan({
    Duration? timeout,
    List<String>? deviceTypes,
    DeviceDiscoveryFilter? filter,
  }) async {
    _logger.info('Starting device scan...');

    await _discovery.startScan(
      timeout: timeout ?? _config.device.scanTimeout,
      deviceTypes: deviceTypes ?? _config.device.allowedDeviceTypes,
      filter: filter,
    );
  }

  /// Stop scanning for devices
  Future<void> stopScan() async {
    _logger.info('Stopping device scan...');
    await _discovery.stopScan();
  }

  /// Connect to a device
  Future<DeviceConnection> connectToDevice(
    String deviceId, {
    Duration? timeout,
    bool autoReconnect = true,
  }) async {
    _logger.info('Connecting to device: $deviceId');

    if (_connections.containsKey(deviceId)) {
      final existing = _connections[deviceId]!;
      if (existing.state == DeviceConnectionState.connected) {
        return existing;
      }
    }

    final device = await _discovery.getDevice(deviceId);
    if (device == null) {
      throw DeviceNotFoundException(deviceId);
    }

    final connection = await _connectionFactory.createConnection(device);
    _connections[deviceId] = connection;

    // Listen to connection events
    connection.stateStream.listen((state) {
      _connectionEventsController.add(
        DeviceConnectionEvent(
          deviceId: deviceId,
          state: state,
          timestamp: DateTime.now(),
        ),
      );
    });

    await connection.connect(
      timeout: timeout ?? _config.device.connectionTimeout,
    );

    return connection;
  }

  /// Disconnect from a device
  Future<void> disconnectFromDevice(String deviceId) async {
    _logger.info('Disconnecting from device: $deviceId');

    final connection = _connections[deviceId];
    if (connection != null) {
      await connection.disconnect();
      _connections.remove(deviceId);
    }
  }

  /// Get all discovered devices
  List<OmiDevice> get discoveredDevices => _discovery.discoveredDevices;

  /// Get all connected devices
  List<DeviceConnection> get connectedDevices =>
      _connections.values
          .where((c) => c.state == DeviceConnectionState.connected)
          .toList();

  /// Stream of discovered devices
  Stream<List<OmiDevice>> get devicesStream => _devicesController.stream;

  /// Stream of connection events
  Stream<DeviceConnectionEvent> get connectionEventsStream =>
      _connectionEventsController.stream;

  void _onDevicesDiscovered(List<OmiDevice> devices) {
    _devicesController.add(devices);
  }

  Future<void> dispose() async {
    _logger.info('Disposing Device SDK...');

    // Disconnect all devices
    for (final connection in _connections.values) {
      await connection.disconnect();
    }
    _connections.clear();

    await _discovery.dispose();
    await _devicesController.close();
    await _connectionEventsController.close();
  }
}

class DeviceNotFoundException implements Exception {
  final String deviceId;
  DeviceNotFoundException(this.deviceId);

  @override
  String toString() => 'Device not found: $deviceId';
}

class DeviceConnectionEvent {
  final String deviceId;
  final DeviceConnectionState state;
  final DateTime timestamp;
  final String? error;

  DeviceConnectionEvent({
    required this.deviceId,
    required this.state,
    required this.timestamp,
    this.error,
  });
}
