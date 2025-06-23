import '../core/config/sdk_config.dart';
import '../core/logger/sdk_logger.dart';
import 'platform/platform_utils.dart';
import 'analytics/analytics_utils.dart';
import 'notifications/notification_utils.dart';

/// Utilities subsystem
class UtilsSDK {
  final SDKConfig _config;
  final SDKLogger _logger;

  late final AnalyticsUtils _analytics;
  late final NotificationUtils _notifications;

  UtilsSDK({
    required SDKConfig config,
    required SDKLogger logger,
  })  : _config = config,
        _logger = logger;

  Future<void> initialize() async {
    _logger.info('Initializing Utils SDK...');

    _analytics = AnalyticsUtils(config: _config, logger: _logger);
    _notifications = NotificationUtils(config: _config, logger: _logger);

    await _analytics.initialize();
    await _notifications.initialize();

    _logger.info('Utils SDK initialized');
  }

  /// Platform utilities (static access)
  static PlatformUtils get platform => PlatformUtils();

  /// Analytics utilities
  AnalyticsUtils get analytics => _analytics;

  /// Notification utilities
  NotificationUtils get notifications => _notifications;

  Future<void> dispose() async {
    await _notifications.dispose();
    await _analytics.dispose();
  }
}
