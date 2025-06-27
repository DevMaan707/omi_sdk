import 'package:flutter/material.dart';
import 'package:omi_sdk/omi_sdk.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class FloatingControlsPanel extends StatefulWidget {
  final AppState appState;
  final Animation<double> scanAnimation;
  final Animation<double> pulseAnimation;
  final VoidCallback onStartScan;
  final VoidCallback onStartAudioStream;
  final VoidCallback onStartTranscriptionStream;
  final VoidCallback onStopStreaming;
  final VoidCallback onDisconnect;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onPauseRecording;
  final VoidCallback onResumeRecording;

  const FloatingControlsPanel({
    super.key,
    required this.appState,
    required this.scanAnimation,
    required this.pulseAnimation,
    required this.onStartScan,
    required this.onStartAudioStream,
    required this.onStartTranscriptionStream,
    required this.onStopStreaming,
    required this.onDisconnect,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onPauseRecording,
    required this.onResumeRecording,
  });

  @override
  State<FloatingControlsPanel> createState() => _FloatingControlsPanelState();
}

class _FloatingControlsPanelState extends State<FloatingControlsPanel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expanded Controls
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _expandAnimation.value,
                alignment: Alignment.bottomRight,
                child: Opacity(
                  opacity: _expandAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!widget.appState.isConnected) ...[
                          _buildControlButton(
                            'Scan',
                            Icons.radar,
                            AppTheme.primaryColor,
                            widget.appState.isScanning
                                ? null
                                : widget.onStartScan,
                            animation: widget.scanAnimation,
                          ),
                        ] else ...[
                          if (!widget.appState.isStreamingAudio &&
                              !widget.appState.isStreamingTranscription) ...[
                            _buildControlButton(
                              'Stream',
                              Icons.graphic_eq,
                              AppTheme.accentColor,
                              widget.onStartAudioStream,
                            ),
                            const SizedBox(height: 8),
                            _buildControlButton(
                              'Transcribe',
                              Icons.transcribe,
                              AppTheme.successColor,
                              widget.onStartTranscriptionStream,
                            ),
                          ] else ...[
                            _buildControlButton(
                              'Stop',
                              Icons.stop,
                              AppTheme.errorColor,
                              widget.onStopStreaming,
                            ),
                          ],
                          const SizedBox(height: 8),
                          if (widget.appState.recordingState ==
                              RecordingState.idle) ...[
                            _buildControlButton(
                              'Record',
                              Icons.fiber_manual_record,
                              AppTheme.errorColor,
                              widget.appState.canStartRecording
                                  ? widget.onStartRecording
                                  : null,
                            ),
                          ] else ...[
                            _buildControlButton(
                              widget.appState.recordingState ==
                                      RecordingState.recording
                                  ? 'Pause'
                                  : 'Resume',
                              widget.appState.recordingState ==
                                      RecordingState.recording
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              AppTheme.warningColor,
                              widget.appState.recordingState ==
                                      RecordingState.recording
                                  ? widget.onPauseRecording
                                  : widget.onResumeRecording,
                            ),
                            const SizedBox(height: 8),
                            _buildControlButton(
                              'Stop Rec',
                              Icons.stop,
                              AppTheme.errorColor,
                              widget.onStopRecording,
                            ),
                          ],
                          const SizedBox(height: 8),
                          _buildControlButton(
                            'Disconnect',
                            Icons.bluetooth_disabled,
                            Colors.grey.shade600,
                            widget.onDisconnect,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Main FAB
          AnimatedBuilder(
            animation: widget.pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: (widget.appState.isRecording ||
                        widget.appState.isStreamingAudio ||
                        widget.appState.isStreamingTranscription)
                    ? widget.pulseAnimation.value
                    : 1.0,
                child: FloatingActionButton(
                  onPressed: _toggleExpanded,
                  backgroundColor:
                      _isExpanded ? AppTheme.errorColor : AppTheme.primaryColor,
                  child: AnimatedRotation(
                    turns: _isExpanded ? 0.125 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      _isExpanded ? Icons.close : Icons.tune,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed, {
    Animation<double>? animation,
  }) {
    Widget button = Container(
      width: 120,
      height: 44,
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? LinearGradient(
                colors: [color, color.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: onPressed == null ? Colors.grey.shade300 : null,
        borderRadius: BorderRadius.circular(22),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: onPressed != null ? Colors.white : Colors.grey.shade500,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color:
                      onPressed != null ? Colors.white : Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (animation != null) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.rotate(
            angle: animation.value * 6.28,
            child: button,
          );
        },
      );
    }

    return button;
  }
}
