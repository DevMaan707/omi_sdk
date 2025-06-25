import 'package:flutter/material.dart';
import 'dart:math' as math;

class AudioVisualizer extends StatefulWidget {
  final List<double> audioLevels;
  final bool isActive;
  final Color? color;

  const AudioVisualizer({
    super.key,
    required this.audioLevels,
    required this.isActive,
    this.color,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barColor = widget.color ?? colorScheme.primary;

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: widget.audioLevels.asMap().entries.map((entry) {
          final index = entry.key;
          final level = entry.value;

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final animatedLevel = widget.isActive
                  ? level *
                      (0.5 +
                          0.5 *
                              math.sin(
                                  _animationController.value * 2 * math.pi +
                                      index))
                  : 0.0;

              return Container(
                width: 4,
                height: math.max(4, animatedLevel * 80),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.3 + animatedLevel * 0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
