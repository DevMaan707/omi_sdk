import 'dart:io';
import 'package:universal_io/io.dart' as universal_io;

class PlatformUtils {
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isLinux => Platform.isLinux;
  static bool get isFuchsia => Platform.isFuchsia;

  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => isMacOS || isWindows || isLinux;
  static bool get isApple => isMacOS || isIOS;

  /// Check if Bluetooth is supported on current platform
  static bool get isBluetoothSupported => isMobile || isMacOS || isWindows;

  /// Check if background services are supported
  static bool get isBackgroundServiceSupported => isMobile;

  /// Check if system audio recording is supported
  static bool get isSystemAudioSupported => isMacOS || isWindows;

  /// Check if notifications are supported
  static bool get isNotificationSupported => isMobile || isMacOS;

  /// Get platform name
  static String get platformName {
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isMacOS) return 'macOS';
    if (isWindows) return 'Windows';
    if (isLinux) return 'Linux';
    if (isFuchsia) return 'Fuchsia';
    return 'Unknown';
  }

  static T? executeIfSupported<T>(
    bool isSupported,
    T Function() function, {
    T? fallback,
  }) {
    if (isSupported) {
      try {
        return function();
      } catch (e) {
        return fallback;
      }
    }
    return fallback;
  }

  /// Execute async function only if platform supports it
  static Future<T?> executeIfSupportedAsync<T>(
    bool isSupported,
    Future<T> Function() function, {
    T? fallback,
  }) async {
    if (isSupported) {
      try {
        return await function();
      } catch (e) {
        return fallback;
      }
    }
    return fallback;
  }

  /// Get operating system version
  static String get operatingSystemVersion => Platform.operatingSystemVersion;

  /// Get number of processors
  static int get numberOfProcessors => Platform.numberOfProcessors;

  /// Get path separator for current platform
  static String get pathSeparator => Platform.pathSeparator;

  /// Check if running in debug mode
  static bool get isDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }

  /// Get environment variable
  static String? getEnvironmentVariable(String name) {
    return Platform.environment[name];
  }

  /// Check if running on physical device (not emulator/simulator)
  static Future<bool> get isPhysicalDevice async {
    // This would require additional platform-specific checks
    // For now, return true as default
    return true;
  }
}
