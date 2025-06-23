import 'dart:developer' as developer;
import 'log_level.dart';

class SDKLogger {
  final LogLevel _level;
  final String _prefix;

  const SDKLogger(this._level, {String prefix = 'OmiSDK'}) : _prefix = prefix;

  void debug(String message, [StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, stackTrace);
  }

  void info(String message, [StackTrace? stackTrace]) {
    _log(LogLevel.info, message, stackTrace);
  }

  void warning(String message, [StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, stackTrace);
  }

  void error(String message, [StackTrace? stackTrace]) {
    _log(LogLevel.error, message, stackTrace);
  }

  void _log(LogLevel level, String message, [StackTrace? stackTrace]) {
    if (level.index < _level.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final formattedMessage = '[$timestamp] $levelStr [$_prefix] $message';

    // Use developer.log for better debugging support
    developer.log(
      formattedMessage,
      name: _prefix,
      level: _levelToInt(level),
      error: level == LogLevel.error ? message : null,
      stackTrace: stackTrace,
    );
  }

  int _levelToInt(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
