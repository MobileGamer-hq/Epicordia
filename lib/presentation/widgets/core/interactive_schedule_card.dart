import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/database/database.dart';
import '../../../data/providers.dart';
import '../edit_timetable_slot_dialog.dart';
import 'item_interaction_dialogs.dart';

class InteractiveScheduleCard extends ConsumerWidget {
  final TimetableSlotEntity slot;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;

  const InteractiveScheduleCard({
    super.key,
    required this.slot,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    const dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final dayName = (slot.dayOfWeek >= 1 && slot.dayOfWeek <= 7)
        ? dayNames[slot.dayOfWeek - 1]
        : 'Day ${slot.dayOfWeek}';

    Color accentColor = colorScheme.primary;
    if (slot.colorTag != null && slot.colorTag!.isNotEmpty) {
      try {
        accentColor = Color(int.parse(slot.colorTag!.replaceFirst('#', '0xff')));
      } catch (_) {}
    }

    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    return GestureDetector(
      onTap: onTap ??
          () => EditTimetableSlotDialog.show(
                context,
                slot: slot,
              ),
      onLongPress: onLongPress ??
          () => ItemInteractionDialogs.showScheduleDetailDialog(
                context: context,
                ref: ref,
                slot: slot,
              ),
      onDoubleTap: onDoubleTap ??
          () => ItemInteractionDialogs.showDoubleTapMenu(
                context: context,
                title: slot.title,
                subtitle: '$dayName (${slot.startTime} - ${slot.endTime})',
                items: [
                  DoubleTapMenuItem(
                    icon: Icons.copy_rounded,
                    label: 'Copy Schedule Info',
                    onTap: () {
                      ItemInteractionDialogs.copyToClipboard(
                        context,
                        'Schedule Event: ${slot.title}\nDay: $dayName\nTime: ${slot.startTime} - ${slot.endTime}\nLocation: ${slot.location ?? 'N/A'}\nNotes: ${slot.notes ?? ''}',
                      );
                    },
                  ),
                  DoubleTapMenuItem(
                    icon: Icons.share_outlined,
                    label: 'Share Schedule Info',
                    onTap: () {
                      ItemInteractionDialogs.shareContent(
                        context,
                        'Schedule Event: ${slot.title}\nDay: $dayName\nTime: ${slot.startTime} - ${slot.endTime}\nLocation: ${slot.location ?? 'N/A'}\nNotes: ${slot.notes ?? ''}',
                      );
                    },
                  ),
                  DoubleTapMenuItem(
                    icon: Icons.edit_calendar_rounded,
                    label: 'Edit Event',
                    onTap: () => EditTimetableSlotDialog.show(context, slot: slot),
                  ),
                  DoubleTapMenuItem(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete Event',
                    color: EpicordiaColors.errorLight,
                    onTap: () async {
                      await ref.read(timetableDaoProvider).deleteSlot(slot.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Schedule event deleted'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderClr),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${slot.startTime} - ${slot.endTime}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    slot.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight,
                    ),
                  ),
                  if (slot.location != null && slot.location!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            slot.location!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
