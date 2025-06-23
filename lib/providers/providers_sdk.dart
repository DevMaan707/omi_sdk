import 'package:flutter/foundation.dart';
import '../core/sdk_core.dart';
import 'device_provider.dart';

/// Providers subsystem for state management
class ProvidersSDK {
  static final Map<Type, ChangeNotifier> _providers = {};

  /// Get or create provider
  static T getProvider<T extends ChangeNotifier>() {
    if (_providers[T] != null) {
      return _providers[T] as T;
    }

    late ChangeNotifier provider;

    if (T == DeviceProvider) {
      provider = DeviceProvider();
    } else {
      throw UnsupportedError('Provider type $T not supported');
    }

    _providers[T] = provider;
    return provider as T;
  }

  /// Register custom provider
  static void registerProvider<T extends ChangeNotifier>(T provider) {
    _providers[T] = provider;
  }

  /// Dispose all providers
  static void disposeAll() {
    for (final provider in _providers.values) {
      provider.dispose();
    }
    _providers.clear();
  }
}

/// Device state provider
class DeviceProvider extends ChangeNotifier {
  final OmiSDK _sdk = OmiSDK.instance;

  List<String> _connectedDeviceIds = [];
  String? _activeDeviceId;
  bool _isScanning = false;

  List<String> get connectedDeviceIds => List.unmodifiable(_connectedDeviceIds);
  String? get activeDeviceId => _activeDeviceId;
  bool get isScanning => _isScanning;

  DeviceProvider() {
    _initialize();
  }

  void _initialize() {
    // Listen to device events
    _sdk.device.connectionEventsStream.listen(_onConnectionEvent);
  }

  Future<void> startScanning() async {
    _isScanning = true;
    notifyListeners();

    try {
      await _sdk.device.startScan();
    } catch (e) {
      _sdk.logger.error('Failed to start scanning: $e');
    }
  }

  Future<void> stopScanning() async {
    _isScanning = false;
    notifyListeners();

    await _sdk.device.stopScan();
  }

  Future<void> connectToDevice(String deviceId) async {
    try {
      await _sdk.device.connectToDevice(deviceId);
      _activeDeviceId = deviceId;
      notifyListeners();
    } catch (e) {
      _sdk.logger.error('Failed to connect to device $deviceId: $e');
      rethrow;
    }
  }

  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      await _sdk.device.disconnectFromDevice(deviceId);

      _connectedDeviceIds.remove(deviceId);
      if (_activeDeviceId == deviceId) {
        _activeDeviceId = null;
      }

      notifyListeners();
    } catch (e) {
      _sdk.logger.error('Failed to disconnect from device $deviceId: $e');
      rethrow;
    }
  }

  void _onConnectionEvent(dynamic event) {
    final deviceId = event.deviceId;

    switch (event.state) {
      case 'connected':
        if (!_connectedDeviceIds.contains(deviceId)) {
          _connectedDeviceIds.add(deviceId);
        }
        break;
      case 'disconnected':
        _connectedDeviceIds.remove(deviceId);
        if (_activeDeviceId == deviceId) {
          _activeDeviceId = null;
        }
        break;
    }

    notifyListeners();
  }
}
