import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../notifiers/alarm_timer_provider.dart';

class AlarmRingingDialog extends StatefulWidget {

  final RingingEvent event;
  final VoidCallback onDismiss;
  final ValueChanged<Duration> onSnooze;

  const AlarmRingingDialog({
    super.key,
    required this.event,
    required this.onDismiss,
    required this.onSnooze,
  });

  static Future<void> show(
    BuildContext context, {
    required RingingEvent event,
    required VoidCallback onDismiss,
    required ValueChanged<Duration> onSnooze,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlarmRingingDialog(
        event: event,
        onDismiss: () {
          onDismiss();
          Navigator.of(ctx).pop();
        },
        onSnooze: (dur) {
          onSnooze(dur);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  State<AlarmRingingDialog> createState() => _AlarmRingingDialogState();
}
class _AlarmRingingDialogState extends State<AlarmRingingDialog>

    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _soundLoopTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Play immediate audio alert & vibration feedback
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.vibrate();

    // Repeat sound alert chime & vibration every 1.5 seconds while ringing dialog is visible
    _soundLoopTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.vibrate();
    });
  }

  @override
  void dispose() {
    _soundLoopTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    return Dialog(
      backgroundColor: bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing Alarm Icon
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 1.0 + (_controller.value * 0.12);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: EpicordiaColors.blue600.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.event.isAlarm ? Icons.alarm_on : Icons.timer,
                      size: 36,
                      color: EpicordiaColors.blue600,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              widget.event.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            if (widget.event.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.event.subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                if (widget.event.isAlarm) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => widget.onSnooze(const Duration(minutes: 5)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: EpicordiaColors.borderStrongLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                      ),
                      child: const Text(
                        'Snooze 5m',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: widget.onDismiss,
                    style: FilledButton.styleFrom(
                      backgroundColor: EpicordiaColors.blue600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
}
