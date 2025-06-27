# Omi SDK for Flutter

A comprehensive Flutter SDK for connecting to and streaming audio from Omi devices, with built-in support for real-time transcription, audio recording, and WebSocket streaming.

## Features

- 🎧 **Audio Streaming**: Real-time audio streaming from Omi devices
- 🎙️ **Recording**: Record and save audio sessions to local storage
- 📝 **Transcription**: Real-time speech-to-text via WebSocket (Deepgram compatible)
- 🔊 **Playback**: Play recorded audio files
- 📱 **Device Management**: Scan, connect, and manage Omi devices via Bluetooth
- 🔋 **Battery Monitoring**: Get battery levels from connected devices
- 🎵 **Multiple Codecs**: Support for PCM8, PCM16, Opus, and OpusFS320
- 🔄 **Auto-Reconnection**: Automatic reconnection for both Bluetooth and WebSocket
- 📊 **Audio Processing**: Real-time audio processing and format conversion

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  omi_sdk: ^1.0.0
```

### Platform-specific Setup

#### Android
Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS
Add the following to your `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to Omi devices</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to process audio</string>
```

## Quick Start

### 1. Initialize the SDK

```dart
import 'package:omi_sdk/omi_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the SDK with your configuration
  final sdk = await OmiSDK.initialize(OmiConfig(
    apiKey: 'your-deepgram-api-key', // Optional: For transcription
    apiBaseUrl: 'wss://api.deepgram.com', // Optional: Custom WebSocket URL
    connectionTimeout: Duration(seconds: 15),
    autoReconnect: true,
    maxReconnectAttempts: 3,
  ));

  runApp(MyApp());
}
```

### 2. Scan for Devices

```dart
// Start scanning for Omi devices
await OmiSDK.instance.device.startScan();

// Listen for discovered devices
OmiSDK.instance.device.devicesStream.listen((devices) {
  print('Found ${devices.length} devices');
  for (final device in devices) {
    print('Device: ${device.name} (${device.id})');
  }
});

// Stop scanning after 10 seconds
await Future.delayed(Duration(seconds: 10));
await OmiSDK.instance.device.stopScan();
```

### 3. Connect to a Device

```dart
// Connect to a specific device
final deviceId = 'your-device-id';
await OmiSDK.instance.device.connectToDevice(deviceId);

// Listen for connection state changes
OmiSDK.instance.device.connectionStateStream.listen((state) {
  switch (state) {
    case DeviceConnectionState.connected:
      print('Device connected!');
      break;
    case DeviceConnectionState.disconnected:
      print('Device disconnected');
      break;
    case DeviceConnectionState.connecting:
      print('Connecting...');
      break;
    case DeviceConnectionState.error:
      print('Connection error');
      break;
  }
});
```

## Usage Examples

### Audio Recording

```dart
class AudioRecordingExample extends StatefulWidget {
  @override
  _AudioRecordingExampleState createState() => _AudioRecordingExampleState();
}

class _AudioRecordingExampleState extends State<AudioRecordingExample> {
  bool _isRecording = false;
  RecordingSession? _currentSession;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Recording controls
        ElevatedButton(
          onPressed: _isRecording ? _stopRecording : _startRecording,
          child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
        ),

        // Recording duration display
        StreamBuilder<Duration>(
          stream: OmiSDK.instance.recording.recordingDurationStream,
          builder: (context, snapshot) {
            final duration = snapshot.data ?? Duration.zero;
            return Text('Duration: ${_formatDuration(duration)}');
          },
        ),

