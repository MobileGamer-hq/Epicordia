import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/database.dart';
import '../../data/providers.dart';
import '../../core/theme.dart';
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

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            if (isMobile) {
              // ── MOBILE LAYOUT: Vertical list of Day Cards ──────────────
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final dayNumber = index + 1;
                  final dayName = _dayNames[index];
                  final daySlots = slotsByDay[dayNumber] ?? [];

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? EpicordiaColors.surfaceCardDark
                          : EpicordiaColors.surfaceCardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? EpicordiaColors.borderSubtleDark
                            : EpicordiaColors.borderSubtleLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day Section Header
                        Container(
                          padding: const EdgeInsets.all(14),
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
                              Text(
                                dayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${daySlots.length}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
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
                              vertical: 16,
                            ),
                            child: Text(
                              'No events scheduled for $dayName',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            itemCount: daySlots.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, slotIndex) {
                              final slot = daySlots[slotIndex];
                              return InteractiveScheduleCard(slot: slot);
                            },
                          ),

                        // Add Event Action
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                minimumSize: const Size(120, 36),
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: Text('Add Event for $dayName'),
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

            // ── DESKTOP/TABLET LAYOUT: Horizontal Multi-Column Kanban ─────
            final double columnWidth = constraints.maxWidth > 900
                ? (constraints.maxWidth - (6 * 12) - 32) / 7
                : 280;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(7, (index) {
                  final dayNumber = index + 1;
                  final dayName = _dayNames[index];
                  final daySlots = slotsByDay[dayNumber] ?? [];

                  return Container(
                    width: columnWidth,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? EpicordiaColors.surfaceCardDark
                          : EpicordiaColors.surfaceCardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? EpicordiaColors.borderSubtleDark
                            : EpicordiaColors.borderSubtleLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Column Header
                        Container(
                          padding: const EdgeInsets.all(14),
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
                              Text(
                                dayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${daySlots.length}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Slot Cards List
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 500),
                          child: daySlots.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      'No events scheduled',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.all(12),
                                  itemCount: daySlots.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, slotIndex) {
                                    final slot = daySlots[slotIndex];
                                    return InteractiveScheduleCard(slot: slot);
                                  },
                                ),
                        ),

                        // Add Event Button
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(999),
                                ),
                                minimumSize: const Size.fromHeight(36),
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Event'),
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
                }),
              ),
            );
          },
        );
      },
    );
  }
}
