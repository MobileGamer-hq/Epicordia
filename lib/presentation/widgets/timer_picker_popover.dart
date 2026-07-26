import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/services/device_timer_alarm_service.dart';
import '../../domain/services/notification_service.dart';

class TimerPickerPopover extends StatefulWidget {
  final String? taskTitle;

  const TimerPickerPopover({super.key, this.taskTitle});

  static Future<void> show(BuildContext context, {String? taskTitle}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => TimerPickerPopover(taskTitle: taskTitle),
    );
  }

  @override
  State<TimerPickerPopover> createState() => _TimerPickerPopoverState();
}

class _TimerPickerPopoverState extends State<TimerPickerPopover> {
  final TextEditingController _customMinutesController = TextEditingController();
  int _selectedMinutes = 25; // Default Pomodoro duration
  final _timerService = DeviceTimerAlarmService();
  final _notificationService = NotificationService();

  final List<int> _presetDurations = [5, 10, 15, 25, 30, 45, 60];

  @override
  void dispose() {
    _customMinutesController.dispose();
    super.dispose();
  }

  Future<void> _handleStartTimer() async {
    final minutes = int.tryParse(_customMinutesController.text) ?? _selectedMinutes;
    if (minutes <= 0) return;

    final result = await _timerService.startTimer(
      minutes: minutes,
      title: widget.taskTitle ?? 'Epicordia Task Timer',
    );

    if (!mounted) return;

    if (result == TimerActionResult.androidSystemHandoffSuccess) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Started $minutes min timer in system Clock app'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (result == TimerActionResult.iosNotificationScheduled) {
      // Schedule local notification fallback for iOS
      await _notificationService.scheduleTimerNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: widget.taskTitle ?? 'Timer Finished',
        duration: Duration(minutes: minutes),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Timer set for $minutes min (Local notification fallback for iOS)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start timer'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20), // radius-l
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start Timer',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
              ],
            ),
            if (widget.taskTitle != null) ...[
              const SizedBox(height: 4),
              Text(
                'Task: ${widget.taskTitle}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Duration',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetDurations.map((duration) {
                final isSelected = _selectedMinutes == duration &&
                    _customMinutesController.text.isEmpty;
                return ChoiceChip(
                  label: Text('$duration min'),
                  selected: isSelected,
                  selectedColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999), // pill
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedMinutes = duration;
                        _customMinutesController.clear();
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customMinutesController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Custom duration (minutes)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // radius-s
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999), // pill
                  ),
                ),
                onPressed: _handleStartTimer,
                child: const Text(
                  'Start Timer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

