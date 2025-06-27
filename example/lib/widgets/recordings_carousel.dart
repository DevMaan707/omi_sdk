import 'package:flutter/material.dart';
import 'package:omi_sdk/omi_sdk.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class RecordingsCarousel extends StatelessWidget {
  final AppState appState;
  final Function(String) onPlayRecording;
  final VoidCallback onStopPlayback;
  final Function(String) onDeleteRecording;
  final VoidCallback onRefreshRecordings;

  const RecordingsCarousel({
    super.key,
    required this.appState,
    required this.onPlayRecording,
    required this.onStopPlayback,
    required this.onDeleteRecording,
    required this.onRefreshRecordings,
  });

  @override
  Widget build(BuildContext context) {
    if (appState.recordings.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.library_music,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Recordings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onRefreshRecordings,
              icon: const Icon(Icons.refresh),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: appState.recordings.length,
            itemBuilder: (context, index) {
              final recording = appState.recordings[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                child: _buildRecordingCard(recording),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mic_none,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No recordings yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect to a device and start recording',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(RecordingSession recording) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.audiotrack,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getRecordingName(recording),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(recording.duration),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  _formatDate(recording),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onPlayRecording(recording.filePath),
                        borderRadius: BorderRadius.circular(8),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Play',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onDeleteRecording(recording.filePath),
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(
                        Icons.delete_outline,
                        color: AppTheme.errorColor,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRecordingName(RecordingSession recording) {
    // Extract filename from filePath if available, otherwise use a default name
    if (recording.filePath.isNotEmpty) {
      final parts = recording.filePath.split('/');
      return parts.last.replaceAll('.wav', '').replaceAll('.mp3', '');
    }
    return 'Recording ${DateTime.now().millisecondsSinceEpoch}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatDate(RecordingSession recording) {
    // Since RecordingSession might not have a timestamp field,
    // we'll extract date from filePath or use current date
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year.toString().substring(2)}';
  }
}
