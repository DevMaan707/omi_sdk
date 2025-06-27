import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class AudioWaveSection extends StatefulWidget {
  final AppState appState;
  final String transcriptionText;
  final String interimText;

  const AudioWaveSection({
    super.key,
    required this.appState,
    required this.transcriptionText,
    required this.interimText,
  });

  @override
  State<AudioWaveSection> createState() => _AudioWaveSectionState();
}

class _AudioWaveSectionState extends State<AudioWaveSection>
    with TickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.appState.isStreamingAudio ||
        widget.appState.isStreamingTranscription) {
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(AudioWaveSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.appState.isStreamingAudio ||
            widget.appState.isStreamingTranscription) &&
        !(oldWidget.appState.isStreamingAudio ||
            oldWidget.appState.isStreamingTranscription)) {
      _waveController.repeat();
    } else if (!(widget.appState.isStreamingAudio ||
            widget.appState.isStreamingTranscription) &&
        (oldWidget.appState.isStreamingAudio ||
            oldWidget.appState.isStreamingTranscription)) {
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Audio Visualizer
          Container(
            height: 120,
            padding: const EdgeInsets.all(20),
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: AudioWavePainter(
                    audioLevels: widget.appState.audioLevels,
                    animationValue: _waveController.value,
                    isActive: widget.appState.isStreamingAudio ||
                        widget.appState.isStreamingTranscription,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // Transcription Display
          if (widget.appState.isStreamingTranscription) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.transcribe,
                          color: AppTheme.successColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live Transcription',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.appState.isWebSocketConnected
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: 80,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.transcriptionText.isNotEmpty) ...[
                          Text(
                            widget.transcriptionText,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          if (widget.interimText.isNotEmpty)
                            const SizedBox(height: 8),
                        ],
                        if (widget.interimText.isNotEmpty)
                          Text(
                            widget.interimText,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        if (widget.transcriptionText.isEmpty &&
                            widget.interimText.isEmpty)
                          Text(
                            'Listening for speech...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AudioWavePainter extends CustomPainter {
  final List<double> audioLevels;
  final double animationValue;
  final bool isActive;

  AudioWavePainter({
    required this.audioLevels,
    required this.animationValue,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;

    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final barWidth =
        size.width / (audioLevels.isNotEmpty ? audioLevels.length : 20);

    if (audioLevels.isNotEmpty) {
      for (int i = 0; i < audioLevels.length; i++) {
        final x = i * barWidth + barWidth / 2;
        final level = audioLevels[i];
        final animatedLevel = level *
            (0.5 + 0.5 * math.sin(animationValue * 2 * math.pi + i * 0.5));
        final barHeight = animatedLevel * size.height * 0.8;

        final gradient = LinearGradient(
          colors: [
            AppTheme.accentColor,
            AppTheme.primaryColor,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

        paint.shader = gradient.createShader(
          Rect.fromLTWH(x - 1.5, centerY - barHeight / 2, 3, barHeight),
        );

        canvas.drawLine(
          Offset(x, centerY - barHeight / 2),
          Offset(x, centerY + barHeight / 2),
          paint,
        );
      }
    } else {
      // Default wave animation when no audio data
      for (int i = 0; i < 20; i++) {
        final x = i * barWidth + barWidth / 2;
        final waveHeight =
            20 * math.sin(animationValue * 4 * math.pi + i * 0.3);

        paint.color = AppTheme.accentColor.withOpacity(0.6);
        canvas.drawLine(
          Offset(x, centerY - waveHeight),
          Offset(x, centerY + waveHeight),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
