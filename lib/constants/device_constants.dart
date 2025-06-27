class DeviceConstants {
  // Bluetooth Service UUIDs
  static const String omiServiceUuid = '19b10000-e8f2-537e-4f6c-d104768a1214';
  static const String frameServiceUuid = '7a230001-5475-a6a4-654c-8431f6ad49c4';
  static const String batteryServiceUuid =
      '0000180f-0000-1000-8000-00805f9b34fb';

  // Bluetooth Characteristic UUIDs
  static const String audioCharacteristicUuid =
      '19b10001-e8f2-537e-4f6c-d104768a1214';
  static const String codecCharacteristicUuid =
      '19b10002-e8f2-537e-4f6c-d104768a1214';
  static const String batteryCharacteristicUuid =
      '00002a19-0000-1000-8000-00805f9b34fb';

  // Audio Configuration
  static const int defaultMtuSize = 512;
  static const int audioHeaderSize =
      3; // This is the key - first 3 bytes are header

  // Connection Settings
  static const int heartbeatIntervalSeconds = 30;
  static const int connectionTimeoutSeconds = 15;
  static const int maxReconnectDelaySeconds = 30;

  // WebSocket Settings
  static const String defaultWebSocketUrl = 'wss://api.deepgram.com';
  static const String defaultLanguage = 'en';
}
