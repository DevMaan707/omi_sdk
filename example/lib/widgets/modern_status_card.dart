import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class ModernStatusCard extends StatelessWidget {
  final AppState appState;

  const ModernStatusCard({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: _getStatusGradient(),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern - FIXED
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: PatternPainter(color: Colors.white.withOpacity(0.1)),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusTitle(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appState.statusMessage,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Connection Info
                if (appState.isConnected && appState.connectedDevice != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bluetooth_connected,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          appState.connectedDevice!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Activity Indicators
                if (_hasActiveIndicators())
                  Row(
                    children: _buildActivityChips(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveIndicators() {
    return appState.isRecording ||
        appState.isStreamingAudio ||
        appState.isStreamingTranscription;
  }

  List<Widget> _buildActivityChips() {
    final chips = <Widget>[];

    if (appState.isRecording) {
      chips.add(_buildActivityChip(
          'REC', Icons.fiber_manual_record, AppTheme.errorColor));
    }

    if (appState.isStreamingAudio) {
      chips.add(
          _buildActivityChip('STREAM', Icons.graphic_eq, AppTheme.accentColor));
    }

    if (appState.isStreamingTranscription) {
      chips.add(_buildActivityChip(
          'TRANSCRIBE', Icons.transcribe, AppTheme.successColor));
    }

    // Add spacing between chips
    final spacedChips = <Widget>[];
    for (int i = 0; i < chips.length; i++) {
      spacedChips.add(chips[i]);
      if (i < chips.length - 1) {
        spacedChips.add(const SizedBox(width: 8));
      }
    }

    return spacedChips;
  }

  Widget _buildActivityChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getStatusGradient() {
    switch (appState.status) {
      case AppStatus.connected:
        return LinearGradient(
          colors: [AppTheme.successColor, AppTheme.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppStatus.recording:
        return LinearGradient(
          colors: [AppTheme.errorColor, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppStatus.streamingAudio:
      case AppStatus.streamingTranscription:
        return LinearGradient(
          colors: [AppTheme.accentColor, AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppStatus.error:
        return LinearGradient(
          colors: [AppTheme.errorColor, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return AppTheme.primaryGradient;
    }
  }

  Color _getStatusColor() {
    switch (appState.status) {
      case AppStatus.connected:
        return AppTheme.successColor;
      case AppStatus.recording:
        return AppTheme.errorColor;
      case AppStatus.streamingAudio:
      case AppStatus.streamingTranscription:
        return AppTheme.accentColor;
      case AppStatus.error:
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getStatusIcon() {
    switch (appState.status) {
      case AppStatus.connected:
        return Icons.bluetooth_connected;
      case AppStatus.recording:
        return Icons.fiber_manual_record;
      case AppStatus.streamingAudio:
        return Icons.graphic_eq;
      case AppStatus.streamingTranscription:
        return Icons.transcribe;
      case AppStatus.scanning:
        return Icons.radar;
      case AppStatus.error:
        return Icons.error_outline;
      default:
        return Icons.headset_mic;
    }
  }

  String _getStatusTitle() {
    switch (appState.status) {
      case AppStatus.connected:
        return 'Connected';
      case AppStatus.recording:
        return 'Recording';
      case AppStatus.streamingAudio:
        return 'Audio Stream';
      case AppStatus.streamingTranscription:
        return 'Live Transcription';
      case AppStatus.scanning:
        return 'Scanning';
      case AppStatus.error:
        return 'Error';
      default:
        return 'Omi Studio';
    }
  }
}

// FIXED PatternPainter
class PatternPainter extends CustomPainter {
  final Color color;

  PatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Add safety checks
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 20.0;

    try {
      // Draw diagonal lines safely
      for (double i = -size.height;
          i < size.width + size.height;
          i += spacing) {
        final startX = i;
        final startY = 0.0;
        final endX = i - size.height;
        final endY = size.height;

        // Only draw if coordinates are valid
        if (startX.isFinite &&
            startY.isFinite &&
            endX.isFinite &&
            endY.isFinite) {
          canvas.drawLine(
            Offset(startX, startY),
            Offset(endX, endY),
            paint,
          );
        }
      }
    } catch (e) {
      // Silently handle any painting errors
      print('PatternPainter error: $e');
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
