import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/providers.dart';
import '../../core/theme.dart';
import '../../domain/services/notification_service.dart';

class EditTimetableSlotDialog extends ConsumerStatefulWidget {
  final TimetableSlotEntity? slot;
  final int? defaultDayOfWeek;

  const EditTimetableSlotDialog({
    super.key,
    this.slot,
    this.defaultDayOfWeek,
  });

  static Future<void> show(
    BuildContext context, {
    TimetableSlotEntity? slot,
    int? defaultDayOfWeek,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => EditTimetableSlotDialog(
        slot: slot,
        defaultDayOfWeek: defaultDayOfWeek,
      ),
    );
  }

  @override
  ConsumerState<EditTimetableSlotDialog> createState() => _EditTimetableSlotDialogState();
}

class _EditTimetableSlotDialogState extends ConsumerState<EditTimetableSlotDialog> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _notificationService = NotificationService();

  late Set<int> _selectedDays;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String? _selectedColorTag;

  final List<String> _colorTags = [
    '#0137c3', // Blue
    '#785a00', // Gold/Yellow
    '#00543f', // Emerald
    '#ba1a1a', // Crimson
    '#6E96FF', // Soft Blue
    '#89f1ca', // Mint
  ];

  @override
  void initState() {
    super.initState();
    if (widget.slot != null) {
      _titleController.text = widget.slot!.title;
      _locationController.text = widget.slot!.location ?? '';
      _notesController.text = widget.slot!.notes ?? '';
      _selectedDays = {widget.slot!.dayOfWeek};
      _selectedColorTag = widget.slot!.colorTag;
      _startTime = _parseTimeOfDay(widget.slot!.startTime);
      _endTime = _parseTimeOfDay(widget.slot!.endTime);
    } else {
      _selectedDays = {widget.defaultDayOfWeek ?? 1};
    }
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedDays.isEmpty) return;

    final dao = ref.read(timetableDaoProvider);
    final startTimeStr = _formatTimeOfDay(_startTime);
    final endTimeStr = _formatTimeOfDay(_endTime);
    final locText = _locationController.text.trim().isEmpty ? null : _locationController.text.trim();
    final notesText = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    if (widget.slot != null) {
      final primaryDay = _selectedDays.first;
      await dao.updateSlot(
        widget.slot!.copyWith(
          title: title,
          location: drift.Value(locText),
          dayOfWeek: primaryDay,
          startTime: startTimeStr,
          endTime: endTimeStr,
          colorTag: drift.Value(_selectedColorTag),
          notes: drift.Value(notesText),
        ),
      );
      await _notificationService.scheduleTimetableSlotNotification(
        slotId: widget.slot!.id,
        title: title,
        dayOfWeek: primaryDay,
        startTime: startTimeStr,
        location: locText,
      );

      final otherDays = _selectedDays.where((d) => d != primaryDay);
      for (final dayNum in otherDays) {
        final slotId = const Uuid().v4();
        await dao.insertSlot(
          TimetableSlotsCompanion.insert(
            id: slotId,
            title: title,
            dayOfWeek: dayNum,
            startTime: startTimeStr,
            endTime: endTimeStr,
            location: drift.Value(locText),
            colorTag: drift.Value(_selectedColorTag),
            notes: drift.Value(notesText),
          ),
        );
        await _notificationService.scheduleTimetableSlotNotification(
          slotId: slotId,
          title: title,
          dayOfWeek: dayNum,
          startTime: startTimeStr,
          location: locText,
        );
      }
    } else {
      for (final dayNum in _selectedDays) {
        final slotId = const Uuid().v4();
        await dao.insertSlot(
          TimetableSlotsCompanion.insert(
            id: slotId,
            title: title,
            dayOfWeek: dayNum,
            startTime: startTimeStr,
            endTime: endTimeStr,
            location: drift.Value(locText),
            colorTag: drift.Value(_selectedColorTag),
            notes: drift.Value(notesText),
          ),
        );
        await _notificationService.scheduleTimetableSlotNotification(
          slotId: slotId,
          title: title,
          dayOfWeek: dayNum,
          startTime: startTimeStr,
          location: locText,
        );
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.slot != null) {
      await ref.read(timetableDaoProvider).deleteSlot(widget.slot!.id);
      await _notificationService.cancelTimetableSlotNotification(widget.slot!.id);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final borderClr = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderSubtleLight;
    final isEditing = widget.slot != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: cardBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Schedule Event' : 'Add Schedule Event',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight),
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Title Input
            TextField(
              controller: _titleController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: 'Event Title (e.g. Math 101, Gym)',
                labelStyle: TextStyle(color: textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            // Multi-Day Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Days of Week (Select one or more):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (index) {
                      final dayNum = index + 1;
                      final dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index];
                      final isSelected = _selectedDays.contains(dayNum);

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(
                            dayShort,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : textPrimary,
                            ),
                          ),
                          selectedColor: isDark ? EpicordiaColors.blue600 : EpicordiaColors.blue700,
                          backgroundColor: isDark ? const Color(0xFF2B2E34) : const Color(0xFFF3F4F6),
                          showCheckmark: false,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDays.add(dayNum);
                              } else {
                                if (_selectedDays.length > 1) {
                                  _selectedDays.remove(dayNum);
                                }
                              }
                            });
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Start & End Time Pickers
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderClr),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(Icons.access_time, color: textSecondary),
                    label: Text('Start: ${_startTime.format(context)}', style: TextStyle(color: textPrimary, fontSize: 12)),
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (time != null) setState(() => _startTime = time);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderClr),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(Icons.access_time_filled, color: textSecondary),
                    label: Text('End: ${_endTime.format(context)}', style: TextStyle(color: textPrimary, fontSize: 12)),
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                      );
                      if (time != null) setState(() => _endTime = time);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location Input
            TextField(
              controller: _locationController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: 'Location / Room (Optional)',
                labelStyle: TextStyle(color: textSecondary),
              ),
            ),
            const SizedBox(height: 16),

            // Color Tag Selector
            Text('Color Accent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: _colorTags.map((colorHex) {
                final isSelected = _selectedColorTag == colorHex;
                final color = Color(int.parse(colorHex.replaceFirst('#', '0xff')));
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorTag = colorHex),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: textPrimary, width: 2.5)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Notes Input
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                labelStyle: TextStyle(color: textSecondary),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: borderClr),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: TextStyle(color: textPrimary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: EpicordiaColors.blue600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: _save,
                    child: Text(
                      isEditing ? 'Save' : 'Create',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
