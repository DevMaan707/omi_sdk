// omi_sdk/example/lib/widgets/professional/quick_actions_section.dart
import 'package:flutter/material.dart';
import '../../models/app_state.dart';
import '../../theme/app_theme.dart';

class QuickActionsSection extends StatelessWidget {
  final AppState appState;
  final Animation<double> scanAnimation;
  final Animation<double> pulseAnimation;
  final VoidCallback onStartScan;
  final VoidCallback onStartAudioStream;
  final VoidCallback onStartTranscriptionStream;
  final VoidCallback onStopStreaming;
  final VoidCallback onDisconnect;

  const QuickActionsSection({
    super.key,
    required this.appState,
    required this.scanAnimation,
    required this.pulseAnimation,
    required this.onStartScan,
    required this.onStartAudioStream,
    required this.onStartTranscriptionStream,
    required this.onStopStreaming,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Primary Action Button
          _buildPrimaryAction(context),

          if (appState.isConnected) ...[
            const SizedBox(height: 16),
            _buildSecondaryActions(context),
          ],

          // Audio Visualization
          if (appState.isStreamingAudio ||
              appState.isStreamingTranscription) ...[
            const SizedBox(height: 20),
            _buildAudioVisualization(context),
          ],
        ],
      ),
    );
  }

  Widget _buildPrimaryAction(BuildContext context) {
    if (!appState.isConnected) {
      return AnimatedBuilder(
        animation: scanAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: appState.isInitialized &&
                        !appState.isScanning &&
                        appState.hasBluetoothPermissions
                    ? onStartScan
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: scanAnimation.value * 6.28,
                        child: Icon(
                          appState.isScanning
                              ? Icons.radar
                              : Icons.bluetooth_searching,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        appState.isScanning
                            ? 'Scanning for Devices...'
                            : 'Discover Devices',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successColor.withOpacity(0.1),
            AppTheme.accentColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.successColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bluetooth_connected,
              color: AppTheme.successColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected to ${appState.connectedDevice?.name ?? 'Device'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'Ready for audio streaming and recording',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audio Controls',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Stream Audio',
                Icons.graphic_eq,
                AppTheme.accentColor,
                appState.canStartStreaming ? onStartAudioStream : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Transcribe',
                Icons.transcribe,
                AppTheme.secondaryColor,
                appState.canStartStreaming ? onStartTranscriptionStream : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Stop Stream',
                Icons.stop,
                AppTheme.errorColor,
                appState.canStopStreaming ? onStopStreaming : null,
                isOutlined: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Disconnect',
                Icons.bluetooth_disabled,
                AppTheme.errorColor,
                appState.isConnected ? onDisconnect : null,
                isOutlined: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed, {
    bool isOutlined = false,
  }) {
    return Container(
      height: 48,
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
                  size: 18,
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

  Widget _buildAudioVisualization(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.graphic_eq,
                        color: AppTheme.accentColor,
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                'Audio Stream Active',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(20, (index) {
                final level = appState.audioLevels.isNotEmpty &&
                        index < appState.audioLevels.length
                    ? appState.audioLevels[index]
                    : 0.0;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 3,
                  height: (level * 50).clamp(2.0, 50.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accentColor, AppTheme.primaryColor],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