        // Recording state display
        StreamBuilder<RecordingState>(
          stream: OmiSDK.instance.recording.stateStream,
          builder: (context, snapshot) {
            final state = snapshot.data ?? RecordingState.idle;
            return Text('State: ${state.toString()}');
          },
        ),
      ],
    );
  }

  Future<void> _startRecording() async {
    try {
      final filePath = await OmiSDK.instance.startRecording(
        customFileName: 'my_recording_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      print('Recording started: $filePath');
      setState(() => _isRecording = true);
    } catch (e) {
      print('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final session = await OmiSDK.instance.stopRecording();
      if (session != null) {
        print('Recording saved: ${session.filePath}');
        setState(() {
          _isRecording = false;
          _currentSession = session;
        });
      }
    } catch (e) {
      print('Failed to stop recording: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
```

### Real-time Transcription

```dart
class TranscriptionExample extends StatefulWidget {
  @override
  _TranscriptionExampleState createState() => _TranscriptionExampleState();
}

class _TranscriptionExampleState extends State<TranscriptionExample> {
  String _currentTranscript = '';
  bool _isStreaming = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isStreaming ? _stopTranscription : _startTranscription,
          child: Text(_isStreaming ? 'Stop Transcription' : 'Start Transcription'),
        ),

        // WebSocket state
        StreamBuilder<WebSocketState>(
          stream: OmiSDK.instance.websocket.stateStream,
          builder: (context, snapshot) {
            final state = snapshot.data ?? WebSocketState.disconnected;
            return Text('WebSocket: ${state.toString()}');
          },
        ),

        // Transcription results
        StreamBuilder<Map<String, dynamic>>(
          stream: OmiSDK.instance.websocket.messageStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final message = snapshot.data!;
              if (message['type'] == 'Results') {
                _updateTranscript(message);
              }
            }
            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentTranscript.isEmpty
                  ? 'Transcription will appear here...'
                  : _currentTranscript,
                style: TextStyle(fontSize: 16),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _startTranscription() async {
    try {
      await OmiSDK.instance.startTranscriptionStreaming(
        language: 'en-US',
        userId: 'user123',
        includeSpeechProfile: true,
      );
      setState(() => _isStreaming = true);
    } catch (e) {
      print('Failed to start transcription: $e');
    }
  }

  Future<void> _stopTranscription() async {
    try {
      await OmiSDK.instance.stopAudioStreaming();
      setState(() => _isStreaming = false);
    } catch (e) {
      print('Failed to stop transcription: $e');
    }
  }

  void _updateTranscript(Map<String, dynamic> message) {
    // Extract transcript from Deepgram response
    String? transcript;
    final isFinal = message['is_final'] as bool? ?? false;

    if (message['channel'] != null) {
      final channel = message['channel'] as Map<String, dynamic>?;
      if (channel?['alternatives'] is List) {
        final alternatives = channel!['alternatives'] as List;
        if (alternatives.isNotEmpty && alternatives[0] is Map) {
          final firstAlt = alternatives[0] as Map<String, dynamic>;
          transcript = firstAlt['transcript'] as String?;
        }
      }
    }

    if (transcript != null && transcript.isNotEmpty && isFinal) {
      setState(() {
        _currentTranscript += ' $transcript';
      });
    }
  }
}
```

### Audio Playback

```dart
class PlaybackExample extends StatefulWidget {
  @override
  _PlaybackExampleState createState() => _PlaybackExampleState();
}

class _PlaybackExampleState extends State<PlaybackExample> {
  List<RecordingSession> _recordings = [];

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    final recordings = await OmiSDK.instance.getRecordings();
    setState(() => _recordings = recordings);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _recordings.length,
      itemBuilder: (context, index) {
        final recording = _recordings[index];
        return ListTile(
          title: Text('Recording ${recording.id}'),
          subtitle: Text('Duration: ${_formatDuration(recording.duration)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: () => _playRecording(recording.filePath),
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _deleteRecording(recording),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _playRecording(String filePath) async {
    try {
      await OmiSDK.instance.playRecording(filePath);
    } catch (e) {
      print('Failed to play recording: $e');
    }
  }

  Future<void> _deleteRecording(RecordingSession recording) async {
    try {
      await OmiSDK.instance.deleteRecording(recording.filePath);
      await _loadRecordings(); // Refresh list
    } catch (e) {
      print('Failed to delete recording: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
```

### Dual Streaming (Audio + Transcription)

```dart
// Stream both audio data and transcription simultaneously
await OmiSDK.instance.startDualStreaming(
  language: 'en-US',
  userId: 'user123',
);

// Listen to audio data
OmiSDK.instance.audio.audioDataStream.listen((audioData) {
  // Process raw audio data
  print('Received ${audioData.length} bytes of audio');
});

// Listen to transcription
OmiSDK.instance.websocket.messageStream.listen((message) {
  if (message['type'] == 'Results') {
    // Handle transcription results
    print('Transcription: ${message}');
  }
});
```

## Advanced Features

### Custom WebSocket Parameters

```dart
await OmiSDK.instance.startTranscriptionStreaming(
  websocketUrl: 'wss://your-custom-server.com/v1/listen',
  apiKey: 'your-api-key',
  language: 'en-US',
  customHeaders: {
    'X-Custom-Header': 'value',
  },
  customParams: {
    'model': 'nova-2',
    'smart_format': 'true',
    'diarize': 'true',
  },
);
```

### Audio Codec Detection

```dart
// The SDK automatically detects the audio codec from the device
final codec = await OmiSDK.instance.device.getAudioCodec();
print('Device codec: $codec');
print('Sample rate: ${codec.sampleRate} Hz');
```

### Battery Monitoring

```dart
// Get current battery level
final batteryLevel = await OmiSDK.instance.device.getBatteryLevel();
print('Battery: $batteryLevel%');
```

### Debug Logging

```dart
// Get current audio debug log path
final logPath = OmiSDK.instance.getCurrentAudioLogPath();
print('Audio debug log: $logPath');

// Get all log files
final allLogs = OmiSDK.instance.getAllAudioLogFiles();
for (final log in allLogs) {
  print('Log file: $log');
}
```

## Supported Audio Codecs

- **PCM 8-bit**: 8kHz sample rate, 1 byte per sample
- **PCM 16-bit**: 16kHz sample rate, 2 bytes per sample
- **Opus**: 16kHz sample rate, compressed audio
- **Opus FS320**: 16kHz sample rate, compressed audio with 320ms frame size

The SDK automatically detects the codec from your Omi device and handles the appropriate decoding.

## Error Handling

```dart
try {
  await OmiSDK.instance.device.connectToDevice(deviceId);
} catch (e) {
  if (e.toString().contains('Device not found')) {
    // Handle device not found
  } else if (e.toString().contains('Connection timeout')) {
    // Handle connection timeout
  } else {
    // Handle other errors
  }
}
```

## Best Practices

1. **Always initialize the SDK** before using any features
2. **Handle connection states** properly in your UI
3. **Dispose resources** when done:
   ```dart
   @override
   void dispose() {
     OmiSDK.instance.dispose();
     super.dispose();
   }
   ```
4. **Check connection status** before starting audio operations
5. **Use StreamBuilder** widgets for real-time updates
6. **Handle permissions** gracefully on both Android and iOS

## Troubleshooting

### Common Issues

1. **Bluetooth Permission Denied**
   - Ensure all required permissions are added to your manifest
   - Request permissions at runtime on Android 6+

2. **WebSocket Connection Failed**
   - Check your API key and endpoint URL
   - Verify network connectivity
   - Check firewall settings

3. **Audio Codec Issues**
   - The SDK automatically handles codec detection
   - Check debug logs for codec information

4. **No Devices Found**
   - Ensure Bluetooth is enabled
   - Check if the device is in pairing mode
   - Verify the device supports Omi service UUIDs

### Debug Information

Enable debug logging to get detailed information:

```dart
// Audio debug logs are automatically created
final logPath = OmiSDK.instance.getCurrentAudioLogPath();
// Check the log file for detailed audio processing information
```

## API Reference

### OmiSDK Core
- `initialize(OmiConfig)` - Initialize the SDK
- `startRecording()` - Start audio recording
- `stopRecording()` - Stop recording and get session
- `startTranscriptionStreaming()` - Start real-time transcription
- `startDualStreaming()` - Start audio + transcription
- `dispose()` - Clean up resources

### Device Manager
- `startScan()` - Scan for devices
- `connectToDevice(String)` - Connect to device
- `getAudioCodec()` - Get device audio codec
- `getBatteryLevel()` - Get battery level

### Audio Manager
- `audioDataStream` - Raw audio data stream
- `processedAudioStream` - Processed audio stream
- `isStreaming` - Current streaming state

### WebSocket Manager
- `connect()` - Connect to WebSocket
- `messageStream` - Incoming message stream
- `sendAudio()` - Send audio data

### Recording Manager
- `startRecording()` - Start recording session
- `pauseRecording()` - Pause current recording
- `getRecordings()` - Get all recordings
- `playRecording()` - Play audio file

## Attribution

This SDK is based on [OMI by BasedHardware](https://github.com/BasedHardware/omi),
originally licensed under the MIT License.
All original work belongs to its respective authors.

Special thanks to the [BasedHardware team](https://github.com/BasedHardware/omi) for creating the Omi platform and making it open source.

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

## Support

For issues and questions:
- Check the troubleshooting section above
- Review debug logs for detailed error information
- Open an issue on our GitHub repository
