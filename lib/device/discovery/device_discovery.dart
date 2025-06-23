import 'dart:async';
import 'dart:io';
import '../../core/config/sdk_config.dart';
import '../../core/logger/sdk_logger.dart';
import '../models/device_models.dart';
import '../models/device_types.dart';
import 'discovery_filter.dart';
import '../adapters/bluetooth_adapter.dart';

class DeviceDiscovery {
  final SDKConfig _config;
  final SDKLogger _logger;
  final BluetoothAdapter _bluetoothAdapter;

  final List<OmiDevice> _discoveredDevices = [];
  final StreamController<List<OmiDevice>> _devicesController =
      StreamController.broadcast();

  bool _isScanning = false;
  Timer? _scanTimer;
  StreamSubscription? _scanSubscription;

  DeviceDiscovery({required SDKConfig config, required SDKLogger logger})
    : _config = config,
      _logger = logger,
      _bluetoothAdapter = BluetoothAdapter();

  Future<void> initialize() async {
    _logger.info('Initializing Device Discovery...');

    await _bluetoothAdapter.initialize();

    _logger.info('Device Discovery initialized');
  }

  Future<void> startScan({
    Duration? timeout,
    List<String>? deviceTypes,
    DeviceDiscoveryFilter? filter,
  }) async {
    if (_isScanning) {
      _logger.warning('Scan already in progress');
      return;
    }

    _logger.info('Starting device scan...');
    _isScanning = true;
    _discoveredDevices.clear();

    try {
      // Set up scan timeout
      if (timeout != null) {
        _scanTimer = Timer(timeout, () async {
          _logger.info('Scan timeout reached');
          await stopScan();
        });
      }

      // Start listening to scan results
      _scanSubscription = _bluetoothAdapter.scanResults.listen(
        (results) => _processScanResults(results, filter),
        onError: (error) {
          _logger.error('Scan error: $error');
          _isScanning = false;
        },
      );

      // Start actual scanning
      await _bluetoothAdapter.startScan(
        withServices: _getServiceUuids(deviceTypes),
        timeout: timeout,
      );
    } catch (e) {
      _logger.error('Failed to start scan: $e');
      _isScanning = false;
      rethrow;
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;

    _logger.info('Stopping device scan...');

    _scanTimer?.cancel();
    _scanTimer = null;

    await _scanSubscription?.cancel();
    _scanSubscription = null;

    await _bluetoothAdapter.stopScan();
    _isScanning = false;
  }

  void _processScanResults(
    List<dynamic> results,
    DeviceDiscoveryFilter? filter,
  ) {
    final newDevices = <OmiDevice>[];

    for (final result in results) {
      try {
        final device = _createDeviceFromScanResult(result);
        if (device != null && _shouldIncludeDevice(device, filter)) {
          // Check if device already exists
          final existingIndex = _discoveredDevices.indexWhere(
            (d) => d.id == device.id,
          );
          if (existingIndex >= 0) {
            _discoveredDevices[existingIndex] = device; // Update existing
          } else {
            _discoveredDevices.add(device);
            newDevices.add(device);
          }
        }
      } catch (e) {
        _logger.error('Error processing scan result: $e');
      }
    }

    if (newDevices.isNotEmpty) {
      _logger.debug('Found ${newDevices.length} new devices');
      _devicesController.add(List.from(_discoveredDevices));
    }
  }

  OmiDevice? _createDeviceFromScanResult(dynamic scanResult) {
    try {
      // Extract device information from scan result
      final deviceId = scanResult.device?.remoteId?.str ?? '';
      final deviceName = scanResult.device?.platformName ?? 'Unknown Device';
      final rssi = scanResult.rssi ?? 0;

      if (deviceId.isEmpty) return null;

      // Determine device type from advertised services
      final services = scanResult.advertisementData?.serviceUuids ?? [];
      final deviceType = _determineDeviceType(services);

      final deviceData = {
        'id': deviceId,
        'name': deviceName,
        'type': deviceType.name,
        'rssi': rssi,
        'services': services.map((s) => s.toString()).toList(),
        'metadata': {
          'manufacturerData':
              scanResult.advertisementData?.manufacturerData ?? {},
          'serviceData': scanResult.advertisementData?.serviceData ?? {},
          'txPowerLevel': scanResult.advertisementData?.txPowerLevel,
        },
      };

      return OmiDevice.fromScanResult(deviceData);
    } catch (e) {
      _logger.error('Failed to create device from scan result: $e');
      return null;
    }
  }

  DeviceType _determineDeviceType(List<dynamic> services) {
    final serviceStrings =
        services.map((s) => s.toString().toLowerCase()).toList();

    // Check for Omi/OpenGlass service
    if (serviceStrings.contains('19b10000-e8f2-537e-4f6c-d104768a1214')) {
      return DeviceType.omi;
    }

    // Check for Frame service
    if (serviceStrings.contains('7a230001-5475-a6a4-654c-8431f6ad49c4')) {
      return DeviceType.frame;
    }

    return DeviceType.unknown;
  }

  bool _shouldIncludeDevice(OmiDevice device, DeviceDiscoveryFilter? filter) {
    if (filter == null) return true;

    // Apply filters
    if (filter.deviceTypes != null &&
        !filter.deviceTypes!.contains(device.type)) {
      return false;
    }

    if (filter.namePattern != null &&
        !device.name.contains(filter.namePattern!)) {
      return false;
    }

    if (filter.minRssi != null && (device.rssi ?? -100) < filter.minRssi!) {
      return false;
    }

    if (filter.customFilter != null && !filter.customFilter!(device)) {
      return false;
    }

    return true;
  }

  List<String> _getServiceUuids(List<String>? deviceTypes) {
    if (deviceTypes == null || deviceTypes.isEmpty) {
      // Return all supported service UUIDs
      return DeviceType.values
          .expand((type) => type.supportedServices)
          .toList();
    }

    return deviceTypes
        .map((name) => DeviceType.fromString(name))
        .expand((type) => type.supportedServices)
        .toList();
  }

  List<OmiDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);
  Stream<List<OmiDevice>> get devicesStream => _devicesController.stream;
  bool get isScanning => _isScanning;

  Future<OmiDevice?> getDevice(String deviceId) async {
    return _discoveredDevices.firstWhere(
      (device) => device.id == deviceId,
      orElse: () => throw DeviceNotFoundException(deviceId),
    );
  }

  Future<void> dispose() async {
    await stopScan();
    await _devicesController.close();
    await _bluetoothAdapter.dispose();
  }
}

class DeviceNotFoundException implements Exception {
  final String deviceId;
  DeviceNotFoundException(this.deviceId);

  @override
  String toString() => 'Device not found: $deviceId';
}
