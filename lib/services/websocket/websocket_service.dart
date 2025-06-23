import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../../core/config/sdk_config.dart';
import '../../core/logger/sdk_logger.dart';

enum WebSocketState { disconnected, connecting, connected, reconnecting, error }

class WebSocketService {
  final SDKConfig _config;
  final SDKLogger _logger;

  WebSocketChannel? _channel;
  WebSocketState _state = WebSocketState.disconnected;

  final StreamController<WebSocketState> _stateController =
      StreamController.broadcast();
  final StreamController<dynamic> _messageController =
      StreamController.broadcast();

  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  WebSocketService({required SDKConfig config, required SDKLogger logger})
    : _config = config,
      _logger = logger;

  Future<void> initialize() async {
    _logger.info('Initializing WebSocket Service...');
    // WebSocket service is ready to use after initialization
    _logger.info('WebSocket Service initialized');
  }

  /// Current WebSocket state
  WebSocketState get state => _state;

  /// Stream of state changes
  Stream<WebSocketState> get stateStream => _stateController.stream;

  /// Stream of incoming messages
  Stream<dynamic> get messageStream => _messageController.stream;

  /// Connect to WebSocket server
  Future<void> connect(String url, {Map<String, String>? headers}) async {
    if (_state == WebSocketState.connected ||
        _state == WebSocketState.connecting) {
      _logger.warning('WebSocket already connected or connecting');
      return;
    }

    try {
      _updateState(WebSocketState.connecting);
      _logger.info('Connecting to WebSocket: $url');

      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri, protocols: headers);

      await _channel!.ready;

      _updateState(WebSocketState.connected);
      _reconnectAttempts = 0;
      _logger.info('WebSocket connected successfully');

      // Start listening to messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
        cancelOnError: false,
      );

      // Start heartbeat
      _startHeartbeat();
    } catch (e) {
      _logger.error('Failed to connect to WebSocket: $e');
      _updateState(WebSocketState.error);
      _scheduleReconnect();
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    if (_state == WebSocketState.disconnected) {
      return;
    }

    _logger.info('Disconnecting from WebSocket...');

    _stopHeartbeat();
    _stopReconnectTimer();

    await _channel?.sink.close(status.normalClosure);
    _channel = null;

    _updateState(WebSocketState.disconnected);
    _logger.info('WebSocket disconnected');
  }

  /// Send message to WebSocket server
  void sendMessage(dynamic message) {
    if (_state != WebSocketState.connected) {
      _logger.warning('Cannot send message: WebSocket not connected');
      return;
    }

    try {
      if (message is String) {
        _channel!.sink.add(message);
      } else {
        _channel!.sink.add(jsonEncode(message));
      }
    } catch (e) {
      _logger.error('Failed to send message: $e');
    }
  }

  /// Send binary data to WebSocket server
  void sendBinary(List<int> data) {
    if (_state != WebSocketState.connected) {
      _logger.warning('Cannot send binary data: WebSocket not connected');
      return;
    }

    try {
      _channel!.sink.add(data);
    } catch (e) {
      _logger.error('Failed to send binary data: $e');
    }
  }

  void _onMessage(dynamic message) {
    try {
      // Handle ping/pong
      if (message == 'ping') {
        sendMessage('pong');
        return;
      }

      _messageController.add(message);
    } catch (e) {
      _logger.error('Error handling message: $e');
    }
  }

  void _onError(error) {
    _logger.error('WebSocket error: $error');
    _updateState(WebSocketState.error);
    _scheduleReconnect();
  }

  void _onDisconnected() {
    _logger.info('WebSocket disconnected');
    _stopHeartbeat();

    if (_state != WebSocketState.disconnected) {
      _updateState(WebSocketState.disconnected);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.error('Max reconnect attempts reached');
      _updateState(WebSocketState.error);
      return;
    }

    final delay = Duration(
      seconds: min(pow(2, _reconnectAttempts).toInt(), 30),
    );
    _logger.info(
      'Scheduling reconnect in ${delay.inSeconds} seconds (attempt ${_reconnectAttempts + 1})',
    );

    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      _updateState(WebSocketState.reconnecting);
      // Note: Would need to store original URL and headers for reconnection
      // This is a simplified implementation
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (_state == WebSocketState.connected) {
        sendMessage('ping');
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

  void _updateState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
    }
  }

  Future<void> dispose() async {
    _logger.info('Disposing WebSocket Service...');

    await disconnect();
    await _stateController.close();
    await _messageController.close();
  }
}
