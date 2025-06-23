import '../../core/config/sdk_config.dart';
import '../../core/logger/sdk_logger.dart';
import '../platform/platform_utils.dart';

class AnalyticsUtils {
  final SDKConfig _config;
  final SDKLogger _logger;
  final Map<String, AnalyticsProvider> _providers = {};

  AnalyticsUtils({required SDKConfig config, required SDKLogger logger})
    : _config = config,
      _logger = logger;

  /// Initialize analytics providers
  Future<void> initialize() async {
    if (!_config.environment.enableAnalytics) {
      _logger.info('Analytics disabled in configuration');
      return;
    }

    _logger.info('Initializing Analytics Utils...');

    // Initialize default providers based on platform
    if (PlatformUtils.isMobile) {
      _providers['default'] = MobileAnalyticsProvider(_logger);
    } else {
      _providers['default'] = DesktopAnalyticsProvider(_logger);
    }

    // Initialize all providers
    for (final provider in _providers.values) {
      await provider.initialize();
    }

    _logger.info('Analytics Utils initialized');
  }

  /// Track event
  void trackEvent(String eventName, {Map<String, dynamic>? properties}) {
    if (!_config.environment.enableAnalytics) return;

    try {
      for (final provider in _providers.values) {
        provider.trackEvent(eventName, properties: properties);
      }
    } catch (e) {
      _logger.error('Failed to track event: $e');
    }
  }

  /// Set user property
  void setUserProperty(String key, dynamic value) {
    if (!_config.environment.enableAnalytics) return;

    try {
      for (final provider in _providers.values) {
        provider.setUserProperty(key, value);
      }
    } catch (e) {
      _logger.error('Failed to set user property: $e');
    }
  }

  /// Identify user
  void identifyUser(String userId, {Map<String, dynamic>? properties}) {
    if (!_config.environment.enableAnalytics) return;

    try {
      for (final provider in _providers.values) {
        provider.identifyUser(userId, properties: properties);
      }
    } catch (e) {
      _logger.error('Failed to identify user: $e');
    }
  }

  /// Add custom provider
  void addProvider(String name, AnalyticsProvider provider) {
    _providers[name] = provider;
  }

  /// Remove provider
  void removeProvider(String name) {
    _providers.remove(name);
  }

  Future<void> dispose() async {
    for (final provider in _providers.values) {
      await provider.dispose();
    }
    _providers.clear();
  }
}

/// Base analytics provider interface
abstract class AnalyticsProvider {
  Future<void> initialize();
  void trackEvent(String eventName, {Map<String, dynamic>? properties});
  void setUserProperty(String key, dynamic value);
  void identifyUser(String userId, {Map<String, dynamic>? properties});
  Future<void> dispose();
}

/// Mobile analytics provider
class MobileAnalyticsProvider implements AnalyticsProvider {
  final SDKLogger _logger;

  MobileAnalyticsProvider(this._logger);

  @override
  Future<void> initialize() async {
    _logger.debug('Initializing mobile analytics provider');
  }

  @override
  void trackEvent(String eventName, {Map<String, dynamic>? properties}) {
    _logger.debug('Tracking event: $eventName with properties: $properties');
    // Implement mobile-specific analytics tracking
  }

  @override
  void setUserProperty(String key, dynamic value) {
    _logger.debug('Setting user property: $key = $value');
    // Implement mobile-specific user property setting
  }

  @override
  void identifyUser(String userId, {Map<String, dynamic>? properties}) {
    _logger.debug('Identifying user: $userId with properties: $properties');
    // Implement mobile-specific user identification
  }

  @override
  Future<void> dispose() async {
    _logger.debug('Disposing mobile analytics provider');
  }
}

/// Desktop analytics provider
class DesktopAnalyticsProvider implements AnalyticsProvider {
  final SDKLogger _logger;

  DesktopAnalyticsProvider(this._logger);

  @override
  Future<void> initialize() async {
    _logger.debug('Initializing desktop analytics provider');
  }

  @override
  void trackEvent(String eventName, {Map<String, dynamic>? properties}) {
    _logger.debug('Tracking event: $eventName with properties: $properties');
    // Implement desktop-specific analytics tracking
  }

  @override
  void setUserProperty(String key, dynamic value) {
    _logger.debug('Setting user property: $key = $value');
    // Implement desktop-specific user property setting
  }

  @override
  void identifyUser(String userId, {Map<String, dynamic>? properties}) {
    _logger.debug('Identifying user: $userId with properties: $properties');
    // Implement desktop-specific user identification
  }

  @override
  Future<void> dispose() async {
    _logger.debug('Disposing desktop analytics provider');
  }
}
