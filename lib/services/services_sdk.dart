import 'dart:async';
import '../core/config/sdk_config.dart';
import '../core/logger/sdk_logger.dart';
import 'recorder/recorder_service.dart';
import 'websocket/websocket_service.dart';
import 'background/background_service.dart';

/// Services management subsystem
class ServicesSDK {
  final SDKConfig _config;
  final SDKLogger _logger;

  late final RecorderService _recorderService;
  late final WebSocketService _websocketService;
  late final BackgroundService _backgroundService;

  ServicesSDK({required SDKConfig config, required SDKLogger logger})
    : _config = config,
      _logger = logger;

  Future<void> initialize() async {
    _logger.info('Initializing Services SDK...');

    _recorderService = RecorderService(config: _config, logger: _logger);
    _websocketService = WebSocketService(config: _config, logger: _logger);
    _backgroundService = BackgroundService(config: _config, logger: _logger);

    await _recorderService.initialize();
    await _websocketService.initialize();
    await _backgroundService.initialize();

    _logger.info('Services SDK initialized');
  }

  /// Get recorder service
  RecorderService get recorder => _recorderService;

  /// Get WebSocket service
  WebSocketService get websocket => _websocketService;

  /// Get background service
  BackgroundService get background => _backgroundService;

  Future<void> dispose() async {
    _logger.info('Disposing Services SDK...');

    await _backgroundService.dispose();
    await _websocketService.dispose();
    await _recorderService.dispose();
  }
}
