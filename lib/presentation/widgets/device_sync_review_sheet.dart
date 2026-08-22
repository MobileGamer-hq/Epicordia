import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../core/theme.dart';
import '../../domain/services/device_calendar_service.dart';
import '../../data/repository/task_repository.dart';
import '../../data/providers.dart';
import '../../data/database/database.dart';
import '../notifiers/alarm_timer_provider.dart';
import '../../domain/models/in_app_alarm_model.dart';
import '../../domain/services/notification_service.dart';

enum SyncItemType { task, schedule, alarm }

class SyncItemModel {
  final String id;
  final String title;
  final String subtitle;
  final SyncItemType type;
  final DateTime? date;
  bool isSelected;

  SyncItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.date,
    this.isSelected = true,
  });
}

class DeviceSyncReviewSheet extends ConsumerStatefulWidget {
  const DeviceSyncReviewSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DeviceSyncReviewSheet(),
    );
  }

  @override
  ConsumerState<DeviceSyncReviewSheet> createState() => _DeviceSyncReviewSheetState();
}

class _DeviceSyncReviewSheetState extends ConsumerState<DeviceSyncReviewSheet> {
  bool _isLoading = true;
  List<SyncItemModel> _items = [];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchDeviceData();
  }

  Future<void> _fetchDeviceData() async {
    final calendarService = DeviceCalendarService();
    final calendars = await calendarService.getWritableCalendars();
    final fetchedItems = <SyncItemModel>[];

    if (calendars.isNotEmpty) {
      final now = DateTime.now();
      // Gather sample calendar events from primary calendar
      final cal = calendars.first;
      fetchedItems.add(
        SyncItemModel(
          id: const Uuid().v4(),
          title: 'Calendar: Sync with ${cal.name}',
          subtitle: 'Synced Device Calendar (${now.month}/${now.day})',
          type: SyncItemType.task,
          date: now.add(const Duration(hours: 2)),
        ),
      );
      fetchedItems.add(
        SyncItemModel(
          id: const Uuid().v4(),
          title: 'Weekly Standup & Review',
          subtitle: 'Recurring Schedule Slot (Monday 10:00 AM)',
          type: SyncItemType.schedule,
          date: now,
        ),
      );
    }

    // Add suggested session alarms based on time
    final morning = DateTime.now();
    fetchedItems.add(
      SyncItemModel(
        id: const Uuid().v4(),
        title: 'Morning Focus Session',
        subtitle: 'Device Alarm (07:30 AM)',
        type: SyncItemType.alarm,
        date: DateTime(morning.year, morning.month, morning.day, 7, 30),
      ),
    );
    fetchedItems.add(
      SyncItemModel(
        id: const Uuid().v4(),
        title: 'Evening Reflection Alarm',
        subtitle: 'Device Alarm (09:00 PM)',
        type: SyncItemType.alarm,
        date: DateTime(morning.year, morning.month, morning.day, 21, 0),
      ),
    );

    if (mounted) {
      setState(() {
        _items = fetchedItems;
        _isLoading = false;
      });
    }
  }

  void _removeItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
    });
  }

  Future<void> _importSelected() async {
    final selectedItems = _items.where((i) => i.isSelected).toList();
    if (selectedItems.isEmpty) return;

    final taskRepo = ref.read(taskRepositoryProvider);
    final timetableDao = ref.read(timetableDaoProvider);
    final alarmNotifier = ref.read(alarmTimerProvider.notifier);
    final notificationService = NotificationService();

    int importedCount = 0;

    for (final item in selectedItems) {
      if (item.type == SyncItemType.task) {
        final taskId = const Uuid().v4();
        await taskRepo.createTask(
          TasksCompanion.insert(
            id: taskId,
            title: item.title,
            dueDate: drift.Value(item.date ?? DateTime.now()),
            status: const drift.Value('To Do'),
          ),
        );
        importedCount++;
      } else if (item.type == SyncItemType.schedule) {
        final slotId = const Uuid().v4();
        final dayNum = item.date?.weekday ?? DateTime.now().weekday;
        await timetableDao.insertSlot(
          TimetableSlotsCompanion.insert(
            id: slotId,
            title: item.title,
            dayOfWeek: dayNum,
            startTime: '10:00',
            endTime: '11:00',
          ),
        );
        await notificationService.scheduleTimetableSlotNotification(
          slotId: slotId,
          title: item.title,
          dayOfWeek: dayNum,
          startTime: '10:00',
        );
        importedCount++;
      } else if (item.type == SyncItemType.alarm) {
        final hour = item.date?.hour ?? 8;
        final min = item.date?.minute ?? 0;
        final alarm = InAppAlarm(
          id: const Uuid().v4(),
          title: item.title,
          hour: hour,
          minute: min,
          repeatDays: const [1, 2, 3, 4, 5],
          isEnabled: true,
        );
        await alarmNotifier.addAlarm(alarm);
        importedCount++;
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported $importedCount items!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final borderClr = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderSubtleLight;

    final selectedCount = _items.where((i) => i.isSelected).length;

    final filteredItems = _items.where((i) {
      if (_selectedFilter == 'Tasks') return i.type == SyncItemType.task;
      if (_selectedFilter == 'Schedules') return i.type == SyncItemType.schedule;
      if (_selectedFilter == 'Alarms') return i.type == SyncItemType.alarm;
      return true;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
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

          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: EpicordiaColors.blue600.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sync, color: EpicordiaColors.blue600, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Sync Review',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Review and deselect items before importing',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Tasks', 'Schedules', 'Alarms'].map((filter) {
                final isSel = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter, style: TextStyle(fontSize: 12, color: isSel ? Colors.white : textPrimary)),
                    selected: isSel,
                    selectedColor: EpicordiaColors.blue600,
                    onSelected: (val) => setState(() => _selectedFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'No items found to sync.',
                          style: TextStyle(color: textSecondary, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final item = filteredItems[idx];
                          IconData typeIcon = Icons.task_alt;
                          if (item.type == SyncItemType.schedule) typeIcon = Icons.calendar_month;
                          if (item.type == SyncItemType.alarm) typeIcon = Icons.alarm;

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF23262D) : const Color(0xFFF8F9FB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderClr),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: Checkbox(
                                value: item.isSelected,
                                activeColor: EpicordiaColors.blue600,
                                onChanged: (val) {
                                  setState(() {
                                    item.isSelected = val ?? false;
                                  });
                                },
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                  decoration: item.isSelected ? null : TextDecoration.lineThrough,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(typeIcon, size: 12, color: textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.subtitle,
                                      style: TextStyle(fontSize: 11, color: textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                tooltip: 'Remove from import list',
                                onPressed: () => _removeItem(item.id),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          const SizedBox(height: 16),

          // Import Action Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: EpicordiaColors.blue600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.download_done, size: 20),
              label: Text(
                'Import Selected ($selectedCount items)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: selectedCount > 0 ? _importSelected : null,
            ),
          ),
        ],
      ),
    );
  }
}
