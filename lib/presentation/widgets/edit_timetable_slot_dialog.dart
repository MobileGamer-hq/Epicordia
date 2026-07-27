import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/providers.dart';
import '../../core/theme.dart';

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

  late int _selectedDay;
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

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.slot != null) {
      _titleController.text = widget.slot!.title;
      _locationController.text = widget.slot!.location ?? '';
      _notesController.text = widget.slot!.notes ?? '';
      _selectedDay = widget.slot!.dayOfWeek;
      _selectedColorTag = widget.slot!.colorTag;
      _startTime = _parseTimeOfDay(widget.slot!.startTime);
      _endTime = _parseTimeOfDay(widget.slot!.endTime);
    } else {
      _selectedDay = widget.defaultDayOfWeek ?? 1;
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
    if (title.isEmpty) return;

    final dao = ref.read(timetableDaoProvider);
    final startTimeStr = _formatTimeOfDay(_startTime);
    final endTimeStr = _formatTimeOfDay(_endTime);

    if (widget.slot != null) {
      await dao.updateSlot(
        widget.slot!.copyWith(
          title: title,
          location: drift.Value(_locationController.text.trim().isEmpty ? null : _locationController.text.trim()),
          dayOfWeek: _selectedDay,
          startTime: startTimeStr,
          endTime: endTimeStr,
          colorTag: drift.Value(_selectedColorTag),
          notes: drift.Value(_notesController.text.trim().isEmpty ? null : _notesController.text.trim()),
        ),
      );
    } else {
      final newId = const Uuid().v4();
      await dao.insertSlot(
        TimetableSlotsCompanion.insert(
          id: newId,
          title: title,
          dayOfWeek: _selectedDay,
          startTime: startTimeStr,
          endTime: endTimeStr,
          location: drift.Value(_locationController.text.trim().isEmpty ? null : _locationController.text.trim()),
          colorTag: drift.Value(_selectedColorTag),
          notes: drift.Value(_notesController.text.trim().isEmpty ? null : _notesController.text.trim()),
        ),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.slot != null) {
      await ref.read(timetableDaoProvider).deleteSlot(widget.slot!.id);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.slot != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // radius-l
      ),
      backgroundColor: colorScheme.surface,
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: EpicordiaColors.errorLight),
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Title Input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Event Title (e.g. Math 101, Gym)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // radius-s
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Day of Week Selector
            DropdownButtonFormField<int>(
              value: _selectedDay,
              decoration: InputDecoration(
                labelText: 'Day of Week',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: List.generate(7, (index) {
                return DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text(_days[index]),
                );
              }),
              onChanged: (val) {
                if (val != null) setState(() => _selectedDay = val);
              },
            ),
            const SizedBox(height: 16),

            // Start & End Time Pickers
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.access_time),
                    label: Text('Start: ${_startTime.format(context)}'),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.access_time_filled),
                    label: Text('End: ${_endTime.format(context)}'),
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
              decoration: InputDecoration(
                labelText: 'Location / Room (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Color Tag Selector
            Text('Color Accent', style: theme.textTheme.labelLarge),
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
                          ? Border.all(color: colorScheme.onSurface, width: 2.5)
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
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: _save,
                    child: Text(isEditing ? 'Save' : 'Create'),
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
