import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/alarm_timer_provider.dart';
import 'alarm_ringing_dialog.dart';

class AlarmRingingWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AlarmRingingWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AlarmRingingWrapper> createState() => _AlarmRingingWrapperState();
}

class _AlarmRingingWrapperState extends ConsumerState<AlarmRingingWrapper> {
  bool _isDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AlarmTimerState>(alarmTimerProvider, (previous, next) {
      if (next.ringingEvent != null && !_isDialogShowing) {
        _isDialogShowing = true;
        AlarmRingingDialog.show(
          context,
          event: next.ringingEvent!,
          onDismiss: () {
            _isDialogShowing = false;
            ref.read(alarmTimerProvider.notifier).dismissRinging();
          },
          onSnooze: (duration) {
            _isDialogShowing = false;
            ref.read(alarmTimerProvider.notifier).snoozeRinging(duration);
          },
        ).then((_) {
          _isDialogShowing = false;
        });
      }
    });

    return widget.child;
  }
}
