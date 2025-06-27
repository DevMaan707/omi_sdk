import 'package:flutter/material.dart';
import 'package:omi_sdk/omi_sdk.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class AudioControlsSection extends StatelessWidget {
  final AppState appState;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onPauseRecording;
  final VoidCallback onResumeRecording;

  const AudioControlsSection({
    super.key,
    required this.appState,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onPauseRecording,
    required this.onResumeRecording,
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
                    gradient: LinearGradient(
                      colors: [AppTheme.errorColor, Colors.red.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fiber_manual_record,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Recording Studio',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recording Status
            _buildRecordingStatus(context),

            const SizedBox(height: 16),

            // Recording Controls
            _buildRecordingControls(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingStatus(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recordingState = appState.recordingState;
    final isRecording = recordingState == RecordingState.recording;
    final isPaused = recordingState == RecordingState.paused;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isRecording ? AppTheme.errorColor : AppTheme.primaryColor)
                .withOpacity(0.1),
            (isRecording ? AppTheme.errorColor : AppTheme.primaryColor)
                .withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isRecording ? AppTheme.errorColor : AppTheme.primaryColor)
              .withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isRecording ? AppTheme.errorColor : AppTheme.primaryColor)
                  .withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRecording
                  ? Icons.fiber_manual_record
                  : isPaused
                      ? Icons.pause
                      : Icons.radio_button_unchecked,
              color: isRecording ? AppTheme.errorColor : AppTheme.primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRecording
                      ? 'Recording Active'
                      : isPaused
                          ? 'Recording Paused'
                          : 'Ready to Record',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isRecording
                        ? AppTheme.errorColor
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isRecording || isPaused
                      ? 'Duration: ${_formatDuration(appState.recordingDuration)}'
                      : 'Connect to a device to start recording',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingControls(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recordingState = appState.recordingState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Controls',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Start/Stop Recording
            Expanded(
              child: recordingState == RecordingState.idle
                  ? _buildControlButton(
                      'Start Recording',
                      Icons.fiber_manual_record,
                      AppTheme.errorColor,
                      appState.canStartRecording ? onStartRecording : null,
                    )
                  : _buildControlButton(
                      'Stop Recording',
                      Icons.stop,
                      AppTheme.errorColor,
                      appState.canStopRecording ? onStopRecording : null,
                    ),
            ),
            if (recordingState == RecordingState.recording ||
                recordingState == RecordingState.paused) ...[
              const SizedBox(width: 12),
              // Pause/Resume Recording
              Expanded(
                child: _buildControlButton(
                  recordingState == RecordingState.recording
                      ? 'Pause'
                      : 'Resume',
                  recordingState == RecordingState.recording
                      ? Icons.pause
                      : Icons.play_arrow,
                  AppTheme.accentColor,
                  recordingState == RecordingState.recording
                      ? onPauseRecording
                      : onResumeRecording,
                  isOutlined: true,
                ),
              ),
            ],
          ],
        ),
        if (!appState.canStartRecording &&
            recordingState == RecordingState.idle)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warningColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.warningColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appState.isStreamingAudio ||
                              appState.isStreamingTranscription
                          ? 'Stop streaming to start recording'
                          : 'Connect to a device to start recording',
                      style: TextStyle(
                        color: AppTheme.warningColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControlButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed, {
    bool isOutlined = false,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: isOutlined
            ? null
            : LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(12),
        border: isOutlined ? Border.all(color: color.withOpacity(0.3)) : null,
        boxShadow: isOutlined
            ? null
            : [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isOutlined ? color : Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isOutlined ? color : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
