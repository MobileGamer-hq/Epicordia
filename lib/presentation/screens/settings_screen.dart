import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_lock_provider.dart';
import '../../core/board_settings_provider.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../domain/services/data_export_service.dart';
import '../../data/providers.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/board_repository.dart';
import 'pin_lock_screen.dart';
import '../notifiers/alarm_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/state/journaling_provider.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _defaultView = 'Canvas';
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final currentName = ref.read(userNameProvider);
    _nameController = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveUserName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    await ref.read(userNameProvider.notifier).updateName(newName);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Display name updated to "$newName"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.code, color: EpicordiaColors.blue600),
              title: const Text('Export Workspace as JSON'),
              subtitle: const Text('Full snapshot of boards, pins, tasks, and timetable'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final db = ref.read(databaseProvider);
                final jsonStr = await DataExportService.generateWorkspaceJson(db);
                final path = await DataExportService.saveExportToFile(
                  fileName: 'epicordia_workspace_export.json',
                  content: jsonStr,
                );
                if (context.mounted && path != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Workspace exported to $path'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: EpicordiaColors.blue600),
              title: const Text('Export Weekly Schedule as CSV'),
              subtitle: const Text('Weekly recurring schedule in spreadsheet format'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final slots = ref.read(allTimetableSlotsProvider).value ?? [];
                final csvStr = DataExportService.exportTimetableToCsv(slots);
                final path = await DataExportService.saveExportToFile(
                  fileName: 'epicordia_schedule_export.csv',
                  content: csvStr,
                );
                if (context.mounted && path != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Weekly Schedule exported to $path'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: EpicordiaColors.blue600),
              title: const Text('Export Tasks as CSV'),
              subtitle: const Text('Tasks list with status, dates, and boards'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final tasks = ref.read(allTasksProvider).value ?? [];
                final boards = ref.read(allBoardsProvider).value ?? [];
                final boardsMap = {for (final b in boards) b.id: b};
                final csvStr = DataExportService.exportTasksToCsv(tasks, boardsMap);
                final path = await DataExportService.saveExportToFile(
                  fileName: 'epicordia_tasks_export.csv',
                  content: csvStr,
                );
                if (context.mounted && path != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tasks exported to $path'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmResetAppData(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              'Reset App Data?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete all your boards, tasks, notes, schedule, and saved settings. You will be returned to the onboarding screen to enter your name and purpose for using the app.\n\nThis action cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _resetAppData(context);
    }
  }

  Future<void> _resetAppData(BuildContext context) async {
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      for (final table in db.allTables) {
        await db.delete(table).go();
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App data reset successfully. Welcome back to Onboarding!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final themeNotifier = ref.read(themeModeProvider.notifier);
    final selectedThemeString = themeNotifier.currentModeString;

    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;

    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        backgroundColor: bgApp,
        elevation: 0,
        // titleSpacing: 20,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: textPrimary,
          ),
          onPressed: () => context.pop(),
        ),

        // leadingWidth: 160,
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.search, color: textPrimary),
        //     onPressed: () {},
        //   ),
        //   const SizedBox(width: 8),
        // ],
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
          children: [
            // ── Profile ──────────────────────────────────────────
            const _SectionHeader(icon: Icons.person_outline, label: 'Profile & Display Name'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Name',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Used for greetings on Today\'s Dashboard and throughout your workspace.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _saveUserName(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            hintStyle: TextStyle(
                              color: isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight,
                              fontSize: 14,
                            ),
                            // prefixIcon: Icon(
                            //   Icons.badge_outlined,
                            //   color: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600,
                            //   size: 20,
                            // ),
                            filled: true,
                            fillColor: isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _saveUserName,
                        style: FilledButton.styleFrom(
                          backgroundColor: EpicordiaColors.blue600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Appearance ──────────────────────────────────────
            const _SectionHeader(icon: Icons.palette_outlined, label: 'Appearance'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? EpicordiaColors.textSecondaryDark
                          : EpicordiaColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SegmentedToggle(
                    options: const ['Light', 'Dark', 'System'],
                    selected: selectedThemeString,
                    onSelect: (v) {
                      ref.read(themeModeProvider.notifier).setThemeMode(v);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: EpicordiaColors.borderSubtleLight),
                  const SizedBox(height: 16),
                  Text(
                    'Board Toolbar Position',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? EpicordiaColors.textSecondaryDark
                          : EpicordiaColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, _) {
                      final pos = ref.watch(toolbarPositionProvider);
                      final currentLabel = pos.name[0].toUpperCase() + pos.name.substring(1);
                      return _SegmentedToggle(
                        options: const ['Left', 'Right', 'Bottom'],
                        selected: currentLabel,
                        onSelect: (v) {
                          final targetPos = ToolbarPosition.values.firstWhere(
                            (e) => e.name.toLowerCase() == v.toLowerCase(),
                            orElse: () => ToolbarPosition.left,
                          );
                          ref.read(toolbarPositionProvider.notifier).setPosition(targetPos);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Default View ─────────────────────────────────────
            const _SectionHeader(
                icon: Icons.space_dashboard_outlined, label: 'Default View'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: ['Canvas', 'List', 'Focus'].map((view) {
                  final active = _defaultView == view;
                  return _RadioRow(
                    icon: view == 'Canvas'
                        ? Icons.brush_outlined
                        : view == 'List'
                            ? Icons.format_list_bulleted
                            : Icons.center_focus_strong_outlined,
                    label: '$view View',
                    selected: active,
                    onTap: () => setState(() => _defaultView = view),
                    showDivider: view != 'Focus',
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // ── Alarms & Timers Engine ────────────────────────────
            const _SectionHeader(
                icon: Icons.alarm_outlined, label: 'Alarms & Timers Engine'),
            const SizedBox(height: 10),
            Consumer(
              builder: (context, ref, _) {
                final useSystem = ref.watch(alarmSettingsProvider);

                return _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SwitchRow(
                        icon: Icons.app_shortcut_outlined,
                        label: 'Use Native System Clock App',
                        value: useSystem,
                        onChanged: (enabled) {
                          ref.read(alarmSettingsProvider.notifier).setUseSystemClockApp(enabled);
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        useSystem
                            ? 'Timer & alarm creation opens your device\'s system Clock app (Android/iOS handoff).'
                            : 'Alarms and timers run directly in Epicordia with animated progress rings & active alarm lists.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? EpicordiaColors.textTertiaryDark
                              : EpicordiaColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Journaling Plan & Habit ─────────────────────────────
            const _SectionHeader(
                icon: Icons.edit_calendar_outlined, label: 'Journaling Plan & Habit'),
            const SizedBox(height: 10),
            Consumer(
              builder: (context, ref, _) {
                final journalingState = ref.watch(journalingPlanProvider);
                final journalingNotifier = ref.read(journalingPlanProvider.notifier);

                return _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SwitchRow(
                        icon: Icons.notifications_active_outlined,
                        label: 'Enable Journaling Habit Plan',
                        value: journalingState.isEnabled,
                        onChanged: (enabled) async {
                          await journalingNotifier.updatePlan(isEnabled: enabled);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  enabled
                                      ? 'Journaling habit enabled. Automatic reminders scheduled!'
                                      : 'Journaling habit disabled. Reminders cancelled.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        showDivider: journalingState.isEnabled,
                      ),
                      if (journalingState.isEnabled) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Target Frequency',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _SegmentedToggle(
                          options: const ['Daily', '5 Days', '3 Days'],
                          selected: journalingState.frequency == 'daily'
                              ? 'Daily'
                              : (journalingState.frequency == 'fiveDays' ? '5 Days' : '3 Days'),
                          onSelect: (v) {
                            final targetFreq = v == 'Daily'
                                ? 'daily'
                                : (v == '5 Days' ? 'fiveDays' : 'threeDays');
                            journalingNotifier.updatePlan(frequency: targetFreq);
                          },
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: EpicordiaColors.borderSubtleLight),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(Icons.access_time_outlined,
                                size: 18,
                                color: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600),
                            const SizedBox(width: 10),
                            Text(
                              'Reminder Time',
                              style: TextStyle(
                                fontSize: 14,
                                color: textPrimary,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                    hour: journalingState.reminderHour,
                                    minute: journalingState.reminderMinute,
                                  ),
                                );
                                if (picked != null) {
                                  journalingNotifier.updatePlan(
                                    reminderHour: picked.hour,
                                    reminderMinute: picked.minute,
                                  );
                                }
                              },
                              child: Text(
                                journalingState.formattedTime,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '${journalingState.currentStreak} Days',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Current Streak',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              Container(height: 28, width: 1, color: EpicordiaColors.borderSubtleLight),
                              Column(
                                children: [
                                  Text(
                                    '${journalingState.longestStreak} Days',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Longest Streak',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Privacy & Security ────────────────────────────────

            const _SectionHeader(
                icon: Icons.shield_outlined, label: 'Privacy & Security'),
            const SizedBox(height: 10),
            Consumer(
              builder: (context, ref, _) {
                final lockState = ref.watch(appLockProvider);
                final lockNotifier = ref.read(appLockProvider.notifier);
                final lockAllJournals = ref.watch(lockAllJournalsProvider);
                final lockAllNotifier = ref.read(lockAllJournalsProvider.notifier);

                return _Card(
                  child: Column(
                    children: [
                      _SwitchRow(
                        icon: Icons.lock_outline,
                        label: 'App Lock',
                        value: lockState.isEnabled,
                        onChanged: (enabled) async {
                          if (enabled) {
                            if (!lockState.hasPin) {
                              final created = await PinLockScreen.showCreate(context);
                              if (created == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('App Lock enabled with your new PIN.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } else {
                              await lockNotifier.enableAppLock();
                            }
                          } else {
                            final verified = await PinLockScreen.showVerify(context);
                            if (verified == true && context.mounted) {
                              await lockNotifier.disableAppLock();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('App Lock disabled.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        showDivider: true,
                      ),
                      _SwitchRow(
                        icon: Icons.security_rounded,
                        label: 'Lock All Journal Notes',
                        value: lockAllJournals,
                        onChanged: (enabled) async {
                          if (enabled && !lockState.hasPin) {
                            final created = await PinLockScreen.showCreate(context);
                            if (created == true) {
                              await lockAllNotifier.toggle(true);
                            }
                          } else {
                            await lockAllNotifier.toggle(enabled);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  enabled
                                      ? 'All journal notes are now PIN locked.'
                                      : 'Global journal lock disabled.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        showDivider: true,
                      ),
                      _ActionRow(
                        icon: Icons.pin_outlined,
                        label: 'Change PIN',
                        labelColor: isDark
                            ? EpicordiaColors.blue300
                            : EpicordiaColors.blue600,
                        showChevron: true,
                        onTap: () async {
                          if (!lockState.hasPin) {
                            final created = await PinLockScreen.showCreate(context);
                            if (created == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN created successfully.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            final changed = await PinLockScreen.showChange(context);
                            if (changed == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('PIN changed successfully.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Data & Backup ─────────────────────────────────────
            const _SectionHeader(
                icon: Icons.cloud_outlined, label: 'Data ',),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: [
                  // Text(
                  //   'Do What You Want With Your Data',
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     color: isDark
                  //         ? EpicordiaColors.textSecondaryDark
                  //         : EpicordiaColors.textSecondaryLight,
                  //   ),
                  // ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showExportOptions(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? EpicordiaColors.borderStrongDark
                                  : EpicordiaColors.borderStrongLight,
                            ),
                            foregroundColor: textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Export All Data',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _confirmResetAppData(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? EpicordiaColors.errorDark
                                  : EpicordiaColors.errorLight,
                            ),
                            foregroundColor: isDark
                                ? EpicordiaColors.errorDark
                                : EpicordiaColors.errorLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Reset App Data',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── About ─────────────────────────────────────────────
            const _SectionHeader(icon: Icons.info_outline, label: 'About'),
            const SizedBox(height: 10),
            const _Card(
              child: Column(
                children: [
                  _InfoRow(
                      label: 'Version',
                      value: 'v1.0.3-stable',
                      showDivider: true),
                  _ActionRow(
                      label: 'Terms of Service',
                      icon: Icons.open_in_new,
                      onTap: null,
                      showChevron: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable section header ──────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? EpicordiaColors.textSecondaryDark
        : EpicordiaColors.textSecondaryLight;
    final textPrimary = isDark
        ? EpicordiaColors.textPrimaryDark
        : EpicordiaColors.textPrimaryLight;

    return Row(
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Card wrapper ──────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? EpicordiaColors.surfaceCardDark
            : EpicordiaColors.surfaceCardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? EpicordiaColors.borderSubtleDark
              : EpicordiaColors.borderSubtleLight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }
}

// ── Segmented toggle ──────────────────────────────────────────────────
class _SegmentedToggle extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  const _SegmentedToggle({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? EpicordiaColors.textSecondaryDark
        : EpicordiaColors.textSecondaryLight;
    final borderSubtle = isDark
        ? EpicordiaColors.borderStrongDark
        : EpicordiaColors.borderSubtleLight;

    return Row(
      children: options.map((opt) {
        final active = opt == selected;
        final activeColor = isDark
            ? EpicordiaColors.blue500
            : EpicordiaColors.blue600;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? activeColor : borderSubtle,
                  ),
                ),
                child: Text(
                  opt,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Radio row ─────────────────────────────────────────────────────────
class _RadioRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;
  const _RadioRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? EpicordiaColors.textSecondaryDark
        : EpicordiaColors.textSecondaryLight;
    final textPrimary = isDark
        ? EpicordiaColors.textPrimaryDark
        : EpicordiaColors.textPrimaryLight;
    final borderSubtle = isDark
        ? EpicordiaColors.borderSubtleDark
        : EpicordiaColors.borderSubtleLight;
    final borderStrong = isDark
        ? EpicordiaColors.borderStrongDark
        : EpicordiaColors.borderStrongLight;
    final activeColor = isDark
        ? EpicordiaColors.blue500
        : EpicordiaColors.blue600;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 14, color: textPrimary),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? activeColor : Colors.transparent,
                    border: Border.all(
                      color: selected ? activeColor : borderStrong,
                      width: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, color: borderSubtle),
      ],
    );
  }
}

// ── Switch row ────────────────────────────────────────────────────────
class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? EpicordiaColors.textSecondaryDark
        : EpicordiaColors.textSecondaryLight;
    final textPrimary = isDark
        ? EpicordiaColors.textPrimaryDark
        : EpicordiaColors.textPrimaryLight;
    final borderSubtle = isDark
        ? EpicordiaColors.borderSubtleDark
        : EpicordiaColors.borderSubtleLight;
    final activeColor = isDark
        ? EpicordiaColors.blue500
        : EpicordiaColors.blue600;

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: textPrimary),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: activeColor,
            ),
          ],
        ),
        if (showDivider) Divider(height: 1, color: borderSubtle),
      ],
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color? labelColor;
  const _ActionRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.showChevron = true,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? EpicordiaColors.textSecondaryDark
        : EpicordiaColors.textSecondaryLight;
    final textPrimary = isDark
        ? EpicordiaColors.textPrimaryDark
        : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark
        ? EpicordiaColors.textTertiaryDark
        : EpicordiaColors.textTertiaryLight;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: labelColor ?? textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? textPrimary,
                ),
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right, size: 18, color: textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;
  const _InfoRow({
    required this.label,
    required this.value,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? EpicordiaColors.textSecondaryDark
        : EpicordiaColors.textSecondaryLight;
    final textPrimary = isDark
        ? EpicordiaColors.textPrimaryDark
        : EpicordiaColors.textPrimaryLight;
    final borderSubtle = isDark
        ? EpicordiaColors.borderSubtleDark
        : EpicordiaColors.borderSubtleLight;
    final surfaceSunken = isDark
        ? EpicordiaColors.surfaceSunkenDark
        : EpicordiaColors.surfaceSunkenLight;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: surfaceSunken,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: borderSubtle),
      ],
    );
  }
}
