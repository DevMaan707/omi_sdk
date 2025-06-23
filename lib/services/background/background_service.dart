import 'dart:async';
import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../../core/config/sdk_config.dart';
import '../../core/logger/sdk_logger.dart';

class BackgroundService {
  final SDKConfig _config;
  final SDKLogger _logger;

  bool _isInitialized = false;
  bool _isRunning = false;

  BackgroundService({required SDKConfig config, required SDKLogger logger})
    : _config = config,
      _logger = logger;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _logger.info('Initializing Background Service...');

    if (Platform.isAndroid || Platform.isIOS) {
      await _initializeForegroundTask();
    }

    _isInitialized = true;
    _logger.info('Background Service initialized');
  }

  Future<void> _initializeForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'omi_sdk_foreground',
        channelName: 'Omi SDK Background Service',
        channelDescription: 'Omi SDK is running in the background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000), // 5 seconds
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Start background service
  Future<void> startService({
    String title = 'Omi SDK Running',
    String description = 'Processing audio and managing device connections',
  }) async {
    if (!_isInitialized) {
      throw BackgroundServiceException('Service not initialized');
    }

    if (_isRunning) {
      _logger.warning('Background service already running');
      return;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await FlutterForegroundTask.startService(
          notificationTitle: title,
          notificationText: description,
          callback: _startCallback,
        );

        if (result is ServiceRequestSuccess) {
          _isRunning = true;
          _logger.info('Background service started successfully');
        } else {
          throw BackgroundServiceException(
            'Failed to start service: ${result.toString()}',
          );
        }
      } else {
        // For desktop platforms, we might use different approach
        _isRunning = true;
        _logger.info('Background service started (desktop mode)');
      }
    } catch (e) {
      _logger.error('Failed to start background service: $e');
      rethrow;
    }
  }

  /// Stop background service
  Future<void> stopService() async {
    if (!_isRunning) {
      return;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await FlutterForegroundTask.stopService();
      }

      _isRunning = false;
      _logger.info('Background service stopped');
    } catch (e) {
      _logger.error('Failed to stop background service: $e');
      rethrow;
    }
  }

  /// Check if service is running
  bool get isRunning => _isRunning;

  /// Send data to background task
  void sendDataToTask(Map<String, dynamic> data) {
    if (!_isRunning) {
      _logger.warning('Cannot send data: background service not running');
      return;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      FlutterForegroundTask.sendDataToTask(data);
    }
  }

  /// Listen to data from background task
  void listenToTaskData(Function(dynamic data) onData) {
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterForegroundTask.receivePort.listen(onData);
    }
  }

  Future<void> dispose() async {
    _logger.info('Disposing Background Service...');

    await stopService();
    _isInitialized = false;
  }
}

/// Background task callback
@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_BackgroundTaskHandler());
}

class _BackgroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter taskStarter) async {
    // Initialize background task
    print('Background task started at $timestamp');
  }

  @override
  void onReceiveData(Object data) {
    // Handle data from main isolate
    print('Background task received data: $data');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Periodic task execution
    print('Background task repeat event: $timestamp');

    // Send heartbeat or perform periodic tasks
    FlutterForegroundTask.sendDataToMain({
      'type': 'heartbeat',
      'timestamp': timestamp.toIso8601String(),
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // Cleanup background task
    print('Background task destroyed at $timestamp');
  }
}

class BackgroundServiceException implements Exception {
  final String message;
  BackgroundServiceException(this.message);

  @override
  String toString() => 'BackgroundServiceException: $message';
}
