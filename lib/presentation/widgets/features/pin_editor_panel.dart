import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:epicorida/core/theme.dart';
import 'package:epicorida/data/database/database.dart';
import 'package:epicorida/data/providers.dart';
import 'package:epicorida/data/repository/pin_repository.dart';
import 'package:epicorida/data/repository/task_repository.dart';


// ---------------------------------------------------------------------------
// Color-tag palette (shared with BoardPinCard)
// ---------------------------------------------------------------------------

const Map<String, Color> _kTagColors = {
  'yellow': Color(0xFFF4C453),
  'coral': Color(0xFFF0806B),
  'mint': Color(0xFF5FC7A3),
  'lavender': Color(0xFF9C8CF0),
  'sky': Color(0xFF5FA8F5),
  'grey': Color(0xFFB9BCC2),
};

Color? _colorFromTag(String? tag) {
  if (tag == null || tag.isEmpty) return null;
  return _kTagColors[tag.toLowerCase()];
}

// ---------------------------------------------------------------------------
// Entry-point helper
// ---------------------------------------------------------------------------

/// Opens [PinEditorPanel] as a modal bottom sheet.
void showPinEditorPanel(
  BuildContext context, {
  required String pinId,
  required String boardId,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PinEditorPanel(
      pinId: pinId,
      boardId: boardId,
      onClose: () => Navigator.of(context).pop(),
    ),
  );
}

// ---------------------------------------------------------------------------
// PinEditorPanel
// ---------------------------------------------------------------------------

class PinEditorPanel extends ConsumerStatefulWidget {
  const PinEditorPanel({
    super.key,
    required this.pinId,
    required this.boardId,
    required this.onClose,
  });

  final String pinId;
  final String boardId;
  final VoidCallback onClose;

  @override
  ConsumerState<PinEditorPanel> createState() => _PinEditorPanelState();
}

class _PinEditorPanelState extends ConsumerState<PinEditorPanel> {
  PinEntity? _pin;
  TaskEntity? _task;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pinDao = ref.read(pinDaoProvider);
    final taskDao = ref.read(taskDaoProvider);

    final pin = await pinDao.getPin(widget.pinId);
    TaskEntity? task;
    if (pin != null && pin.type == 'task') {
      final allTasks = await taskDao.select(taskDao.tasks).get();
      try {
        task = allTasks.firstWhere((t) => t.pinId == pin.id);
      } catch (_) {
        task = null;
      }
    }

    if (mounted) {
      setState(() {
        _pin = pin;
        _task = task;
        _loading = false;
      });
    }
  }

  Future<void> _refreshPin() async {
    final pin = await ref.read(pinDaoProvider).getPin(widget.pinId);
    if (mounted) setState(() => _pin = pin);
  }

  Future<void> _refreshTask() async {
    if (_pin == null) return;
    final taskDao = ref.read(taskDaoProvider);
    final allTasks = await taskDao.select(taskDao.tasks).get();
    TaskEntity? task;
    try {
      task = allTasks.firstWhere((t) => t.pinId == _pin!.id);
    } catch (_) {
      task = null;
    }
    if (mounted) setState(() => _task = task);
  }

  Future<void> _updateColorTag(String? tag) async {
    if (_pin == null) return;
    final updated = _pin!.copyWith(colorTag: Value(tag));
    await ref.read(pinRepositoryProvider).updatePin(updated);
    if (mounted) setState(() => _pin = updated);
  }

  Future<void> _deletePin() async {
    final confirmed = await _showDeleteConfirm();
    if (!confirmed) return;
    if (_pin == null) return;

    if (_task != null) {
      await ref.read(taskRepositoryProvider).deleteTask(_task!.id);
    }
    await ref.read(pinRepositoryProvider).deletePin(_pin!.id);
    widget.onClose();
  }

  Future<bool> _showDeleteConfirm() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EpicordiaColors.surfaceCardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete pin?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: EpicordiaColors.textPrimaryLight,
          ),
        ),
        content: const Text(
          'This action cannot be undone. The pin will be permanently removed from the board.',
          style: TextStyle(
            fontSize: 14,
            color: EpicordiaColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: EpicordiaColors.textSecondaryLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: EpicordiaColors.errorLight, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EpicordiaColors.borderStrongLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          if (!_loading && _pin != null) _PanelHeader(pin: _pin!, onClose: widget.onClose),
          // Body
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(
                color: EpicordiaColors.blue600,
                strokeWidth: 2,
              ),
            )
          else if (_pin == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Text(
                'Pin not found.',
                style: TextStyle(color: EpicordiaColors.textSecondaryLight),
              ),
            )
          else
            Flexible(
              child: _buildBody(),
            ),
          // Bottom action bar
          if (!_loading && _pin != null)
            _BottomActionBar(
              currentTag: _pin!.colorTag,
              onTagSelected: _updateColorTag,
              onDelete: _deletePin,
            ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final pin = _pin!;
    return switch (pin.type) {
      'note' => _NoteEditor(pin: pin, onSaved: _refreshPin),
      'task' => _TaskEditor(
          pin: pin,
          task: _task,
          onPinSaved: _refreshPin,
          onTaskSaved: _refreshTask,
        ),
      'checklist' => _ChecklistEditor(pin: pin, onSaved: _refreshPin),
      _ => _PlaceholderEditor(pinType: pin.type),
    };
  }
}

