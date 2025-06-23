import 'dart:async';
import 'package:flutter/foundation.dart';
import 'config/sdk_config.dart';
import 'logger/sdk_logger.dart';
import '../device/device_sdk.dart';
import '../audio/audio_sdk.dart';
import '../services/services_sdk.dart';

class OmiSDK {
  static OmiSDK? _instance;
  static OmiSDK get instance =>
      _instance ?? (throw SDKNotInitializedException());

  late final SDKConfig _config;
  late final SDKLogger _logger;
  late final DeviceSDK _deviceSDK;
  late final AudioSDK _audioSDK;
  late final ServicesSDK _servicesSDK;

  bool _isInitialized = false;

  OmiSDK._internal();

  static Future<OmiSDK> initialize(SDKConfig config) async {
    if (_instance != null) {
      throw SDKAlreadyInitializedException();
    }

    _instance = OmiSDK._internal();
    await _instance!._initialize(config);
    return _instance!;
  }

  Future<void> _initialize(SDKConfig config) async {
    if (_isInitialized) return;

    _config = config;
    _logger = SDKLogger(config.logLevel);

    _logger.info('Initializing Omi SDK...');

    _deviceSDK = DeviceSDK(config: config, logger: _logger);
    _audioSDK = AudioSDK(config: config, logger: _logger);
    _servicesSDK = ServicesSDK(config: config, logger: _logger);

    await _deviceSDK.initialize();
    await _audioSDK.initialize();
    await _servicesSDK.initialize();

    _isInitialized = true;
    _logger.info('Omi SDK initialized successfully');
  }

  DeviceSDK get device => _deviceSDK;

  AudioSDK get audio => _audioSDK;

  /// Get services subsystem
  ServicesSDK get services => _servicesSDK;

  /// Get SDK configuration
  SDKConfig get config => _config;

  /// Get SDK logger
  SDKLogger get logger => _logger;

  /// Dispose SDK and cleanup resources
  Future<void> dispose() async {
    if (!_isInitialized) return;

    _logger.info('Disposing Omi SDK...');

    await _servicesSDK.dispose();
    await _audioSDK.dispose();
    await _deviceSDK.dispose();

    _isInitialized = false;
    _instance = null;

    _logger.info('Omi SDK disposed');
  }

  bool get isInitialized => _isInitialized;
}

class SDKNotInitializedException implements Exception {
  @override
  String toString() => 'SDK not initialized. Call OmiSDK.initialize() first.';
}

class SDKAlreadyInitializedException implements Exception {
  @override
  String toString() => 'SDK already initialized.';
}
