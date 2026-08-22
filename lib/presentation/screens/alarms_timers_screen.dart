import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../domain/models/in_app_alarm_model.dart';
import '../../domain/models/in_app_timer_model.dart';
import '../notifiers/alarm_settings_provider.dart';
import '../notifiers/alarm_timer_provider.dart';
import '../widgets/animated_progress_ring.dart';
import '../widgets/alarm_ringing_dialog.dart';
import '../widgets/core/interactive_task_card.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/board_repository.dart';

class AlarmsTimersScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const AlarmsTimersScreen({super.key, this.initialIndex = 1});

  @override
  ConsumerState<AlarmsTimersScreen> createState() => _AlarmsTimersScreenState();
}

class _AlarmsTimersScreenState extends ConsumerState<AlarmsTimersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 1;
  final TextEditingController _customMinutesController = TextEditingController();
  int _selectedPresetMinutes = 25;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customMinutesController.dispose();
    super.dispose();
  }

  void _showRingingDialogIfNeeded(RingingEvent? event) {
    if (event == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AlarmRingingDialog.show(
        context,
        event: event,
        onDismiss: () {
          ref.read(alarmTimerProvider.notifier).dismissRinging();
        },
        onSnooze: (dur) {
          ref.read(alarmTimerProvider.notifier).snoozeRinging(dur);
        },
      );
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Interactive Long-Press Floating Pop-Up for Alarms
  // ─────────────────────────────────────────────────────────────
  void _showAlarmDetailPopup(BuildContext context, InAppAlarm alarm) {
    HapticFeedback.mediumImpact();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Alarm Details',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final bgCard = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
        final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
        final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
        final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;



        final nextRing = alarm.timeUntilNextRing;
        final hrs = nextRing.inHours;
        final mins = nextRing.inMinutes.remainder(60);
        final countdownText = hrs > 0 ? '$hrs hr $mins min' : '$mins min';

        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: borderSubtle, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.18),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: EpicordiaColors.blue600.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.alarm, color: EpicordiaColors.blue600, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alarm.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                alarm.formattedTime,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: EpicordiaColors.blue600,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: Icon(Icons.close, color: textSecondary),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Time Remaining Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: EpicordiaColors.blue600.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: EpicordiaColors.blue600.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: EpicordiaColors.blue600, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Time Remaining',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: EpicordiaColors.blue600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  alarm.isEnabled ? 'Rings in $countdownText' : 'Alarm Disabled',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: EpicordiaColors.blue600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Detail items
                    _buildDetailRow('Schedule', alarm.repeatDaysSummary, Icons.event_repeat, textPrimary, textSecondary),
                    const SizedBox(height: 10),
                    _buildDetailRow('Sound', alarm.ringtone, Icons.music_note, textPrimary, textSecondary),
                    const SizedBox(height: 10),
                    _buildDetailRow('Vibration', alarm.vibrate ? 'Enabled' : 'Disabled', Icons.vibration, textPrimary, textSecondary),

                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 18),

                    // Tools Toolbar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildToolButton(
                          ctx,
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          color: EpicordiaColors.blue600,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            context.push('/create/alarm', extra: alarm);
                          },
                        ),
                        _buildToolButton(
                          ctx,
                          icon: Icons.volume_up_outlined,
                          label: 'Preview',
                          color: EpicordiaColors.blue600,
                          onTap: () {
                            SystemSound.play(SystemSoundType.alert);
                            HapticFeedback.heavyImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Playing preview: ${alarm.ringtone}'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        _buildToolButton(
                          ctx,
                          icon: alarm.isEnabled ? Icons.alarm_off_outlined : Icons.alarm_on_outlined,
                          label: alarm.isEnabled ? 'Disable' : 'Enable',
                          color: alarm.isEnabled ? EpicordiaColors.errorLight : EpicordiaColors.blue600,
                          onTap: () {
                            ref.read(alarmTimerProvider.notifier).toggleAlarm(alarm.id);
                            Navigator.of(ctx).pop();
                          },
                        ),
                        _buildToolButton(
                          ctx,
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          color: EpicordiaColors.errorLight,
                          onTap: () {
                            ref.read(alarmTimerProvider.notifier).deleteAlarm(alarm.id);
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Alarm deleted'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
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

  Widget _buildDetailRow(String label, String value, IconData icon, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;

    final timerAlarmState = ref.watch(alarmTimerProvider);
    final activeTimer = timerAlarmState.activeTimer;

    // Listen to ringing event
    ref.listen<AlarmTimerState>(alarmTimerProvider, (prev, next) {
      if (next.ringingEvent != null && prev?.ringingEvent != next.ringingEvent) {
        _showRingingDialogIfNeeded(next.ringingEvent);
      }
    });

    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        backgroundColor: bgApp,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Sessions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight,
          ),
        ),
      ),
      body: Column(
        children: [
          // Sub-Tab Segment Switcher (Timers / Alarms / Schedule)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildSegmentTab(0, 'Timers'),
                _buildSegmentTab(1, 'Alarms'),
                _buildSegmentTab(2, 'Schedule'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTimersTab(context, activeTimer, isDark),
                _buildActiveAlarmsTab(context, timerAlarmState.alarms, isDark),
                _buildTaskSchedulesTab(context, isDark),
              ],
            ),
          ),
        ],
      ),

      // Reference 1 Style Bottom Nav Bar
      bottomNavigationBar: _buildReferenceBottomNavBar(isDark),
    );
  }

  Widget _buildSegmentTab(int index, String label) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {
            _currentIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? EpicordiaColors.surfaceCardDark : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? EpicordiaColors.blue600
                    : (isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Bottom Nav Bar matching Reference 1 (5 Icon Actions)
  // ─────────────────────────────────────────────────────────────
  Widget _buildReferenceBottomNavBar(bool isDark) {
    final bgCard = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: bgCard,
        border: Border(top: BorderSide(color: borderSubtle, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 26),
              color: isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight,
              onPressed: () => context.go('/'),
            ),
            IconButton(
              icon: const Icon(Icons.grid_view_outlined, size: 26),
              color: isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight,
              onPressed: () => context.go('/boards'),
            ),
            // Floating Center Blue Plus Action Button
            GestureDetector(
              onTap: () => context.push('/create/alarm'),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: EpicordiaColors.blue600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x402F53DB),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 26),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.description_outlined, size: 26),
              color: isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight,
              onPressed: () => context.go('/notes'),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline, size: 26),
              color: isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight,
              onPressed: () => context.go('/tasks'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Alarms View (Reference 1 Design)
  // ─────────────────────────────────────────────────────────────
  Widget _buildActiveAlarmsTab(BuildContext context, List<InAppAlarm> alarms, bool isDark) {
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    final dailyAlarms = alarms.where((a) => a.isDaily).toList();
    final oneTimeAlarms = alarms.where((a) => a.isOneTime).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // Title Row (Reference 1): "Alarms" with "+ New Alarm" button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Alarms',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: EpicordiaColors.blue600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 0,
              ),
              onPressed: () => context.push('/create/alarm'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Alarm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── 1. DAILY ALARMS SECTION ─────────────────────────────────
        Text(
          'Daily Alarms',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        if (dailyAlarms.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No daily recurring alarms set.',
              style: TextStyle(fontSize: 13, color: textSecondary.withValues(alpha: 0.6)),
            ),
          )
        else
          ...dailyAlarms.map((alarm) => _buildAlarmCard(context, alarm, isDark)),

        const SizedBox(height: 24),

        // ── 2. ONE-TIME ALARMS SECTION ──────────────────────────────
        Text(
          'One-time Alarms',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        if (oneTimeAlarms.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No one-time alarms set.',
              style: TextStyle(fontSize: 13, color: textSecondary.withValues(alpha: 0.6)),
            ),
          )
        else
          ...oneTimeAlarms.map((alarm) => _buildAlarmCard(context, alarm, isDark)),

        const SizedBox(height: 32),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Alarm Card Component matching Reference 1
  // ─────────────────────────────────────────────────────────────
  Widget _buildAlarmCard(BuildContext context, InAppAlarm alarm, bool isDark) {
    final bgCard = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    final isOff = !alarm.isEnabled;

    return GestureDetector(
      onLongPress: () => _showAlarmDetailPopup(context, alarm),
      onTap: () => context.push('/create/alarm', extra: alarm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderSubtle,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Display e.g. 06:30 AM
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${alarm.hourString}:${alarm.minuteString}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isOff ? textSecondary.withValues(alpha: 0.5) : textPrimary,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        alarm.periodString,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isOff ? textSecondary.withValues(alpha: 0.4) : textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Label Title e.g. Wake Up
                  Text(
                    alarm.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isOff ? textSecondary.withValues(alpha: 0.6) : textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Days / Summary Line
                  if (alarm.isDaily)
                    Row(
                      children: [
                        // Days string e.g. M T W T F S S with active days highlighted in blue
                        ...List.generate(7, (idx) {
                          final dayNum = idx + 1;
                          const dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          final isRepeat = alarm.repeatDays.contains(dayNum);

                          return Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text(
                              dayLetters[idx],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isOff
                                    ? textSecondary.withValues(alpha: 0.3)
                                    : (isRepeat ? EpicordiaColors.blue600 : textSecondary.withValues(alpha: 0.3)),
                              ),
                            ),
                          );
                        }),
                        if (alarm.repeatDays.length == 7) ...[
                          const SizedBox(width: 6),
                          Text(
                            'Everyday',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: isOff ? textSecondary.withValues(alpha: 0.4) : textSecondary,
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    // One-time status text e.g. Today / Tomorrow
                    Text(
                      alarm.relativeDayText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isOff ? textSecondary.withValues(alpha: 0.4) : textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            // Toggle Switch
            Switch(
              value: alarm.isEnabled,
              activeTrackColor: EpicordiaColors.blue600,
              onChanged: (val) {
                ref.read(alarmTimerProvider.notifier).toggleAlarm(alarm.id);
                HapticFeedback.selectionClick();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Timers View
  // ─────────────────────────────────────────────────────────────
  Widget _buildTimersTab(BuildContext context, InAppTimer activeTimer, bool isDark) {
    final presetDurations = [5, 30, 60];
    final isTimerActive = activeTimer.state == TimerState.running || activeTimer.state == TimerState.paused;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final bgCard = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        if (ref.watch(alarmSettingsProvider))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: EpicordiaColors.blue500.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EpicordiaColors.blue500.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: EpicordiaColors.blue600, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'System Clock App Handoff mode active (configured in Settings).',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: EpicordiaColors.blue600),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Animated Ring Display
        Center(
          child: AnimatedProgressRing(
            progress: activeTimer.progressFraction,
            formattedTime: activeTimer.remainingDuration.inSeconds > 0
                ? activeTimer.formattedRemaining
                : '${_selectedPresetMinutes.toString().padLeft(2, '0')}:00',
            label: activeTimer.label ?? 'Focus Session',
            timerState: activeTimer.state,
            size: isTimerActive ? 260 : 230,
          ),
        ),

        const SizedBox(height: 32),

        if (isTimerActive) ...[
          // Controls when Timer is Active
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (activeTimer.state == TimerState.running) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    side: BorderSide(color: isDark ? Colors.white30 : Colors.black26),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                  onPressed: () {
                    ref.read(alarmTimerProvider.notifier).pauseTimer();
                  },
                  icon: const Icon(Icons.pause_rounded, size: 22),
                  label: const Text('Pause', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: EpicordiaColors.errorLight.withValues(alpha: 0.15),
                    foregroundColor: EpicordiaColors.errorLight,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    ref.read(alarmTimerProvider.notifier).stopTimer();
                  },
                  icon: const Icon(Icons.stop_rounded, size: 22),
                  label: const Text('Reset', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ] else if (activeTimer.state == TimerState.paused) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: EpicordiaColors.blue600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    elevation: 2,
                  ),
                  onPressed: () {
                    ref.read(alarmTimerProvider.notifier).resumeTimer();
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: const Text('Resume', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    side: BorderSide(color: borderSubtle),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                  onPressed: () {
                    ref.read(alarmTimerProvider.notifier).resetTimer();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Reset', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
        ] else ...[
          // Duration Selection
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Duration',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    Text(
                      '${_customMinutesController.text.isNotEmpty ? _customMinutesController.text : _selectedPresetMinutes} mins',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: EpicordiaColors.blue600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: presetDurations.map((duration) {
                    final isSelected = _selectedPresetMinutes == duration &&
                        _customMinutesController.text.isEmpty;
                    return ChoiceChip(
                      label: Text('$duration min'),
                      selected: isSelected,
                      selectedColor: EpicordiaColors.blue600,
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.08),
                      side: BorderSide(
                        color: isSelected ? EpicordiaColors.blue600 : borderSubtle,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedPresetMinutes = duration;
                            _customMinutesController.clear();
                          });
                        }
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: _customMinutesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Or enter custom minutes',
                    hintText: 'e.g. 90',
                    prefixIcon: const Icon(Icons.tune_rounded, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: EpicordiaColors.blue600, width: 1.5),
                    ),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Start Button
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: EpicordiaColors.blue600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 2,
                ),
                onPressed: () {
                  final minutes = int.tryParse(_customMinutesController.text) ?? _selectedPresetMinutes;
                  ref.read(alarmTimerProvider.notifier).startTimer(
                        duration: Duration(minutes: minutes),
                        label: 'Focus Timer ($minutes m)',
                      );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('Start Focus Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Task Schedules View
  // ─────────────────────────────────────────────────────────────
  Widget _buildTaskSchedulesTab(BuildContext context, bool isDark) {
    final todayTasksStream = ref.watch(taskRepositoryProvider).watchTasksDueToday();
    final boardsStream = ref.watch(boardRepositoryProvider).watchAllBoards();
    final bgCard = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    return StreamBuilder(
      stream: boardsStream,
      builder: (context, boardsSnapshot) {
        final boards = boardsSnapshot.data ?? [];
        final boardsMap = {for (final b in boards) b.id: b};

        return StreamBuilder(
          stream: todayTasksStream,
          builder: (context, snapshot) {
            final tasks = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Text(
                  'Tasks Scheduled for Today',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start a focus session for any scheduled task due today.',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
                const SizedBox(height: 20),

                if (tasks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.event_available_outlined, size: 40, color: EpicordiaColors.blue600),
                        const SizedBox(height: 12),
                        Text(
                          'No Tasks Scheduled Due Today',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enjoy your free time or add new tasks in your workspaces.',
                          style: TextStyle(fontSize: 13, color: textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...tasks.map((task) {
                    final board = boardsMap[task.boardId];
                    final boardTitle = board?.title ?? 'Workspace';
                    final boardColor = EpicordiaColors.blue600;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          InteractiveTaskCard(
                            task: task,
                            boardTitle: boardTitle,
                            boardColor: boardColor,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: EpicordiaColors.blue600.withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  side: BorderSide(color: EpicordiaColors.blue600.withValues(alpha: 0.3)),
                                ),
                                onPressed: () {
                                  ref.read(alarmTimerProvider.notifier).startTimer(
                                        duration: const Duration(minutes: 25),
                                        label: task.title,
                                        taskId: task.id,
                                      );
                                  _tabController.animateTo(0);
                                  setState(() {
                                    _currentIndex = 0;
                                  });
                                },
                                icon: const Icon(Icons.timer_outlined, size: 18, color: EpicordiaColors.blue600),
                                label: const Text(
                                  'Start 25m Focus Session',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: EpicordiaColors.blue600),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }
}
