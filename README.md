# Omi SDK for Flutter

A comprehensive Flutter SDK for connecting to and streaming audio from Omi devices, enabling real-time speech transcription and AI interactions.

## Attribution

This SDK is based on [OMI by BasedHardware](https://github.com/BasedHardware/omi),
originally licensed under the MIT License.
All original work belongs to its respective authors.

Special thanks to the [BasedHardware team](https://github.com/BasedHardware/omi) for creating the Omi platform and making it open source.

## Features

- 🔍 **Device Discovery**: Scan and discover Omi devices via Bluetooth
- 🔗 **Device Connection**: Connect to Omi devices with automatic reconnection
- 🎤 **Audio Streaming**: Stream real-time audio from connected devices
- 📡 **WebSocket Integration**: Send audio to Omi's transcription service
- 🔋 **Battery Monitoring**: Monitor device battery levels
- 🎛️ **Audio Codec Support**: Support for multiple audio codecs (PCM8, PCM16, Opus)
- 📱 **Cross-Platform**: Works on both Android and iOS
- 🔄 **Auto-Reconnection**: Automatic reconnection on connection loss

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  omi_sdk:
    git:
      url: https://github.com/DevMaan707/omi_sdk.git
```

Or if published to pub.dev:

```yaml
dependencies:
  omi_sdk: ^1.0.0
```

## Permissions

### Android

Add these permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS

Add these to your `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to connect to Omi devices</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to connect to Omi devices</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for audio processing</string>
```

## Quick Start

### 1. Initialize the SDK

```dart
import 'package:omi_sdk/omi_sdk.dart';

// Initialize with your Omi API configuration
final sdk = await OmiSDK.initialize(
  OmiConfig(
    apiBaseUrl: 'https://api.omi.ai',
    apiKey: 'your-api-key-here', // Get from https://omi.ai
    connectionTimeout: Duration(seconds: 15),
    scanTimeout: Duration(seconds: 15),
    autoReconnect: true,
    maxReconnectAttempts: 3,
  ),
);
```

### 2. Scan for Devices

```dart
// Listen for discovered devices
sdk.device.devicesStream.listen((devices) {
  print('Found ${devices.length} devices');
  for (final device in devices) {
    print('Device: ${device.name} (${device.id})');
  }
});

// Start scanning
await sdk.device.startScan(timeout: Duration(seconds: 15));
```

### 3. Connect to a Device

```dart
// Listen for connection state changes
sdk.device.connectionStateStream.listen((state) {
  print('Connection state: ${state.name}');
});

// Connect to a specific device
await sdk.device.connectToDevice('device-id');
```

### 4. Start Audio Streaming

```dart
// Start complete audio streaming workflow
await sdk.startAudioStreaming(
  userId: 'your-user-id', // Optional
);

// Listen for transcription messages
sdk.websocket.messageStream.listen((message) {
  print('Received message: $message');
});

// Listen for transcript segments
sdk.websocket.segmentsStream.listen((segments) {
  print('Received ${segments.length} transcript segments');
});
```

### 5. Stop Streaming and Clean Up

```dart
// Stop audio streaming
await sdk.stopAudioStreaming();

// Disconnect from device
await sdk.device.disconnect();

// Dispose of the SDK
await sdk.dispose();
```

## Complete Example

Here's a complete example showing how to build a simple Omi device controller:

```dart
import 'package:flutter/material.dart';
import 'package:omi_sdk/omi_sdk.dart';

class OmiController extends StatefulWidget {
  @override
  _OmiControllerState createState() => _OmiControllerState();
}

class _OmiControllerState extends State<OmiController> {
  OmiSDK? _sdk;
  List<OmiDevice> _devices = [];
  OmiDevice? _connectedDevice;
  bool _isStreaming = false;
  List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _initializeSDK();
  }

  Future<void> _initializeSDK() async {
    try {
      _sdk = await OmiSDK.initialize(
        OmiConfig(
          apiBaseUrl: 'https://api.omi.ai',
          apiKey: 'your-api-key-here',
        ),
      );

      // Listen for devices
      _sdk!.device.devicesStream.listen((devices) {
        setState(() {
          _devices = devices;
        });
      });

      // Listen for connection state
      _sdk!.device.connectionStateStream.listen((state) {
        if (state == DeviceConnectionState.connected) {
          setState(() {
            _connectedDevice = _sdk!.device.connectedDevice;
          });
        } else if (state == DeviceConnectionState.disconnected) {
          setState(() {
            _connectedDevice = null;
            _isStreaming = false;
          });
        }
      });

      // Listen for messages
      _sdk!.websocket.messageStream.listen((message) {
        setState(() {
          _messages.insert(0, message.toString());
        });
      });

    } catch (e) {
      print('Failed to initialize SDK: $e');
    }
  }

  Future<void> _startScan() async {
    try {
      await _sdk?.device.startScan(timeout: Duration(seconds: 15));
    } catch (e) {
      print('Scan failed: $e');
    }
  }

  Future<void> _connectToDevice(OmiDevice device) async {
    try {
      await _sdk?.device.connectToDevice(device.id);
    } catch (e) {
      print('Connection failed: $e');
    }
  }

  Future<void> _startStreaming() async {
    try {
      await _sdk?.startAudioStreaming(userId: 'user_123');
      setState(() {
        _isStreaming = true;
      });
    } catch (e) {
      print('Streaming failed: $e');
    }
  }

  Future<void> _stopStreaming() async {
    try {
      await _sdk?.stopAudioStreaming();
      setState(() {
        _isStreaming = false;
      });
    } catch (e) {
      print('Stop streaming failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Omi Controller')),
      body: Column(
        children: [
          // Connection Status
          Card(
            child: ListTile(
              leading: Icon(
                _connectedDevice != null
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
                color: _connectedDevice != null ? Colors.green : Colors.red,
              ),
              title: Text(_connectedDevice?.name ?? 'Not connected'),
              subtitle: Text(_connectedDevice?.id ?? 'No device'),
            ),
          ),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _startScan,
                child: Text('Scan'),
              ),
              ElevatedButton(
                onPressed: _connectedDevice != null && !_isStreaming
                    ? _startStreaming
                    : null,
                child: Text('Start Stream'),
              ),
              ElevatedButton(
                onPressed: _isStreaming ? _stopStreaming : null,
                child: Text('Stop Stream'),
              ),
            ],
          ),

          // Devices List
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text('${device.type.name} • ${device.rssi} dBm'),
                  trailing: ElevatedButton(
                    onPressed: () => _connectToDevice(device),
                    child: Text('Connect'),
                  ),
                );
              },
            ),
          ),

          // Messages
          if (_messages.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_messages[index]),
                    dense: true,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sdk?.dispose();
    super.dispose();
  }
}
```

## API Reference

### OmiSDK

The main SDK class that provides access to all functionality.

```dart
// Initialize
static Future<OmiSDK> initialize(OmiConfig config)

