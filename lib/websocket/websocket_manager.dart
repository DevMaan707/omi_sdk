import 'dart:async';
import 'dart:convert';
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
  final StreamController<dynamic> _messageController =
      StreamController.broadcast();
  final StreamController<List<dynamic>> _segmentsController =
      StreamController.broadcast();

  // Connection parameters for reconnection
  AudioCodec? _lastCodec;
  int? _lastSampleRate;
  String? _lastLanguage;
  String? _lastUserId;
  String? _lastWebsocketUrl;
  String? _lastApiKey;
  Map<String, String>? _lastCustomParams;

  WebSocketManager(this._config);

  WebSocketState get state => _state;
  Stream<WebSocketState> get stateStream => _stateController.stream;
  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<List<dynamic>> get segmentsStream => _segmentsController.stream;

  Future<void> connect({
    required AudioCodec codec,
    required int sampleRate,
    String language = 'en',
    String? userId,
    bool includeSpeechProfile = true,
    String? websocketUrl,
    String? apiKey,
    Map<String, String>? customHeaders,
    Map<String, String>? customParams,
  }) async {
    if (_state == WebSocketState.connected) return;
    if (_state == WebSocketState.connecting) {
      throw Exception('Connection already in progress');
    }

    _lastCodec = codec;
    _lastSampleRate = sampleRate;
    _lastLanguage = language;
    _lastUserId = userId;
    _lastWebsocketUrl = websocketUrl;
    _lastApiKey = apiKey;
    _lastCustomParams = customParams;

    _updateState(WebSocketState.connecting);

    try {
      final baseUrl = websocketUrl ??
          _config.apiBaseUrl?.replaceAll('https', 'wss') ??
          'wss://api.deepgram.com';

      // Build query parameters
      final params = <String, String>{};

      // Add custom parameters first (for Deepgram compatibility)
      if (customParams != null) {
        params.addAll(customParams);
      }

      // Add standard parameters if not already specified
      if (!params.containsKey('language')) {
        params['language'] = language;
      }
      if (!params.containsKey('sample_rate')) {
        params['sample_rate'] = sampleRate.toString();
      }
      if (!params.containsKey('encoding')) {
        // Map codec to Deepgram encoding
        switch (codec) {
          case AudioCodec.pcm8:
          case AudioCodec.pcm16:
            params['encoding'] = 'linear16';
            break;
          case AudioCodec.opus:
          case AudioCodec.opusFS320:
            params['encoding'] = 'opus';
            break;
        }
      }

      if (userId != null && !params.containsKey('uid')) {
        params['uid'] = userId;
      }

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final uri = Uri.parse('$baseUrl/v1/listen?$queryString');

      // Set up headers
      final headers = <String, dynamic>{};

      final effectiveApiKey = apiKey ?? _config.apiKey;
      if (effectiveApiKey != null) {
        // Use Deepgram-style authentication
        headers['Authorization'] =
            'Token $effectiveApiKey'; // Note: "Token" not "Bearer" for Deepgram
      }

      if (customHeaders != null) {
        headers.addAll(customHeaders);
      }

      print('Connecting to WebSocket: $uri');
      print('Headers: $headers');

      _channel = IOWebSocketChannel.connect(
        uri,
        protocols: effectiveApiKey != null ? ['token', effectiveApiKey] : null,
        headers: headers.isNotEmpty ? headers : null,
        pingInterval:
            Duration(seconds: DeviceConstants.heartbeatIntervalSeconds),
        connectTimeout:
            Duration(seconds: DeviceConstants.connectionTimeoutSeconds),
      );

      await _channel!.ready;
      _updateState(WebSocketState.connected);
      _reconnectAttempts = 0;

      print('WebSocket connected successfully');

      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _updateState(WebSocketState.error);
          _scheduleReconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _updateState(WebSocketState.disconnected);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      print('WebSocket connection failed: $e');
      _updateState(WebSocketState.error);
      _scheduleReconnect();
      rethrow;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      // Parse JSON message
      dynamic jsonData;
      try {
        jsonData = jsonDecode(message);
      } catch (e) {
        // Not JSON, treat as raw message
        if (!_messageController.isClosed) {
          _messageController.add(message);
        }
        return;
      }

      // Handle Deepgram response format
      if (jsonData is Map<String, dynamic>) {
        if (jsonData.containsKey('channel') &&
            jsonData['channel'] != null &&
            jsonData['channel']['alternatives'] != null &&
            jsonData['channel']['alternatives'].isNotEmpty) {
          // This is a transcription result
          if (!_messageController.isClosed) {
            _messageController.add(jsonData);
          }
        } else {
          // Other message types
          if (!_messageController.isClosed) {
            _messageController.add(jsonData);
          }
        }
      } else if (jsonData is List) {
        // Handle array messages
        if (!_segmentsController.isClosed) {
          _segmentsController.add(jsonData);
        }
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _config.maxReconnectAttempts) {
      return;
    }

    final delay = Duration(
      seconds: (2 << _reconnectAttempts).clamp(1, 30),
    );

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      if (_lastCodec != null && _lastSampleRate != null) {
        connect(
          codec: _lastCodec!,
          sampleRate: _lastSampleRate!,
          language: _lastLanguage ?? 'en',
          userId: _lastUserId,
          websocketUrl: _lastWebsocketUrl,
          apiKey: _lastApiKey,
          customParams: _lastCustomParams,
        );
      }
    });
  }

  void sendAudio(List<int> audioData) {
    if (_state == WebSocketState.connected && _channel != null) {
      try {
        _channel!.sink.add(audioData);
      } catch (e) {
        print('Error sending audio: $e');
        _updateState(WebSocketState.error);
      }
    }
  }

  void sendMessage(String message) {
    if (_state == WebSocketState.connected && _channel != null) {
      try {
        _channel!.sink.add(message);
      } catch (e) {
        _updateState(WebSocketState.error);
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_state == WebSocketState.connected) {
        try {
          // Send keepalive message
          sendMessage('{"type": "KeepAlive"}');
        } catch (e) {
          _updateState(WebSocketState.error);
        }
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> disconnect({String? reason}) async {
    _stopHeartbeat();
    _stopReconnectTimer();

    if (_channel != null) {
      try {
        await _channel!.sink.close(1000);
      } catch (e) {
        // Ignore close errors
      }
      _channel = null;
    }
    _updateState(WebSocketState.disconnected);
  }

  void _updateState(WebSocketState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  Future<void> dispose() async {
    await disconnect();
    if (!_stateController.isClosed) {
      await _stateController.close();
    }
    if (!_messageController.isClosed) {
      await _messageController.close();
    }
    if (!_segmentsController.isClosed) {
      await _segmentsController.close();
    }
  }
}
