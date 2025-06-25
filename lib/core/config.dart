class OmiConfig {
  final String? apiBaseUrl;
  final String? apiKey;
  final Duration connectionTimeout;
  final Duration scanTimeout;
  final bool autoReconnect;
  final int maxReconnectAttempts;

  const OmiConfig({
    this.apiBaseUrl,
    this.apiKey,
    this.connectionTimeout = const Duration(seconds: 15),
    this.scanTimeout = const Duration(seconds: 10),
    this.autoReconnect = true,
    this.maxReconnectAttempts = 3,
  });
}
