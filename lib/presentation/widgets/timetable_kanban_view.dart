import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../data/providers.dart';
import '../../core/theme.dart';
import '../../domain/services/notification_service.dart';
import 'core/interactive_schedule_card.dart';
import 'edit_timetable_slot_dialog.dart';

class TimetableKanbanView extends ConsumerWidget {
  const TimetableKanbanView({super.key});

  static const List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  Future<void> _moveSlotToDay(WidgetRef ref, TimetableSlotEntity slot, int targetDayNumber) async {
    if (slot.dayOfWeek == targetDayNumber) return;
    final dao = ref.read(timetableDaoProvider);
    await dao.updateSlot(slot.copyWith(dayOfWeek: targetDayNumber));

    final notificationService = NotificationService();
    await notificationService.scheduleTimetableSlotNotification(
      slotId: slot.id,
      title: slot.title,
      dayOfWeek: targetDayNumber,
      startTime: slot.startTime,
      location: slot.location,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    final slotsAsync = ref.watch(allTimetableSlotsProvider);

    return slotsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading schedule: $err')),
      data: (allSlots) {
        // Group slots by day of week (1..7)
        final slotsByDay = <int, List<TimetableSlotEntity>>{};
        for (int i = 1; i <= 7; i++) {
          slotsByDay[i] = [];
        }
        for (final slot in allSlots) {
          slotsByDay[slot.dayOfWeek]?.add(slot);
        }

        // Sort slots in each day column by start time
        for (final day in slotsByDay.keys) {
          slotsByDay[day]!.sort((a, b) => a.startTime.compareTo(b.startTime));
        }

        final now = DateTime.now();
        final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;

            if (!isWide) {
              // ── MOBILE LAYOUT: Vertical list of Day Cards ──────────────
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final dayNumber = index + 1;
                  return _buildDayCard(
                    context: context,
                    ref: ref,
                    index: index,
                    daySlots: slotsByDay[dayNumber] ?? [],
                    theme: theme,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    startOfWeek: startOfWeek,
                    now: now,
                  );
                },
              );
            }

            // ── WIDE SCREEN LAYOUT: Responsive Grid of Day Cards ───────
            final int crossAxisCount = constraints.maxWidth >= 1400
                ? 4
                : (constraints.maxWidth >= 950 ? 3 : 2);

            final int rowCount = (7 / crossAxisCount).ceil();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(rowCount, (rowIndex) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: rowIndex == rowCount - 1 ? 40 : 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(crossAxisCount, (colIndex) {
                        final dayIndex = rowIndex * crossAxisCount + colIndex;
                        if (dayIndex >= 7) {
                          return const Expanded(child: SizedBox.shrink());
                        }
                        final dayNumber = dayIndex + 1;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: colIndex == crossAxisCount - 1 ? 0 : 16,
                            ),
                            child: _buildDayCard(
                              context: context,
                              ref: ref,
                              index: dayIndex,
                              daySlots: slotsByDay[dayNumber] ?? [],
                              theme: theme,
                              isDark: isDark,
                              colorScheme: colorScheme,
                              startOfWeek: startOfWeek,
                              now: now,
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDayCard({
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required List<TimetableSlotEntity> daySlots,
    required ThemeData theme,
    required bool isDark,
    required ColorScheme colorScheme,
    required DateTime startOfWeek,
    required DateTime now,
  }) {
    final dayNumber = index + 1;
    final dayName = _dayNames[index];
    final dayDate = startOfWeek.add(Duration(days: index));
    final isToday = dayDate.year == now.year && dayDate.month == now.month && dayDate.day == now.day;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateFormatted = '${months[dayDate.month - 1]} ${dayDate.day}';

    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    return DragTarget<TimetableSlotEntity>(
      onAcceptWithDetails: (details) async {
        await _moveSlotToDay(ref, details.data, dayNumber);
      },
      builder: (context, candidateData, rejectedData) {
        final isTargeted = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: isTargeted
                ? (isDark ? EpicordiaColors.blue900.withValues(alpha: 0.3) : EpicordiaColors.blue100.withValues(alpha: 0.5))
                : (isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTargeted
                  ? (isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600)
                  : (isToday
                      ? (isDark ? EpicordiaColors.blue400.withValues(alpha: 0.7) : EpicordiaColors.blue500.withValues(alpha: 0.8))
                      : (isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight)),
              width: isTargeted ? 2.0 : (isToday ? 1.5 : 1.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Day Section Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? EpicordiaColors.borderSubtleDark
                          : EpicordiaColors.borderSubtleLight,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            dayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateFormatted,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? EpicordiaColors.blue900 : EpicordiaColors.blue100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark ? EpicordiaColors.blue400 : EpicordiaColors.blue500,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'TODAY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? EpicordiaColors.blue900 : EpicordiaColors.blue100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${daySlots.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Day Events List
              if (daySlots.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Center(
                    child: Text(
                      'No events scheduled — drag event here',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textTertiary,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: daySlots.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, slotIndex) {
                    final slot = daySlots[slotIndex];
                    return LongPressDraggable<TimetableSlotEntity>(
                      data: slot,
                      feedback: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                        child: SizedBox(
                          width: 260,
                          child: InteractiveScheduleCard(slot: slot),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.4,
                        child: InteractiveScheduleCard(slot: slot),
                      ),
                      child: InteractiveScheduleCard(slot: slot),
                    );
                  },
                ),

              // Add Event Action
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textSecondary,
                      side: BorderSide(
                        color: isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size.fromHeight(36),
                    ),
                    icon: Icon(
                      Icons.add,
                      size: 16,
                      color: textSecondary,
                    ),
                    label: Text(
                      'Add Event',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                    onPressed: () {
                      EditTimetableSlotDialog.show(
                        context,
                        defaultDayOfWeek: dayNumber,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
