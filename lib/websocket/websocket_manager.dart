// omi_sdk/lib/websocket/websocket_manager.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../constants/device_constants.dart';
import '../core/config.dart';
import '../device/models.dart';

enum WebSocketState { disconnected, connecting, connected, error }

class WebSocketManager {
  final OmiConfig _config;
  WebSocketChannel? _channel;
  WebSocketState _state = WebSocketState.disconnected;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  final StreamController<WebSocketState> _stateController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  // Connection parameters for reconnection
  AudioCodec? _lastCodec;
  int? _lastSampleRate;
  String? _lastLanguage;
  String? _lastUserId;
  String? _lastWebsocketUrl;
  String? _lastApiKey;

  // Audio streaming stats
  int _audioPacketsSent = 0;
  int _totalAudioBytesSent = 0;

  WebSocketManager(this._config);

  WebSocketState get state => _state;
  Stream<WebSocketState> get stateStream => _stateController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  int get audioPacketsSent => _audioPacketsSent;
  int get totalAudioBytesSent => _totalAudioBytesSent;

  Future<void> connect({
    required AudioCodec codec,
    required int sampleRate,
    String language = 'en-US',
    String? userId,
    bool includeSpeechProfile = true,
    String? websocketUrl,
    String? apiKey,
    Map<String, String>? customHeaders,
    Map<String, String>? customParams,
  }) async {
    if (_state == WebSocketState.connected) {
      print('WebSocket already connected');
      return;
    }

    if (_state == WebSocketState.connecting) {
      throw Exception('Connection already in progress');
    }

    // Store connection parameters
    _lastCodec = codec;
    _lastSampleRate = sampleRate;
    _lastLanguage = language;
    _lastUserId = userId;
    _lastWebsocketUrl = websocketUrl;
    _lastApiKey = apiKey;

    _updateState(WebSocketState.connecting);
    print('Connecting to WebSocket...');

    try {
      // FIXED: Proper URL construction
      String baseUrl;
      if (websocketUrl != null) {
        // Use provided URL, ensure it's wss://
        baseUrl = websocketUrl
            .replaceFirst('https://', 'wss://')
            .replaceFirst('http://', 'ws://');
        // Remove any duplicate paths
        if (baseUrl.contains('/v1/listen/v1/listen')) {
          baseUrl = baseUrl.replaceAll('/v1/listen/v1/listen', '/v1/listen');
        }
      } else {
        // Default Deepgram URL
        baseUrl = 'wss://api.deepgram.com/v1/listen';
      }

      // Build query parameters for Deepgram
      final params = <String, String>{
        'language': language,
        'sample_rate': sampleRate.toString(),
        'channels': '1',
        'encoding': _getEncodingForCodec(codec),
        'model': 'nova-2',
        'smart_format': 'true',
        'interim_results': 'true',
        'punctuate': 'true',
        'endpointing': '300',
        'vad_events': 'true',
        'diarize': 'true',
      };

      // Add custom parameters
      if (customParams != null) {
        params.addAll(customParams);
      }

      if (userId != null) {
        params['uid'] = userId;
      }

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      // FIXED: Proper URI construction
      final uri = Uri.parse('$baseUrl?$queryString');

      // Set up headers
      final headers = <String, dynamic>{};
      final effectiveApiKey = apiKey ?? _config.apiKey;

      if (effectiveApiKey != null) {
        headers['Authorization'] = 'Token $effectiveApiKey';
      }

      if (customHeaders != null) {
        headers.addAll(customHeaders);
      }

      print('Connecting to: $uri');
      print('Using codec: $codec, sample rate: $sampleRate Hz');

      _channel = IOWebSocketChannel.connect(
        uri,
        headers: headers.isNotEmpty ? headers : null,
        pingInterval: Duration(seconds: 20),
        connectTimeout: Duration(seconds: 15),
      );

      await _channel!.ready;
      _updateState(WebSocketState.connected);
      _reconnectAttempts = 0;
      _audioPacketsSent = 0;
      _totalAudioBytesSent = 0;

      print('WebSocket connected successfully');
      _startHeartbeat();

      // Listen for messages
      _channel!.stream.listen(
        (message) {
          try {
            _handleMessage(message);
          } catch (e) {
            print('Error handling WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket stream error: $error');
          _updateState(WebSocketState.error);
          _scheduleReconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _updateState(WebSocketState.disconnected);
          if (_config.autoReconnect) {
            _scheduleReconnect();
          }
        },
      );
    } catch (e) {
      print('WebSocket connection failed: $e');
      _updateState(WebSocketState.error);
      if (_config.autoReconnect) {
        _scheduleReconnect();
      }
      rethrow;
    }
  }

  String _getEncodingForCodec(AudioCodec codec) {
    switch (codec) {
      case AudioCodec.pcm8:
      case AudioCodec.pcm16:
        return 'linear16';
      case AudioCodec.opus:
      case AudioCodec.opusFS320:
        return 'linear16'; // We decode Opus to PCM before sending
    }
  }

  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        final jsonData = jsonDecode(message);

        if (jsonData is Map<String, dynamic>) {
          print('WebSocket message type: ${jsonData['type']}');

          if (!_messageController.isClosed) {
            _messageController.add(jsonData);
          }

          if (jsonData['type'] == 'Results') {
            final isFinal = jsonData['is_final'] as bool? ?? false;

            String? transcript;
            if (jsonData['channel'] != null) {
              final channel = jsonData['channel'] as Map<String, dynamic>?;
              if (channel?['alternatives'] is List) {
                final alternatives = channel!['alternatives'] as List;
                if (alternatives.isNotEmpty && alternatives[0] is Map) {
                  final firstAlt = alternatives[0] as Map<String, dynamic>;
                  transcript = firstAlt['transcript'] as String?;
                }
              }
            }

            if (transcript == null && jsonData['results'] != null) {
              final results = jsonData['results'] as Map<String, dynamic>?;
              if (results?['channels'] is List) {
                final channels = results!['channels'] as List;
                if (channels.isNotEmpty && channels[0] is Map) {
                  final firstChannel = channels[0] as Map<String, dynamic>;
                  if (firstChannel['alternatives'] is List) {
                    final alternatives = firstChannel['alternatives'] as List;
                    if (alternatives.isNotEmpty && alternatives[0] is Map) {
                      final firstAlt = alternatives[0] as Map<String, dynamic>;
                      transcript = firstAlt['transcript'] as String?;
                    }
                  }
                }
              }
            }

            if (transcript != null && transcript.isNotEmpty && isFinal) {
              print('Final transcript: $transcript');
            }
          } else if (jsonData['type'] == 'Metadata') {
            print('Received metadata: ${jsonData}');
          } else if (jsonData['type'] == 'SpeechStarted') {
            print('Speech started detected');
          } else if (jsonData['type'] == 'UtteranceEnd') {
            print('Utterance ended');
          }
        }
      }
    } catch (e, stackTrace) {
      print('Error parsing WebSocket message: $e');
      print('Stack trace: $stackTrace');
      print('Raw message: $message');
    }
  }

  void sendAudio(List<int> audioData) {
    if (_state != WebSocketState.connected || _channel == null) {
      return;
    }

    if (audioData.isEmpty) {
      return;
    }

    try {
      final audioBytes = Uint8List.fromList(audioData);
      _channel!.sink.add(audioBytes);

      _audioPacketsSent++;
      _totalAudioBytesSent += audioBytes.length;

      if (_audioPacketsSent % 100 == 0) {
        print(
            'Sent $_audioPacketsSent audio packets (${_totalAudioBytesSent} bytes total)');
      }
    } catch (e) {
      print('Error sending audio data: $e');
      _updateState(WebSocketState.error);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 20), (_) {
      if (_state == WebSocketState.connected && _channel != null) {
        try {
          _channel!.sink.add('{"type": "KeepAlive"}');
        } catch (e) {
          print('Heartbeat failed: $e');
          _updateState(WebSocketState.error);
        }
      }
    });
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _config.maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      return;
    }

    _heartbeatTimer?.cancel();

    final delay = Duration(seconds: (2 << _reconnectAttempts).clamp(1, 30));
    print('Scheduling reconnection in ${delay.inSeconds} seconds');

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      if (_lastCodec != null && _lastSampleRate != null) {
        connect(
          codec: _lastCodec!,
          sampleRate: _lastSampleRate!,
          language: _lastLanguage ?? 'en-US',
          userId: _lastUserId,
          websocketUrl: _lastWebsocketUrl,
          apiKey: _lastApiKey,
        ).catchError((e) {
          print('Reconnection failed: $e');
        });
      }
    });
  }

  Future<void> disconnect({String? reason}) async {
    print('Disconnecting WebSocket${reason != null ? ': $reason' : ''}');

    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    if (_channel != null) {
      try {
        await _channel!.sink.close(1000, reason);
      } catch (e) {
        print('Error closing WebSocket: $e');
      }
      _channel = null;
    }

    _updateState(WebSocketState.disconnected);
  }

  void _updateState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      print('WebSocket state changed to: $newState');
      if (!_stateController.isClosed) {
        _stateController.add(_state);
      }
    }
  }

  Future<void> dispose() async {
    await disconnect();

    try {
      if (!_stateController.isClosed) {
        await _stateController.close();
      }
      if (!_messageController.isClosed) {
        await _messageController.close();
      }
    } catch (e) {
      print('Error disposing WebSocketManager: $e');
    }
  }
}
