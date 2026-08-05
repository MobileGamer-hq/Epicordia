import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../domain/models/in_app_timer_model.dart';

class AnimatedProgressRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final String formattedTime;
  final String label;
  final TimerState timerState;
  final double size;

  const AnimatedProgressRing({
    super.key,
    required this.progress,
    required this.formattedTime,
    required this.label,
    required this.timerState,
    this.size = 240,
  });

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.timerState == TimerState.running) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.timerState == TimerState.running &&
        !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.timerState != TimerState.running &&
        _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseScale = 1.0 + (_pulseController.value * 0.04);
        final glowOpacity = widget.timerState == TimerState.running
            ? 0.15 + (_pulseController.value * 0.25)
            : 0.05;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow pulse
              Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: widget.size * 0.90,
                  height: widget.size * 0.90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EpicordiaColors.blue500.withValues(
                      alpha: glowOpacity,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: EpicordiaColors.blue600.withValues(
                          alpha: glowOpacity,
                        ),
                        blurRadius: 36,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),

              // Custom Painter Ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ProgressRingPainter(
                  progress: widget.progress,
                  isDark: isDark,
                  isRunning: widget.timerState == TimerState.running,
                ),
              ),

              // Time & Label Text in Center
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: widget.timerState == TimerState.running
                            ? EpicordiaColors.blue600
                            : (isDark
                                  ? EpicordiaColors.textTertiaryDark
                                  : EpicordiaColors.textTertiaryLight),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.formattedTime,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          height: 1.0,
                          color: isDark
                              ? EpicordiaColors.textPrimaryDark
                              : EpicordiaColors.textPrimaryLight,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: widget.timerState == TimerState.running
                            ? EpicordiaColors.blue600.withValues(alpha: 0.12)
                            : (widget.timerState == TimerState.paused
                                  ? EpicordiaColors.warningLight.withValues(
                                      alpha: 0.15,
                                    )
                                  : (widget.timerState == TimerState.finished
                                        ? EpicordiaColors.successLight
                                              .withValues(alpha: 0.15)
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.06,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.04,
                                                )))),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: widget.timerState == TimerState.running
                              ? EpicordiaColors.blue600.withValues(alpha: 0.3)
                              : (widget.timerState == TimerState.paused
                                    ? EpicordiaColors.warningLight.withValues(
                                        alpha: 0.3,
                                      )
                                    : Colors.transparent),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.timerState == TimerState.running)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: EpicordiaColors.blue600,
                              ),
                            ),
                          Text(
                            widget.timerState == TimerState.running
                                ? 'Focusing'
                                : (widget.timerState == TimerState.paused
                                      ? 'Paused'
                                      : (widget.timerState ==
                                                TimerState.finished
                                            ? 'Done!'
                                            : 'Ready')),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: widget.timerState == TimerState.running
                                  ? EpicordiaColors.blue600
                                  : (widget.timerState == TimerState.paused
                                        ? EpicordiaColors.warningLight
                                        : (isDark
                                              ? EpicordiaColors
                                                    .textSecondaryDark
                                              : EpicordiaColors
                                                    .textSecondaryLight)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final bool isRunning;

  _ProgressRingPainter({
    required this.progress,
    required this.isDark,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = 12.0;
    final radius = (size.width - strokeWidth) / 2;

    // Track Paint
    final trackPaint = Paint()
      ..color = isDark
          ? EpicordiaColors.borderSubtleDark
          : EpicordiaColors.borderSubtleLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Progress Gradient Paint
    final sweepAngle = 2 * math.pi * progress;
    final startAngle = -math.pi / 2;

    final progressGradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: const [
        // EpicordiaColors.blue100,
        // EpicordiaColors.blue200,
        EpicordiaColors.blue300,EpicordiaColors.blue300,EpicordiaColors.blue300,
        // EpicordiaColors.blue400,
      ],
    );

    final progressPaint = Paint()
      ..shader = progressGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isRunning != isRunning;
  }
}
