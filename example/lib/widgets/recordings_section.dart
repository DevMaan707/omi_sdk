import 'package:flutter/material.dart';
import 'package:omi_sdk/omi_sdk.dart';
import '../models/app_state.dart';

class RecordingsSection extends StatefulWidget {
  final AppState appState;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onPauseRecording;
  final VoidCallback onResumeRecording;
  final Function(String) onPlayRecording;
  final VoidCallback onStopPlayback;
  final Function(String) onDeleteRecording;
  final VoidCallback onRefreshRecordings;

  const RecordingsSection({
    super.key,
    required this.appState,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onPauseRecording,
    required this.onResumeRecording,
    required this.onPlayRecording,
    required this.onStopPlayback,
    required this.onDeleteRecording,
    required this.onRefreshRecordings,
  });

  @override
  State<RecordingsSection> createState() => _RecordingsSectionState();
}

class _RecordingsSectionState extends State<RecordingsSection> {
  String? _playingRecordingId;

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
            // Header
            Row(
              children: [
                Icon(
                  Icons.album,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Audio Recordings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onRefreshRecordings,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh recordings',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Recording Controls
            _buildRecordingControls(context),

            const SizedBox(height: 20),

            // Recordings List
            _buildRecordingsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingControls(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = widget.appState.isConnected;
    final recordingState = widget.appState.recordingState;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.radio_button_checked,
                color: recordingState == RecordingState.recording
                    ? Colors.red
                    : colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recording Controls',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (recordingState == RecordingState.recording ||
                  recordingState == RecordingState.paused)
                Text(
                  _formatDuration(widget.appState.recordingDuration),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Start/Stop Recording
              Expanded(
                child: recordingState == RecordingState.idle
                    ? FilledButton.icon(
                        onPressed: isConnected ? widget.onStartRecording : null,
                        icon: const Icon(Icons.fiber_manual_record),
                        label: const Text('Start Recording'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: widget.onStopRecording,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop Recording'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        ),
                      ),
              ),
              if (recordingState == RecordingState.recording ||
                  recordingState == RecordingState.paused) ...[
                const SizedBox(width: 12),
                // Pause/Resume Recording
                FilledButton.icon(
                  onPressed: recordingState == RecordingState.recording
                      ? widget.onPauseRecording
                      : widget.onResumeRecording,
                  icon: Icon(recordingState == RecordingState.recording
                      ? Icons.pause
                      : Icons.play_arrow),
                  label: Text(recordingState == RecordingState.recording
                      ? 'Pause'
                      : 'Resume'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingsList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.appState.recordings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No recordings yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to a device and start recording to save audio',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.appState.recordings.length} Recording(s)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.appState.recordings.map((recording) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRecordingItem(context, recording),
          );
        }),
      ],
    );
  }

  Widget _buildRecordingItem(BuildContext context, RecordingSession recording) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPlaying = _playingRecordingId == recording.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPlaying
            ? colorScheme.primaryContainer.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlaying
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Play/Stop Button
          Container(
            decoration: BoxDecoration(
              color: isPlaying
                  ? colorScheme.primary.withOpacity(0.1)
                  : colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                if (isPlaying) {
                  widget.onStopPlayback();
                  setState(() {
                    _playingRecordingId = null;
                  });
                } else {
                  widget.onPlayRecording(recording.filePath);
                  setState(() {
                    _playingRecordingId = recording.id;
                  });
                }
              },
              icon: Icon(
                isPlaying ? Icons.stop : Icons.play_arrow,
                color: isPlaying
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Recording Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recording.id,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(recording.startTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timer,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(recording.duration),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.headset,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        recording.deviceName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Delete Button
          IconButton(
            onPressed: () => _showDeleteConfirmation(context, recording),
            icon: Icon(
              Icons.delete_outline,
              color: colorScheme.error,
            ),
            tooltip: 'Delete recording',
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, RecordingSession recording) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: Text('Are you sure you want to delete "${recording.id}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDeleteRecording(recording.filePath);
              if (_playingRecordingId == recording.id) {
                setState(() {
                  _playingRecordingId = null;
                });
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
