import 'package:flutter/material.dart';
import '../../models/app_state.dart';
import '../../theme/app_theme.dart';

class StatusBar extends StatelessWidget {
  final AppState appState;

  const StatusBar({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor().withOpacity(0.1),
            _getStatusColor().withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(),
              color: _getStatusColor(),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  appState.statusMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (appState.isScanning)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (appState.status) {
      case AppStatus.initializing:
      case AppStatus.scanning:
      case AppStatus.connecting:
        return AppTheme.primaryColor;
      case AppStatus.permissionsRequired:
      case AppStatus.error:
        return AppTheme.errorColor;
      case AppStatus.ready:
      case AppStatus.connected:
        return AppTheme.successColor;
      case AppStatus.streamingAudio:
        return AppTheme.accentColor;
      case AppStatus.streamingTranscription:
        return AppTheme.secondaryColor;
      case AppStatus.recording:
        return AppTheme.errorColor;
    }
  }

  IconData _getStatusIcon() {
    switch (appState.status) {
      case AppStatus.initializing:
        return Icons.hourglass_empty;
      case AppStatus.permissionsRequired:
        return Icons.warning;
      case AppStatus.ready:
        return Icons.check_circle;
      case AppStatus.scanning:
        return Icons.radar;
      case AppStatus.connecting:
        return Icons.sync;
      case AppStatus.connected:
        return Icons.bluetooth_connected;
      case AppStatus.streamingAudio:
        return Icons.graphic_eq;
      case AppStatus.streamingTranscription:
        return Icons.transcribe;
      case AppStatus.recording:
        return Icons.fiber_manual_record;
      case AppStatus.error:
        return Icons.error;
    }
  }

  String _getStatusTitle() {
    switch (appState.status) {
      case AppStatus.initializing:
        return 'Initializing';
      case AppStatus.permissionsRequired:
        return 'Permissions Required';
      case AppStatus.ready:
        return 'Ready';
      case AppStatus.scanning:
        return 'Scanning';
      case AppStatus.connecting:
        return 'Connecting';
      case AppStatus.connected:
        return 'Connected';
      case AppStatus.streamingAudio:
        return 'Streaming Audio';
      case AppStatus.streamingTranscription:
        return 'Live Transcription';
      case AppStatus.recording:
        return 'Recording';
      case AppStatus.error:
        return 'Error';
    }
  }
}
