import 'package:flutter/material.dart';
import '../models/app_state.dart';

class StatusSection extends StatelessWidget {
  final AppState appState;

  const StatusSection({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appState.status, colorScheme)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(appState.status),
                    color: _getStatusColor(appState.status, colorScheme),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Status',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getStatusText(appState.status),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (appState.isScanning)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Text(
                appState.statusMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildStatusChip(
                  'Permissions',
                  appState.hasBluetoothPermissions,
                  Icons.security,
                  colorScheme,
                ),
                _buildStatusChip(
                  'Initialized',
                  appState.isInitialized,
                  Icons.power_settings_new,
                  colorScheme,
                ),
                _buildStatusChip(
                  'Connected',
                  appState.isConnected,
                  Icons.bluetooth_connected,
                  colorScheme,
                ),
                _buildStatusChip(
                  'Streaming',
                  appState.isStreamingAudio ||
                      appState
                          .isStreamingTranscription, // Fix: use correct property names
                  Icons.mic,
                  colorScheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    String label,
    bool isActive,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer
            : colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? colorScheme.primary.withOpacity(0.2)
              : colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(AppStatus status) {
    switch (status) {
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
      case AppStatus.error:
        return Icons.error;
    }
  }

  Color _getStatusColor(AppStatus status, ColorScheme colorScheme) {
    switch (status) {
      case AppStatus.initializing:
      case AppStatus.scanning:
      case AppStatus.connecting:
        return colorScheme.primary;
      case AppStatus.permissionsRequired:
      case AppStatus.error:
        return colorScheme.error;
      case AppStatus.ready:
      case AppStatus.connected:
        return Colors.green;
      case AppStatus.streamingAudio:
        return Colors.blue;
      case AppStatus.streamingTranscription:
        return Colors.purple;
    }
  }

  String _getStatusText(AppStatus status) {
    switch (status) {
      case AppStatus.initializing:
        return 'Setting up the application...';
      case AppStatus.permissionsRequired:
        return 'Waiting for Bluetooth permissions';
      case AppStatus.ready:
        return 'Ready to discover devices';
      case AppStatus.scanning:
        return 'Searching for nearby devices';
      case AppStatus.connecting:
        return 'Establishing connection';
      case AppStatus.connected:
        return 'Device connected successfully';
      case AppStatus.streamingAudio:
        return 'Audio streaming active';
      case AppStatus.streamingTranscription:
        return 'Live transcription active';
      case AppStatus.error:
        return 'Something went wrong';
    }
  }
}
