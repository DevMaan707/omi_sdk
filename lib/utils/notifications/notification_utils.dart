import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../../core/config/sdk_config.dart';
import '../../core/logger/sdk_logger.dart';
import '../platform/platform_utils.dart';

class NotificationUtils {
  final SDKConfig _config;
  final SDKLogger _logger;
  late NotificationProvider _provider;

  NotificationUtils({required SDKConfig config, required SDKLogger logger})
    : _config = config,
      _logger = logger;

  /// Initialize notification utils
  Future<void> initialize() async {
    _logger.info('Initializing Notification Utils...');

    // Choose provider based on platform
    if (PlatformUtils.isMobile) {
      _provider = MobileNotificationProvider(_logger);
    } else if (PlatformUtils.isMacOS) {
      _provider = MacOSNotificationProvider(_logger);
    } else {
      _provider = DefaultNotificationProvider(_logger);
    }

    await _provider.initialize();
    _logger.info('Notification Utils initialized');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    return await _provider.requestPermissions();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _provider.areNotificationsEnabled();
  }

  /// Show notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? id,
    Map<String, String>? payload,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    await _provider.showNotification(
      title: title,
      body: body,
      id: id,
      payload: payload,
      priority: priority,
    );
  }

  /// Cancel notification
  Future<void> cancelNotification(String id) async {
    await _provider.cancelNotification(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _provider.cancelAllNotifications();
  }

  /// Listen to notification interactions
  Stream<NotificationResponse> get onNotificationResponse =>
      _provider.onNotificationResponse;

  Future<void> dispose() async {
    await _provider.dispose();
  }
}

enum NotificationPriority { low, normal, high, urgent }

class NotificationResponse {
  final String id;
  final String? actionId;
  final Map<String, String>? payload;

  NotificationResponse({required this.id, this.actionId, this.payload});
}

/// Base notification provider interface
abstract class NotificationProvider {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<bool> areNotificationsEnabled();
  Future<void> showNotification({
    required String title,
    required String body,
    String? id,
    Map<String, String>? payload,
    NotificationPriority priority = NotificationPriority.normal,
  });
  Future<void> cancelNotification(String id);
  Future<void> cancelAllNotifications();
  Stream<NotificationResponse> get onNotificationResponse;
  Future<void> dispose();
}

/// Mobile notification provider
class MobileNotificationProvider implements NotificationProvider {
  final SDKLogger _logger;
  final StreamController<NotificationResponse> _responseController =
      StreamController.broadcast();

  MobileNotificationProvider(this._logger);

  @override
  Future<void> initialize() async {
    _logger.debug('Initializing mobile notification provider');
    // Initialize platform-specific notification system
  }

  @override
  Future<bool> requestPermissions() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  @override
  Future<void> showNotification({
    required String title,
    required String body,
    String? id,
    Map<String, String>? payload,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    _logger.debug('Showing notification: $title');
    // Implement mobile-specific notification display
  }

  @override
  Future<void> cancelNotification(String id) async {
    _logger.debug('Cancelling notification: $id');
    // Implement mobile-specific notification cancellation
  }

  @override
  Future<void> cancelAllNotifications() async {
    _logger.debug('Cancelling all notifications');
    // Implement mobile-specific notification cancellation
  }

  @override
  Stream<NotificationResponse> get onNotificationResponse =>
      _responseController.stream;

  @override
  Future<void> dispose() async {
    await _responseController.close();
  }
}

/// macOS notification provider
class MacOSNotificationProvider implements NotificationProvider {
  final SDKLogger _logger;
  final StreamController<NotificationResponse> _responseController =
      StreamController.broadcast();

  MacOSNotificationProvider(this._logger);

  @override
  Future<void> initialize() async {
    _logger.debug('Initializing macOS notification provider');
    // Initialize macOS-specific notification system
  }

  @override
  Future<bool> requestPermissions() async {
    // macOS-specific permission request
    return true;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    // macOS-specific permission check
    return true;
  }

  @override
  Future<void> showNotification({
    required String title,
    required String body,
    String? id,
    Map<String, String>? payload,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    _logger.debug('Showing macOS notification: $title');
    // Implement macOS-specific notification display
  }

  @override
  Future<void> cancelNotification(String id) async {
    _logger.debug('Cancelling macOS notification: $id');
    // Implement macOS-specific notification cancellation
  }

  @override
  Future<void> cancelAllNotifications() async {
    _logger.debug('Cancelling all macOS notifications');
    // Implement macOS-specific notification cancellation
  }

  @override
  Stream<NotificationResponse> get onNotificationResponse =>
      _responseController.stream;

  @override
  Future<void> dispose() async {
    await _responseController.close();
  }
}

/// Default notification provider (for unsupported platforms)
class DefaultNotificationProvider implements NotificationProvider {
  final SDKLogger _logger;
  final StreamController<NotificationResponse> _responseController =
      StreamController.broadcast();

  DefaultNotificationProvider(this._logger);

  @override
  Future<void> initialize() async {
    _logger.debug('Initializing default notification provider');
  }

  @override
  Future<bool> requestPermissions() async {
    _logger.warning('Notifications not supported on this platform');
    return false;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    return false;
  }

  @override
  Future<void> showNotification({
    required String title,
    required String body,
    String? id,
    Map<String, String>? payload,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    _logger.debug('Would show notification: $title - $body');
  }

  @override
  Future<void> cancelNotification(String id) async {
    _logger.debug('Would cancel notification: $id');
  }

  @override
  Future<void> cancelAllNotifications() async {
    _logger.debug('Would cancel all notifications');
  }

  @override
  Stream<NotificationResponse> get onNotificationResponse =>
      _responseController.stream;

  @override
  Future<void> dispose() async {
    await _responseController.close();
  }
}
