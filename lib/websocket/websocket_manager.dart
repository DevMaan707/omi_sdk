import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
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
  }) async {
    if (_state == WebSocketState.connected) return;
    if (_state == WebSocketState.connecting) {
      throw Exception('Connection already in progress');
    }

    // Store parameters for potential reconnection
    _lastCodec = codec;
    _lastSampleRate = sampleRate;
    _lastLanguage = language;
    _lastUserId = userId;

    _updateState(WebSocketState.connecting);

    try {
      final params = <String, String>{
        'language': language,
        'sample_rate': sampleRate.toString(),
        'codec': codec.name,
        'include_speech_profile': includeSpeechProfile.toString(),
      };

      if (userId != null) {
        params['uid'] = userId;
      }

      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final uri = Uri.parse(
        '${_config.apiBaseUrl?.replaceAll('https', 'wss') ?? 'wss://api.omi.ai'}/v4/listen?$queryString',
      );

      final headers = <String, dynamic>{};
      if (_config.apiKey != null) {
        headers['Authorization'] = 'Bearer ${_config.apiKey}';
      }

      _channel = IOWebSocketChannel.connect(
        uri,
        headers: headers,
        pingInterval: const Duration(seconds: 30),
        connectTimeout: const Duration(seconds: 15),
      );

      await _channel!.ready;
      _updateState(WebSocketState.connected);
      _reconnectAttempts = 0;

      // Start heartbeat
      _startHeartbeat();

      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          _stopHeartbeat();
          _updateState(WebSocketState.error);
          _scheduleReconnect();
        },
        onDone: () {
          _stopHeartbeat();
          _updateState(WebSocketState.disconnected);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _updateState(WebSocketState.error);
      _scheduleReconnect();
      rethrow;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      if (message == 'ping') {
        _channel?.sink.add('pong');
        return;
      }

      // Try to parse as JSON
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

      // Handle transcript segments (array)
      if (jsonData is List) {
        if (!_segmentsController.isClosed) {
          _segmentsController.add(jsonData);
        }
        return;
      }

      // Handle message events (objects)
      if (!_messageController.isClosed) {
        _messageController.add(jsonData);
      }
    } catch (e) {
      // Log error but don't crash
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
        );
      }
    });
  }

  void sendAudio(List<int> audioData) {
    if (_state == WebSocketState.connected && _channel != null) {
      try {
        _channel!.sink.add(audioData);
      } catch (e) {
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
          _channel?.sink.add('ping');
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
        await _channel!.sink.close(1000); // Normal closure
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
