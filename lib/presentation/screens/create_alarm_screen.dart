import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../domain/models/in_app_alarm_model.dart';
import '../notifiers/alarm_timer_provider.dart';

class CreateAlarmScreen extends ConsumerStatefulWidget {
  final InAppAlarm? alarmToEdit;

  const CreateAlarmScreen({super.key, this.alarmToEdit});

  @override
  ConsumerState<CreateAlarmScreen> createState() => _CreateAlarmScreenState();
}

class _CreateAlarmScreenState extends ConsumerState<CreateAlarmScreen> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late TextEditingController _labelController;

  int _selectedHour12 = 7; // 1..12
  int _selectedMinute = 30; // 0..59
  bool _isPm = false;
  List<int> _selectedRepeatDays = [1, 2, 3, 4, 5]; // Mon-Fri default (1=Mon, 7=Sun)
  String _selectedSound = 'Zen Chimes';
  bool _vibrateEnabled = true;

  final List<String> _availableSounds = [
    'Zen Chimes',
    'Gentle Breeze',
    'Radar',
    'Cosmic Chime',
    'Crisp Bell',
    'Morning Waves',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.alarmToEdit;
    if (existing != null) {
      int h = existing.hour;
      _isPm = h >= 12;
      _selectedHour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      _selectedMinute = existing.minute;
      _selectedRepeatDays = List<int>.from(existing.repeatDays);
      _labelController = TextEditingController(text: existing.title);
      _selectedSound = existing.ringtone;
      _vibrateEnabled = existing.vibrate;
    } else {
      final now = DateTime.now();
      int h = now.hour;
      _isPm = h >= 12;
      _selectedHour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      _selectedMinute = now.minute;
      _labelController = TextEditingController(text: '');
    }

    _hourController = FixedExtentScrollController(initialItem: _selectedHour12 - 1);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  int get _calculated24Hour {
    if (_isPm) {
      return _selectedHour12 == 12 ? 12 : _selectedHour12 + 12;
    } else {
      return _selectedHour12 == 12 ? 0 : _selectedHour12;
    }
  }

  void _saveAlarm() {
    final titleText = _labelController.text.trim();
    final alarmTitle = titleText.isEmpty ? 'Morning Wakeup' : titleText;

    if (widget.alarmToEdit != null) {
      final updated = widget.alarmToEdit!.copyWith(
        title: alarmTitle,
        hour: _calculated24Hour,
        minute: _selectedMinute,
        repeatDays: _selectedRepeatDays..sort(),
        ringtone: _selectedSound,
        vibrate: _vibrateEnabled,
        isEnabled: true,
      );
      ref.read(alarmTimerProvider.notifier).updateAlarm(updated);
    } else {
      final newAlarm = InAppAlarm(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: alarmTitle,
        hour: _calculated24Hour,
        minute: _selectedMinute,
        repeatDays: _selectedRepeatDays..sort(),
        isEnabled: true,
        ringtone: _selectedSound,
        vibrate: _vibrateEnabled,
      );
      ref.read(alarmTimerProvider.notifier).addAlarm(newAlarm);
    }

    HapticFeedback.mediumImpact();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/alarms');
    }
  }

  void _showSoundPickerModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bgCard = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
        final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Select Alarm Sound',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ),
              const SizedBox(height: 12),
              ..._availableSounds.map((sound) {
                final isSelected = _selectedSound == sound;
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? EpicordiaColors.blue600 : Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.music_note,
                      size: 18,
                      color: isSelected ? Colors.white : textPrimary,
                    ),
                  ),
                  title: Text(
                    sound,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: EpicordiaColors.blue600)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedSound = sound;
                    });
                    SystemSound.play(SystemSoundType.alert);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final bgCard = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        backgroundColor: bgApp,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/alarms');
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'Alarm',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: const Text(
              'Save',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: EpicordiaColors.blue600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ── TIME PICKER WHEELS (Reference 2) ─────────────────────────
            Container(
              height: 180,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hour Wheel Card
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListWheelScrollView.useDelegate(
                        controller: _hourController,
                        itemExtent: 54,
                        perspective: 0.003,
                        diameterRatio: 1.4,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedHour12 = index + 1;
                          });
                          HapticFeedback.selectionClick();
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 12,
                          builder: (context, index) {
                            final hVal = index + 1;
                            final isSelected = hVal == _selectedHour12;
                            return Center(
                              child: Text(
                                hVal.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: isSelected ? 34 : 26,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected
                                      ? textPrimary
                                      : textSecondary.withValues(alpha: 0.4),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Separator Colon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),

                  // Minute Wheel Card
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListWheelScrollView.useDelegate(
                        controller: _minuteController,
                        itemExtent: 54,
                        perspective: 0.003,
                        diameterRatio: 1.4,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedMinute = index;
                          });
                          HapticFeedback.selectionClick();
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 60,
                          builder: (context, index) {
                            final isSelected = index == _selectedMinute;
                            return Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: isSelected ? 34 : 26,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected
                                      ? EpicordiaColors.blue600
                                      : textSecondary.withValues(alpha: 0.4),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // AM / PM Stack Pills
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPm = false;
                          });
                          HapticFeedback.selectionClick();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 68,
                          height: 48,
                          decoration: BoxDecoration(
                            color: !_isPm
                                ? EpicordiaColors.blue600
                                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: !_isPm ? EpicordiaColors.blue600 : borderSubtle,
                            ),
                            boxShadow: !_isPm
                                ? [
                                    BoxShadow(
                                      color: EpicordiaColors.blue600.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              'AM',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: !_isPm ? Colors.white : textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPm = true;
                          });
                          HapticFeedback.selectionClick();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 68,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isPm
                                ? EpicordiaColors.blue600
                                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isPm ? EpicordiaColors.blue600 : borderSubtle,
                            ),
                            boxShadow: _isPm
                                ? [
                                    BoxShadow(
                                      color: EpicordiaColors.blue600.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              'PM',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isPm ? Colors.white : textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── LABEL CARD (Reference 2) ───────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Label',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _labelController,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Alarm label',
                      hintStyle: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── REPEAT CARD (Reference 2: S M T W T F S) ───────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repeat',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Circular Day Pills: Order S M T W T F S
                  // Standard mapping: S=7 (Sun), M=1, T=2, W=3, T=4, F=5, S=6 (Sat)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDayCircle(7, 'S', isDark),
                      _buildDayCircle(1, 'M', isDark),
                      _buildDayCircle(2, 'T', isDark),
                      _buildDayCircle(3, 'W', isDark),
                      _buildDayCircle(4, 'T', isDark),
                      _buildDayCircle(5, 'F', isDark),
                      _buildDayCircle(6, 'S', isDark),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── SOUND SELECTOR CARD (Reference 2) ──────────────────────────
            InkWell(
              onTap: () => _showSoundPickerModal(context, isDark),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: EpicordiaColors.blue600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sound',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedSound,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: textSecondary, size: 24),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── VIBRATE TOGGLE CARD (Reference 2) ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.vibration, color: textPrimary, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Vibrate',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Switch(
                    value: _vibrateEnabled,
                    activeTrackColor: EpicordiaColors.blue600,
                    onChanged: (val) {
                      setState(() {
                        _vibrateEnabled = val;
                      });
                      HapticFeedback.selectionClick();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCircle(int dayNum, String label, bool isDark) {
    final isSelected = _selectedRepeatDays.contains(dayNum);
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedRepeatDays.remove(dayNum);
          } else {
            _selectedRepeatDays.add(dayNum);
          }
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? EpicordiaColors.blue600
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          border: Border.all(
            color: isSelected ? EpicordiaColors.blue600 : borderSubtle,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: EpicordiaColors.blue600.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }
}
