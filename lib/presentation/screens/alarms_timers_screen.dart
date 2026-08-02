import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/repository/task_repository.dart';
import '../../domain/models/in_app_alarm_model.dart';
import '../../domain/models/in_app_timer_model.dart';
import '../notifiers/alarm_settings_provider.dart';
import '../notifiers/alarm_timer_provider.dart';
import '../widgets/animated_progress_ring.dart';
import '../widgets/alarm_ringing_dialog.dart';
import '../widgets/core/interactive_task_card.dart';
import '../../data/repository/board_repository.dart';


class AlarmsTimersScreen extends ConsumerStatefulWidget {
  const AlarmsTimersScreen({super.key});

  @override
  ConsumerState<AlarmsTimersScreen> createState() => _AlarmsTimersScreenState();
}

class _AlarmsTimersScreenState extends ConsumerState<AlarmsTimersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  final TextEditingController _customMinutesController = TextEditingController();
  int _selectedPresetMinutes = 25;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  void _showAddAlarmModal(BuildContext context) {
    TimeOfDay selectedTime = TimeOfDay.now();
    final titleController = TextEditingController(text: 'Focus Alarm');
    final List<int> selectedRepeatDays = [1, 2, 3, 4, 5]; // Mon-Fri default

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final bgCard = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Set New Alarm',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Time Picker Button
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: EpicordiaColors.blue600.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: EpicordiaColors.blue600.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          selectedTime.format(ctx),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: EpicordiaColors.blue600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Alarm Label',
                      hintText: 'e.g. Morning Focus',
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('Repeat Days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: List.generate(7, (index) {
                      final dayNum = index + 1;
                      const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      final isSelected = selectedRepeatDays.contains(dayNum);

                      return FilterChip(
                        label: Text(dayLabels[index]),
                        selected: isSelected,
                        selectedColor: EpicordiaColors.blue600,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : EpicordiaColors.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              selectedRepeatDays.add(dayNum);
                            } else {
                              selectedRepeatDays.remove(dayNum);
                            }
                          });
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: EpicordiaColors.blue600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                      ),
                      onPressed: () {
                        final alarm = InAppAlarm(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text.trim().isEmpty ? 'Alarm' : titleController.text.trim(),
                          hour: selectedTime.hour,
                          minute: selectedTime.minute,
                          repeatDays: selectedRepeatDays..sort(),
                          isEnabled: true,
                        );
                        ref.read(alarmTimerProvider.notifier).addAlarm(alarm);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Alarm set for ${alarm.formattedTime}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Save Alarm', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;

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
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Alarms & Timers',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textPrimary),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── 1. TIMERS TAB ─────────────────────────────────────────────
          _buildTimersTab(context, activeTimer, isDark),

          // ── 2. ACTIVE ALARMS TAB ──────────────────────────────────────
          _buildActiveAlarmsTab(context, timerAlarmState.alarms, isDark),

          // ── 3. TASK SCHEDULES TAB ────────────────────────────────────
          _buildTaskSchedulesTab(context, isDark),
        ],
      ),

      // ── CUSTOM EPICORDIA SCREEN BOTTOM NAV ──────────────────────────
      bottomNavigationBar: _buildCustomBottomNavBar(isDark),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Custom Epicordia Bottom Nav Bar
  // ─────────────────────────────────────────────────────────────
  Widget _buildCustomBottomNavBar(bool isDark) {
    final bgCard = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    final items = [
      _AlarmsNavItemData(
        index: 0,
        label: 'Timers',
        icon: Icons.timer_outlined,
        activeIcon: Icons.timer,
      ),
      _AlarmsNavItemData(
        index: 1,
        label: 'Alarms',
        icon: Icons.alarm_outlined,
        activeIcon: Icons.alarm,
      ),
      _AlarmsNavItemData(
        index: 2,
        label: 'Scheduled',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        border: Border(top: BorderSide(color: borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final isActive = _currentIndex == item.index;
              final activeColor = EpicordiaColors.blue600;
              final inactiveColor = isDark
                  ? EpicordiaColors.textTertiaryDark
                  : EpicordiaColors.textTertiaryLight;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    _tabController.animateTo(item.index);
                    setState(() {
                      _currentIndex = item.index;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? activeColor.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: 20,
                          color: isActive ? activeColor : inactiveColor,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? activeColor : inactiveColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),

    );

  }

  // ─────────────────────────────────────────────────────────────
  // Timers View
  // ─────────────────────────────────────────────────────────────
  Widget _buildTimersTab(BuildContext context, InAppTimer activeTimer, bool isDark) {
    final presetDurations = [5, 10, 15, 25, 30, 45, 60];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (ref.watch(alarmSettingsProvider))
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: EpicordiaColors.blue500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EpicordiaColors.blue500.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: EpicordiaColors.blue600, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'System Clock App Handoff mode is active (configured in Settings).',
                    style: TextStyle(fontSize: 12, color: EpicordiaColors.blue600),
                  ),
                ),
              ],
            ),
          ),

        // Animated Ring
        Center(
          child: AnimatedProgressRing(
            progress: activeTimer.progressFraction,
            formattedTime: activeTimer.remainingDuration.inSeconds > 0
                ? activeTimer.formattedRemaining
                : '${_selectedPresetMinutes.toString().padLeft(2, '0')}:00',
            label: activeTimer.label ?? 'Focus Session',
            timerState: activeTimer.state,
            size: 250,
          ),
        ),

        const SizedBox(height: 32),

        // Preset Chips
        const Text(
          'Quick Presets',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presetDurations.map((duration) {
            final isSelected = _selectedPresetMinutes == duration &&
                _customMinutesController.text.isEmpty;
            return ChoiceChip(
              label: Text('$duration min'),
              selected: isSelected,
              selectedColor: EpicordiaColors.blue600.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? EpicordiaColors.blue600 : (isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
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

        const SizedBox(height: 20),

        // Custom duration input
        TextField(
          controller: _customMinutesController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Custom duration (minutes)',
            hintText: 'e.g. 90',
          ),
          onChanged: (val) => setState(() {}),
        ),

        const SizedBox(height: 32),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (activeTimer.state == TimerState.idle || activeTimer.state == TimerState.finished) ...[
              SizedBox(
                width: 180,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: EpicordiaColors.blue600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                  onPressed: () {
                    final minutes = int.tryParse(_customMinutesController.text) ?? _selectedPresetMinutes;
                    ref.read(alarmTimerProvider.notifier).startTimer(
                          duration: Duration(minutes: minutes),
                          label: 'Focus Timer ($minutes m)',
                        );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: const Text('Start Timer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else if (activeTimer.state == TimerState.running) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                ),
                onPressed: () {
                  ref.read(alarmTimerProvider.notifier).pauseTimer();
                },
                icon: const Icon(Icons.pause_rounded),
                label: const Text('Pause'),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: EpicordiaColors.errorLight,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                ),
                onPressed: () {
                  ref.read(alarmTimerProvider.notifier).stopTimer();
                },
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Reset'),
              ),
            ] else if (activeTimer.state == TimerState.paused) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: EpicordiaColors.blue600,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                ),
                onPressed: () {
                  ref.read(alarmTimerProvider.notifier).resumeTimer();
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Resume'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                ),
                onPressed: () {
                  ref.read(alarmTimerProvider.notifier).resetTimer();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Active Alarms View
  // ─────────────────────────────────────────────────────────────
  Widget _buildActiveAlarmsTab(BuildContext context, List<InAppAlarm> alarms, bool isDark) {
    final bgCard = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Configured Alarms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 2),
                Text('${alarms.where((a) => a.isEnabled).length} active in-app alarms', style: TextStyle(fontSize: 13, color: textSecondary)),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: EpicordiaColors.blue600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                elevation: 0,
              ),
              onPressed: () => _showAddAlarmModal(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Alarm', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (alarms.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight),
            ),
            child: Column(
              children: [
                Icon(Icons.alarm_off_outlined, size: 40, color: textSecondary),
                const SizedBox(height: 12),
                Text('No alarms set yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 4),
                Text('Tap "+ Add Alarm" to create your first in-app schedule alarm.', style: TextStyle(fontSize: 12, color: textSecondary)),
              ],
            ),
          )
        else
          ...alarms.map((alarm) {
            final nextRing = alarm.timeUntilNextRing;
            final hrs = nextRing.inHours;
            final mins = nextRing.inMinutes.remainder(60);
            final countdownText = hrs > 0 ? 'Rings in $hrs hr $mins min' : 'Rings in $mins min';

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: alarm.isEnabled
                      ? EpicordiaColors.blue600.withValues(alpha: 0.3)
                      : (isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              alarm.formattedTime,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: alarm.isEnabled ? textPrimary : textSecondary.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (alarm.isEnabled)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: EpicordiaColors.blue600.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  countdownText,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: EpicordiaColors.blue600),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alarm.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: alarm.isEnabled ? textPrimary : textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Repeat: ${alarm.repeatDaysSummary}',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: alarm.isEnabled,
                    activeTrackColor: EpicordiaColors.blue600,
                    onChanged: (val) {
                      ref.read(alarmTimerProvider.notifier).toggleAlarm(alarm.id);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: EpicordiaColors.errorLight, size: 20),
                    onPressed: () {
                      ref.read(alarmTimerProvider.notifier).deleteAlarm(alarm.id);
                    },
                  ),
                ],
              ),
            );
          }),
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
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Tasks Scheduled for Today',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap to open details, toggle completion, long-press for options, or launch a focus timer.',
                  style: TextStyle(fontSize: 13, color: EpicordiaColors.textTertiaryLight),
                ),
                const SizedBox(height: 16),

                if (tasks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('No tasks scheduled due today!'),
                    ),
                  )
                else
                  ...tasks.map((task) {
                    final board = boardsMap[task.boardId];
                    final boardTitle = board?.title ?? 'Workspace';
                    final boardColor = EpicordiaColors.blue600;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          InteractiveTaskCard(
                            task: task,
                            boardTitle: boardTitle,
                            boardColor: boardColor,
                          ),
                          Positioned(
                            right: 12,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: bgCard.withValues(alpha: 0.9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                side: const BorderSide(color: EpicordiaColors.blue600),
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
                              icon: const Icon(Icons.timer_outlined, size: 14, color: EpicordiaColors.blue600),
                              label: const Text('25m Focus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: EpicordiaColors.blue600)),
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

class _AlarmsNavItemData {
  final int index;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  _AlarmsNavItemData({
    required this.index,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
