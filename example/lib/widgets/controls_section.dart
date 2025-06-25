import 'package:flutter/material.dart';
import '../models/app_state.dart';
import 'audio_visualizer.dart';

class ControlsSection extends StatelessWidget {
  final AppState appState;
  final Animation<double> scanAnimation;
  final VoidCallback onStartScan;
  final VoidCallback onStartAudioStream;
  final VoidCallback onStartTranscriptionStream;
  final VoidCallback onStopStreaming;
  final VoidCallback onDisconnect;

  const ControlsSection({
    super.key,
    required this.appState,
    required this.scanAnimation,
    required this.onStartScan,
    required this.onStartAudioStream,
    required this.onStartTranscriptionStream,
    required this.onStopStreaming,
    required this.onDisconnect,
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
                Icon(
                  Icons.control_camera,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Device Controls',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Primary Actions
            _buildPrimaryActions(context),

            const SizedBox(height: 16),

            // Audio Visualization
            if (appState.isStreamingAudio || appState.isStreamingTranscription)
              _buildAudioVisualization(context),

            // Secondary Actions
            if (appState.isConnected) _buildSecondaryActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scan Button
        AnimatedBuilder(
          animation: scanAnimation,
          builder: (context, child) {
            return ElevatedButton.icon(
              onPressed: appState.isInitialized &&
                      !appState.isScanning &&
                      appState.hasBluetoothPermissions
                  ? onStartScan
                  : null,
              icon: Transform.rotate(
                angle: scanAnimation.value * 6.28,
                child: Icon(
                  appState.isScanning ? Icons.radar : Icons.bluetooth_searching,
                  size: 20,
                ),
              ),
              label: Text(
                appState.isScanning ? 'Scanning...' : 'Discover Devices',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAudioVisualization(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audio Stream',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: AudioVisualizer(
            audioLevels: appState.audioLevels.isNotEmpty
                ? appState.audioLevels
                : List.generate(20, (index) => 0.0),
            isActive:
                appState.isStreamingAudio || appState.isStreamingTranscription,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isStreaming =
        appState.isStreamingAudio || appState.isStreamingTranscription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audio Controls',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),

        // Streaming buttons
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: appState.isConnected && !isStreaming
                    ? onStartAudioStream
                    : null,
                icon: const Icon(Icons.graphic_eq, size: 18),
                label: const Text('Start Stream'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: appState.isConnected && !isStreaming
                    ? onStartTranscriptionStream
                    : null,
                icon: const Icon(Icons.transcribe, size: 18),
                label: const Text('Stream + Transcribe'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.tertiary,
                  foregroundColor: colorScheme.onTertiary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Stop and disconnect buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isStreaming ? onStopStreaming : null,
                icon: const Icon(Icons.stop, size: 18),
                label: const Text('Stop Stream'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: appState.isConnected ? onDisconnect : null,
                icon: const Icon(Icons.bluetooth_disabled, size: 18),
                label: const Text('Disconnect'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