// Properties
DeviceManager get device
AudioManager get audio
WebSocketManager get websocket
bool get isInitialized

// Methods
Future<void> startAudioStreaming({String? userId})
Future<void> stopAudioStreaming()
Future<void> dispose()
```

### DeviceManager

Handles Bluetooth device discovery and connection.

```dart
// Properties
List<OmiDevice> get discoveredDevices
Stream<List<OmiDevice>> get devicesStream
Stream<DeviceConnectionState> get connectionStateStream
bool get isConnected
OmiDevice? get connectedDevice

// Methods
Future<void> startScan({Duration? timeout})
Future<void> stopScan()
Future<void> connectToDevice(String deviceId)
Future<void> disconnect()
Future<int> getBatteryLevel()
```

### AudioManager

Manages audio streaming from connected devices.

```dart
// Properties
Stream<Uint8List> get audioDataStream
bool get isStreaming

// Methods
Future<void> startAudioStream({required Function getAudioStream})
Future<void> stopAudioStream()
```

### WebSocketManager

Handles WebSocket connection to Omi's transcription service.

```dart
// Properties
Stream<dynamic> get messageStream
Stream<List<dynamic>> get segmentsStream
WebSocketState get state

// Methods
Future<void> connect({required AudioCodec codec, required int sampleRate})
Future<void> disconnect()
void sendAudio(List<int> audioData)
```

## Configuration

### OmiConfig

```dart
const OmiConfig({
  String? apiBaseUrl,           // Default: 'https://api.omi.ai'
  String? apiKey,               // Your Omi API key
  Duration connectionTimeout,   // Default: 15 seconds
  Duration scanTimeout,         // Default: 10 seconds
  bool autoReconnect,          // Default: true
  int maxReconnectAttempts,    // Default: 3
})
```

## Device Types

The SDK supports multiple device types:

- `DeviceType.omi`: Official Omi devices
- `DeviceType.frame`: Frame devices
- `DeviceType.openglass`: OpenGlass devices
- `DeviceType.unknown`: Other Bluetooth devices

## Audio Codecs

Supported audio codecs:

- `AudioCodec.pcm8`: 8kHz PCM
- `AudioCodec.pcm16`: 16kHz PCM
- `AudioCodec.opus`: Opus codec
- `AudioCodec.opusFS320`: Opus with 320 frame size

## Error Handling

The SDK provides comprehensive error handling:

```dart
try {
  await sdk.device.connectToDevice(deviceId);
} catch (e) {
  if (e.toString().contains('permissions')) {
    // Handle permission errors
  } else if (e.toString().contains('timeout')) {
    // Handle timeout errors
  } else {
    // Handle other errors
  }
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:

- Check the [Omi GitHub repository](https://github.com/BasedHardware/omi)
- Open an issue in this repository
- Join the Omi community discussions

## Changelog

### v1.0.0
- Initial release
- Bluetooth device discovery and connection
- Audio streaming support
- WebSocket integration for transcription
- Cross-platform support (Android/iOS)
- Comprehensive example app
