enum DeviceConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error;

  bool get isConnected => this == DeviceConnectionState.connected;
  bool get isConnecting => this == DeviceConnectionState.connecting;
  bool get isDisconnected => this == DeviceConnectionState.disconnected;
  bool get isDisconnecting => this == DeviceConnectionState.disconnecting;
  bool get hasError => this == DeviceConnectionState.error;
}

class ConnectionStateChange {
  final DeviceConnectionState from;
  final DeviceConnectionState to;
  final DateTime timestamp;
  final String? reason;

  ConnectionStateChange({
    required this.from,
    required this.to,
    DateTime? timestamp,
    this.reason,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'ConnectionStateChange: $from -> $to${reason != null ? ' ($reason)' : ''}';
  }
}
