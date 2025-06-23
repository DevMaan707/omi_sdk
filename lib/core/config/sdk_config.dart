import '../logger/log_level.dart';

/// Configuration class for the SDK
class SDKConfig {
  /// API configuration
  final String? apiBaseUrl;
  final String? apiKey;
  final Map<String, String> apiHeaders;

  /// Device configuration
  final DeviceConfig device;

  /// Audio configuration
  final AudioConfig audio;

  /// Logging configuration
  final LogLevel logLevel;

  /// Environment configuration
  final EnvironmentConfig environment;

  /// Custom configuration
  final Map<String, dynamic> customConfig;

  const SDKConfig({
    this.apiBaseUrl,
    this.apiKey,
    this.apiHeaders = const {},
    this.device = const DeviceConfig(),
    this.audio = const AudioConfig(),
    this.logLevel = LogLevel.info,
    this.environment = const EnvironmentConfig(),
    this.customConfig = const {},
  });

  SDKConfig copyWith({
    String? apiBaseUrl,
    String? apiKey,
    Map<String, String>? apiHeaders,
    DeviceConfig? device,
    AudioConfig? audio,
    LogLevel? logLevel,
    EnvironmentConfig? environment,
    Map<String, dynamic>? customConfig,
  }) {
    return SDKConfig(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiKey: apiKey ?? this.apiKey,
      apiHeaders: apiHeaders ?? this.apiHeaders,
      device: device ?? this.device,
      audio: audio ?? this.audio,
      logLevel: logLevel ?? this.logLevel,
      environment: environment ?? this.environment,
      customConfig: customConfig ?? this.customConfig,
    );
  }
}

/// Device-specific configuration
class DeviceConfig {
  final Duration connectionTimeout;
  final Duration scanTimeout;
  final bool autoReconnect;
  final int maxReconnectAttempts;
  final List<String> allowedDeviceTypes;
  final Map<String, dynamic> deviceSpecificConfig;

  const DeviceConfig({
    this.connectionTimeout = const Duration(seconds: 15),
    this.scanTimeout = const Duration(seconds: 10),
    this.autoReconnect = true,
    this.maxReconnectAttempts = 3,
    this.allowedDeviceTypes = const ['omi', 'frame', 'openglass'],
    this.deviceSpecificConfig = const {},
  });

  DeviceConfig copyWith({
    Duration? connectionTimeout,
    Duration? scanTimeout,
    bool? autoReconnect,
    int? maxReconnectAttempts,
    List<String>? allowedDeviceTypes,
    Map<String, dynamic>? deviceSpecificConfig,
  }) {
    return DeviceConfig(
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      scanTimeout: scanTimeout ?? this.scanTimeout,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      maxReconnectAttempts: maxReconnectAttempts ?? this.maxReconnectAttempts,
      allowedDeviceTypes: allowedDeviceTypes ?? this.allowedDeviceTypes,
      deviceSpecificConfig: deviceSpecificConfig ?? this.deviceSpecificConfig,
    );
  }
}

/// Audio-specific configuration
class AudioConfig {
  final int sampleRate;
  final int channels;
  final String defaultCodec;
  final bool enableProcessing;
  final Map<String, dynamic> processingConfig;

  const AudioConfig({
    this.sampleRate = 16000,
    this.channels = 1,
    this.defaultCodec = 'opus',
    this.enableProcessing = true,
    this.processingConfig = const {},
  });

  AudioConfig copyWith({
    int? sampleRate,
    int? channels,
    String? defaultCodec,
    bool? enableProcessing,
    Map<String, dynamic>? processingConfig,
  }) {
    return AudioConfig(
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
      defaultCodec: defaultCodec ?? this.defaultCodec,
      enableProcessing: enableProcessing ?? this.enableProcessing,
      processingConfig: processingConfig ?? this.processingConfig,
    );
  }
}

/// Environment configuration
class EnvironmentConfig {
  final bool isProduction;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final Map<String, String> environmentVariables;

  const EnvironmentConfig({
    this.isProduction = false,
    this.enableAnalytics = true,
    this.enableCrashReporting = true,
    this.environmentVariables = const {},
  });

  EnvironmentConfig copyWith({
    bool? isProduction,
    bool? enableAnalytics,
    bool? enableCrashReporting,
    Map<String, String>? environmentVariables,
  }) {
    return EnvironmentConfig(
      isProduction: isProduction ?? this.isProduction,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enableCrashReporting: enableCrashReporting ?? this.enableCrashReporting,
      environmentVariables: environmentVariables ?? this.environmentVariables,
    );
  }
}