// ---------------------------------------------------------------------------
// Panel Header
// ---------------------------------------------------------------------------

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.pin, required this.onClose});

  final PinEntity pin;
  final VoidCallback onClose;

  static const Map<String, IconData> _typeIcons = {
    'note': Icons.sticky_note_2_outlined,
    'task': Icons.check_circle_outline,
    'checklist': Icons.checklist_rounded,
    'image': Icons.image_outlined,
    'link': Icons.link,
    'drawing': Icons.draw_outlined,
    'audio': Icons.mic_none_outlined,
    'heading': Icons.title,
    'table': Icons.table_chart_outlined,
    'frame': Icons.crop_square_outlined,
    'board': Icons.dashboard_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _typeIcons[pin.type] ?? Icons.push_pin_outlined;
    final indicatorColor = _colorFromTag(pin.colorTag);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (indicatorColor != null)
            Container(
              width: 4,
              height: 20,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Icon(icon, size: 16, color: EpicordiaColors.blue600),
          const SizedBox(width: 8),
          Text(
            pin.type.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: EpicordiaColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: EpicordiaColors.surfaceSunkenLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close,
                size: 18,
                color: EpicordiaColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NOTE EDITOR
// ---------------------------------------------------------------------------

class _NoteEditor extends ConsumerStatefulWidget {
  const _NoteEditor({required this.pin, required this.onSaved});

  final PinEntity pin;
  final VoidCallback onSaved;

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final TextEditingController _ctrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.pin.content ?? '');
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _save() async {
    final updated = widget.pin.copyWith(
      content: Value(_ctrl.text),
      modifiedAt: DateTime.now(),
    );
    await ref.read(pinRepositoryProvider).updatePin(updated);
    widget.onSaved();
  }

  void _wrapSelection(String prefix, [String? suffix]) {
    final sel = _ctrl.selection;
    final text = _ctrl.text;
    suffix ??= prefix;
    if (!sel.isValid) return;

    final before = text.substring(0, sel.start);
    final selected = text.substring(sel.start, sel.end);
    final after = text.substring(sel.end);

    final newText = '$before$prefix$selected$suffix$after';
    _ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: sel.start + prefix.length,
        extentOffset: sel.end + prefix.length,
      ),
    );
  }

  void _insertLinePrefix(String prefix) {
    final text = _ctrl.text;
    final sel = _ctrl.selection;
    if (!sel.isValid) return;

    final lineStart = text.lastIndexOf('\n', sel.start - 1) + 1;
    final newText =
        text.substring(0, lineStart) + prefix + text.substring(lineStart);
    _ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + prefix.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontSize: 15,
                color: EpicordiaColors.textPrimaryLight,
                height: 1.6,
              ),
              decoration: const InputDecoration(
                hintText: 'Start writing\u2026',
                hintStyle: TextStyle(color: EpicordiaColors.textTertiaryLight),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        // Formatting toolbar
        Container(
          height: 44,
          decoration: const BoxDecoration(
            border:
                Border(top: BorderSide(color: EpicordiaColors.borderSubtleLight)),
          ),
          child: Row(
            children: [
              _FmtButton(
                icon: Icons.format_bold,
                label: 'Bold',
                onTap: () => _wrapSelection('**'),
              ),
              _FmtButton(
                icon: Icons.format_italic,
                label: 'Italic',
                onTap: () => _wrapSelection('_'),
              ),
              _FmtButton(
                icon: Icons.format_list_bulleted,
                label: 'Bullet list',
                onTap: () => _insertLinePrefix('- '),
              ),
              _FmtButton(
                icon: Icons.format_list_numbered,
                label: 'Numbered list',
                onTap: () => _insertLinePrefix('1. '),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FmtButton extends StatelessWidget {
  const _FmtButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(icon, size: 20, color: EpicordiaColors.textSecondaryLight),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TASK EDITOR
// ---------------------------------------------------------------------------

class _TaskEditor extends ConsumerStatefulWidget {
  const _TaskEditor({
    required this.pin,
    required this.task,
    required this.onPinSaved,
    required this.onTaskSaved,
  });

  final PinEntity pin;
  final TaskEntity? task;
  final VoidCallback onPinSaved;
  final VoidCallback onTaskSaved;

  @override
  ConsumerState<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends ConsumerState<_TaskEditor> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  Timer? _debounce;

  String _status = 'todo';
  int _priority = 0;
  DateTime? _dueDate;
  DateTime? _scheduledDate;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleCtrl =
        TextEditingController(text: task?.title ?? widget.pin.content ?? '');
    _notesCtrl = TextEditingController(text: task?.notes ?? '');
    _status = task?.status ?? 'todo';
    _priority = task?.priority ?? 0;
    _dueDate = task?.dueDate;
    _scheduledDate = task?.scheduledDate;

    _titleCtrl.addListener(_scheduleTaskSave);
    _notesCtrl.addListener(_scheduleTaskSave);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleCtrl.removeListener(_scheduleTaskSave);
    _notesCtrl.removeListener(_scheduleTaskSave);
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _scheduleTaskSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _save() async {
    final task = widget.task;
    if (task == null) return;

    final updatedTask = task.copyWith(
      title: _titleCtrl.text.isEmpty ? 'Untitled task' : _titleCtrl.text,
      notes: Value(_notesCtrl.text.isEmpty ? null : _notesCtrl.text),
      status: _status,
      priority: _priority,
      dueDate: Value(_dueDate),
      scheduledDate: Value(_scheduledDate),
      modifiedAt: DateTime.now(),
    );
    await ref.read(taskRepositoryProvider).updateTask(updatedTask);

    final updatedPin = widget.pin.copyWith(
      content: Value(_titleCtrl.text),
      modifiedAt: DateTime.now(),
    );
    await ref.read(pinRepositoryProvider).updatePin(updatedPin);

    widget.onTaskSaved();
    widget.onPinSaved();
  }

  void _setStatus(String status) {
    setState(() => _status = status);
    _scheduleTaskSave();
  }

  void _setPriority(int p) {
    setState(() => _priority = p);
    _scheduleTaskSave();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
      _scheduleTaskSave();
    }
  }

  Future<void> _pickScheduledDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
      _scheduleTaskSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.task == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No task linked to this pin.',
          style: TextStyle(color: EpicordiaColors.textSecondaryLight),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status ring
          Center(child: _StatusRing(status: _status, onChanged: _setStatus)),
          const SizedBox(height: 20),

          // Title
          const _SectionLabel('TITLE'),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: EpicordiaColors.textPrimaryLight,
            ),
            decoration: _inputDeco('What needs to be done?'),
          ),
          const SizedBox(height: 16),

          // Notes
          const _SectionLabel('NOTES'),
          const SizedBox(height: 6),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            style: const TextStyle(
              fontSize: 14,
              color: EpicordiaColors.textPrimaryLight,
              height: 1.5,
            ),
            decoration: _inputDeco('Additional details\u2026'),
          ),
          const SizedBox(height: 16),

          // Priority
          const _SectionLabel('PRIORITY'),
          const SizedBox(height: 8),
          _PriorityChips(priority: _priority, onChanged: _setPriority),
          const SizedBox(height: 16),

          // Due date
          _DateRow(
            label: 'DUE DATE',
            date: _dueDate,
            onTap: _pickDueDate,
            onClear: () {
              setState(() => _dueDate = null);
              _scheduleTaskSave();
            },
          ),
          const SizedBox(height: 10),

          // Scheduled date
          _DateRow(
            label: 'SCHEDULED',
            date: _scheduledDate,
            onTap: _pickScheduledDate,
            onClear: () {
              setState(() => _scheduledDate = null);
              _scheduleTaskSave();
            },
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDeco(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
        color: EpicordiaColors.textTertiaryLight, fontSize: 14),
    filled: true,
    fillColor: EpicordiaColors.surfaceSunkenLight,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
          const BorderSide(color: EpicordiaColors.borderSubtleLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
          const BorderSide(color: EpicordiaColors.borderSubtleLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
          const BorderSide(color: EpicordiaColors.blue600, width: 1.5),
    ),
  );
}

// ---- Status Ring ----

class _StatusRing extends StatelessWidget {
  const _StatusRing({required this.status, required this.onChanged});

  final String status;
  final ValueChanged<String> onChanged;

  static const List<(String, String, Color)> _segments = [
    ('todo', 'To Do', Color(0xFFB9BCC2)),
    ('in_progress', 'In Progress', Color(0xFF5FA8F5)),
    ('done', 'Done', Color(0xFF5FC7A3)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _segments.map((seg) {
        final (value, label, color) = seg;
        final isActive = status == value;
        return GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 52 : 40,
                  height: isActive ? 52 : 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? color.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: color,
                      width: isActive ? 3 : 2,
                    ),
                  ),
                  child: isActive
                      ? Icon(
                          value == 'done'
                              ? Icons.check
                              : value == 'in_progress'
                                  ? Icons.sync
                                  : Icons.radio_button_unchecked,
                          color: color,
                          size: 22,
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive
                        ? color
                        : EpicordiaColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---- Priority Chips ----

class _PriorityChips extends StatelessWidget {
  const _PriorityChips({required this.priority, required this.onChanged});

  final int priority;
  final ValueChanged<int> onChanged;

  static const List<(int, String, Color)> _chips = [
    (0, 'Low', Color(0xFF5FC7A3)),
    (1, 'Medium', Color(0xFFF4C453)),
    (2, 'High', Color(0xFFF0806B)),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _chips.map((chip) {
        final (value, label, color) = chip;
        final active = priority == value;
        return GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: active
                  ? color.withValues(alpha: 0.18)
                  : EpicordiaColors.surfaceSunkenLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? color
                    : EpicordiaColors.borderSubtleLight,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    active ? FontWeight.w700 : FontWeight.w400,
                color: active
                    ? color
                    : EpicordiaColors.textSecondaryLight,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---- Date Row ----

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  String _format(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SectionLabel(label),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: date != null
                  ? EpicordiaColors.blue50
                  : EpicordiaColors.surfaceSunkenLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: date != null
                    ? EpicordiaColors.blue200
                    : EpicordiaColors.borderSubtleLight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: date != null
                      ? EpicordiaColors.blue600
                      : EpicordiaColors.textTertiaryLight,
                ),
                const SizedBox(width: 6),
                Text(
                  date != null ? _format(date!) : 'Set date',
                  style: TextStyle(
                    fontSize: 13,
                    color: date != null
                        ? EpicordiaColors.blue600
                        : EpicordiaColors.textTertiaryLight,
                    fontWeight: date != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (date != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              Icons.close,
              size: 16,
              color: EpicordiaColors.textTertiaryLight,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// CHECKLIST EDITOR
// ---------------------------------------------------------------------------

class _ChecklistItem {
  String id;
  String text;
  bool done;

  _ChecklistItem({required this.id, required this.text, required this.done});

  factory _ChecklistItem.fromMap(Map<String, dynamic> m) => _ChecklistItem(
        id: m['id'] as String? ?? UniqueKey().toString(),
        text: m['text'] as String? ?? '',
        done: m['done'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'done': done};
}

class _ChecklistEditor extends ConsumerStatefulWidget {
  const _ChecklistEditor({required this.pin, required this.onSaved});

  final PinEntity pin;
  final VoidCallback onSaved;

  @override
  ConsumerState<_ChecklistEditor> createState() => _ChecklistEditorState();
}

class _ChecklistEditorState extends ConsumerState<_ChecklistEditor> {
  late List<_ChecklistItem> _items;

  @override
  void initState() {
    super.initState();
    _items = _parseItems(widget.pin.content);
  }

  static List<_ChecklistItem> _parseItems(String? content) {
    if (content == null || content.isEmpty) return [];
    try {
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      final list = decoded['items'] as List<dynamic>;
      return list
          .map((e) => _ChecklistItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save() async {
    final json =
        jsonEncode({'items': _items.map((e) => e.toMap()).toList()});
    final updated = widget.pin.copyWith(
      content: Value(json),
      modifiedAt: DateTime.now(),
    );
    await ref.read(pinRepositoryProvider).updatePin(updated);
    widget.onSaved();
  }

  void _addItem() {
    setState(() {
      _items.add(_ChecklistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '',
        done: false,
      ));
    });
    _save();
  }

  void _toggleDone(int index, bool value) {
    setState(() => _items[index].done = value);
    _save();
  }

  void _updateText(int index, String value) {
    _items[index].text = value;
    _save();
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _items.length,
            itemBuilder: (ctx, i) => _ChecklistRow(
              item: _items[i],
              onToggle: (v) => _toggleDone(i, v),
              onChanged: (v) => _updateText(i, v),
              onDelete: () => _removeItem(i),
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GestureDetector(
            onTap: _addItem,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: EpicordiaColors.blue300, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.add,
                      size: 16, color: EpicordiaColors.blue600),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add item',
                  style: TextStyle(
                    fontSize: 14,
                    color: EpicordiaColors.blue600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChecklistRow extends StatefulWidget {
  const _ChecklistRow({
    required this.item,
    required this.onToggle,
    required this.onChanged,
    required this.onDelete,
  });

  final _ChecklistItem item;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;

  @override
  State<_ChecklistRow> createState() => _ChecklistRowState();
}

class _ChecklistRowState extends State<_ChecklistRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item.text);
    _ctrl.addListener(() => widget.onChanged(_ctrl.text));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Plain square checkbox
          GestureDetector(
            onTap: () => widget.onToggle(!widget.item.done),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: widget.item.done
                    ? EpicordiaColors.blue600
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.item.done
                      ? EpicordiaColors.blue600
                      : EpicordiaColors.borderStrongLight,
                  width: 1.5,
                ),
              ),
              child: widget.item.done
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: TextStyle(
                fontSize: 14,
                color: widget.item.done
                    ? EpicordiaColors.textTertiaryLight
                    : EpicordiaColors.textPrimaryLight,
                decoration: widget.item.done
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
              decoration: const InputDecoration(
                hintText: 'Item text\u2026',
                hintStyle: TextStyle(
                    color: EpicordiaColors.textTertiaryLight,
                    fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onDelete,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.remove_circle_outline,
                  size: 18, color: EpicordiaColors.textTertiaryLight),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PLACEHOLDER for unsupported pin types
// ---------------------------------------------------------------------------

class _PlaceholderEditor extends StatelessWidget {
  const _PlaceholderEditor({required this.pinType});

  final String pinType;

  static const Map<String, IconData> _icons = {
    'image': Icons.image_outlined,
    'link': Icons.link_outlined,
    'drawing': Icons.draw_outlined,
    'audio': Icons.mic_none_outlined,
    'heading': Icons.title,
    'table': Icons.table_chart_outlined,
    'frame': Icons.crop_square_outlined,
    'board': Icons.dashboard_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[pinType] ?? Icons.push_pin_outlined;
    final displayType =
        '${pinType[0].toUpperCase()}${pinType.substring(1)}';
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: EpicordiaColors.textTertiaryLight),
          const SizedBox(height: 12),
          Text(
            'Edit $displayType pin',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: EpicordiaColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Full editor coming soon.',
            style: TextStyle(
                fontSize: 13, color: EpicordiaColors.textTertiaryLight),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BOTTOM ACTION BAR
// ---------------------------------------------------------------------------

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.currentTag,
    required this.onTagSelected,
    required this.onDelete,
  });

  final String? currentTag;
  final ValueChanged<String?> onTagSelected;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            top: BorderSide(color: EpicordiaColors.borderSubtleLight)),
      ),
      child: Row(
        children: [
          // Colour tag dots
          ..._kTagColors.entries.map((entry) {
            final isActive = currentTag == entry.key;
            return GestureDetector(
              onTap: () =>
                  onTagSelected(isActive ? null : entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: isActive ? 26 : 22,
                height: isActive ? 26 : 22,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: entry.value,
                  border: Border.all(
                    color: isActive
                        ? EpicordiaColors.textPrimaryLight
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: isActive
                    ? const Icon(Icons.check,
                        size: 12, color: Colors.white)
                    : null,
              ),
            );
          }),
          const Spacer(),
          // Delete button
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: EpicordiaColors.errorLight
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: EpicordiaColors.errorLight
                      .withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline,
                      size: 17, color: EpicordiaColors.errorLight),
                  SizedBox(width: 5),
                  Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: EpicordiaColors.errorLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helper widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        color: EpicordiaColors.textTertiaryLight,
      ),
    );
  }
}
