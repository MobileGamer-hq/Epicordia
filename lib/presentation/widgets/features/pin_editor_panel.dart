import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:epicordia/core/theme.dart';
import 'package:epicordia/data/database/database.dart';
import 'package:epicordia/data/providers.dart';
import 'package:epicordia/data/repository/pin_repository.dart';
import 'package:epicordia/data/repository/task_repository.dart';
import 'drawing_canvas.dart';

// ---------------------------------------------------------------------------
// Color-tag palette (shared with BoardPinCard)
// ---------------------------------------------------------------------------

const Map<String, Color> _kTagColors = {
  'yellow': Color(0xFFF4C453),
  'orange': Color(0xFFF2994A),
  'coral': Color(0xFFF0806B),
  'purple': Color(0xFFBB6BD9),
  'blue': Color(0xFF2F80ED),
  'green': Color(0xFF27AE60),
};

Color? colorFromTag(String? tag) {
  if (tag == null) return null;
  return _kTagColors[tag.toLowerCase()];
}

// ---------------------------------------------------------------------------
// Entry-point helper
// ---------------------------------------------------------------------------

/// Opens [PinEditorPanel] as a centered modal popup.
void showPinEditorPanel(
  BuildContext context, {
  required String pinId,
  required String boardId,
}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) {
      final screenSize = MediaQuery.of(dialogContext).size;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Material(
            elevation: 20,
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(dialogContext).colorScheme.surface,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: math.min(580, screenSize.width * 0.9),
                maxHeight: math.min(760, screenSize.height * 0.85),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: PinEditorPanel(
                  pinId: pinId,
                  boardId: boardId,
                  onClose: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ),
          ),
        ),
      );
    },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final errorClr = isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete pin?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        content: Text(
          'This action cannot be undone. The pin will be permanently removed from the board.',
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: errorClr, fontWeight: FontWeight.w700),
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
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final handleClr = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;

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
                color: handleClr,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          if (!_loading && _pin != null) _PanelHeader(pin: _pin!, onClose: widget.onClose),
          // Body
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: CircularProgressIndicator(
                color: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600,
                strokeWidth: 2,
              ),
            )
          else if (_pin == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Text(
                'Pin not found.',
                style: TextStyle(color: textSecondary),
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
      'tasklist' => _TaskListEditor(pin: pin, onSaved: _refreshPin),
      'checklist' => _ChecklistEditor(pin: pin, onSaved: _refreshPin),
      'image' => _ImageEditor(pin: pin, onSaved: _refreshPin),
      'drawing' || 'handwriting' => _DrawingEditor(pin: pin, onSaved: _refreshPin),
      'frame' => _FrameEditor(pin: pin, onSaved: _refreshPin),
      'heading' => _HeadingEditor(pin: pin, onSaved: _refreshPin),
      'colorSwatch' => _ColorSwatchEditor(pin: pin, onSaved: _refreshPin),
      'link' => _LinkEditor(pin: pin, onSaved: _refreshPin),
      'file' => _FileEditor(pin: pin, onSaved: _refreshPin),
      'audio' => _AudioEditor(pin: pin, onSaved: _refreshPin),
      'table' => _TableEditor(pin: pin, onSaved: _refreshPin),
      'board' => _BoardTileEditor(pin: pin, onSaved: _refreshPin),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconClr = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final sunkenBg = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;

    final icon = _typeIcons[pin.type] ?? Icons.push_pin_outlined;
    final indicatorColor = colorFromTag(pin.colorTag);

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
          Icon(icon, size: 16, color: iconClr),
          const SizedBox(width: 8),
          Text(
            pin.type.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: textSecondary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: sunkenBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close,
                size: 18,
                color: textSecondary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

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
              style: TextStyle(
                fontSize: 15,
                color: textPrimary,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText: 'Start writing\u2026',
                hintStyle: TextStyle(color: textTertiary),
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
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: borderSubtle)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconClr = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(icon, size: 20, color: iconClr),
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
    final titleText = _titleCtrl.text.isEmpty ? 'Untitled task' : _titleCtrl.text;
    final task = widget.task;

    if (task == null) {
      final taskId = '${widget.pin.id}_task';
      final newTask = TasksCompanion.insert(
        id: taskId,
        pinId: Value(widget.pin.id),
        boardId: Value(widget.pin.boardId),
        title: titleText,
        notes: Value(_notesCtrl.text.isEmpty ? null : _notesCtrl.text),
        status: Value(_status),
        priority: Value(_priority),
        dueDate: Value(_dueDate),
        scheduledDate: Value(_scheduledDate),
      );
      await ref.read(taskRepositoryProvider).createTask(newTask);
    } else {
      final updatedTask = task.copyWith(
        title: titleText,
        notes: Value(_notesCtrl.text.isEmpty ? null : _notesCtrl.text),
        status: _status,
        priority: _priority,
        dueDate: Value(_dueDate),
        scheduledDate: Value(_scheduledDate),
        modifiedAt: DateTime.now(),
      );
      await ref.read(taskRepositoryProvider).updateTask(updatedTask);
    }

    final updatedPin = widget.pin.copyWith(
      content: Value(titleText),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;

    if (widget.task == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No task linked to this pin.',
          style: TextStyle(color: textSecondary),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            decoration: _inputDeco('What needs to be done?', context),
          ),
          const SizedBox(height: 16),

          // Notes
          const _SectionLabel('NOTES'),
          const SizedBox(height: 6),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            style: TextStyle(
              fontSize: 14,
              color: textPrimary,
              height: 1.5,
            ),
            decoration: _inputDeco('Additional details\u2026', context),
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

InputDecoration _inputDeco(String hint, [BuildContext? context]) {
  final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      color: isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight,
      fontSize: 14,
    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

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
                        : textTertiary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;
    final unselectedBorder = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

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
                  : unselectedBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? color
                    : unselectedBorder,
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
                    : textSecondary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? EpicordiaColors.blue900 : EpicordiaColors.blue50;
    final unselectedBg = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;
    final activeBorder = isDark ? EpicordiaColors.blue700 : EpicordiaColors.blue200;
    final unselectedBorder = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

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
                  ? activeBg
                  : unselectedBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: date != null
                    ? activeBorder
                    : unselectedBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: date != null
                      ? activeBlue
                      : textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  date != null ? _format(date!) : 'Set date',
                  style: TextStyle(
                    fontSize: 13,
                    color: date != null
                        ? activeBlue
                        : textTertiary,
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
            child: Icon(
              Icons.close,
              size: 16,
              color: textTertiary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

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
                        color: activeBlue, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.add,
                      size: 16, color: activeBlue),
                ),
                const SizedBox(width: 12),
                Text(
                  'Add item',
                  style: TextStyle(
                    fontSize: 14,
                    color: activeBlue,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

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
                    ? activeBlue
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.item.done
                      ? activeBlue
                      : borderStrong,
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
                    ? textTertiary
                    : textPrimary,
                decoration: widget.item.done
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
              decoration: InputDecoration(
                hintText: 'Item text\u2026',
                hintStyle: TextStyle(
                    color: textTertiary,
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
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.remove_circle_outline,
                  size: 18, color: textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// IMAGE EDITOR
// ---------------------------------------------------------------------------

class _ImageEditor extends ConsumerStatefulWidget {
  const _ImageEditor({required this.pin, required this.onSaved});
  final PinEntity pin;
  final VoidCallback onSaved;

  @override
  ConsumerState<_ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends ConsumerState<_ImageEditor> {
  late final TextEditingController _captionCtrl;
  String? _filePath;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final data = _parseData(widget.pin.content);
    _filePath = data['filePath'] as String?;
    _captionCtrl = TextEditingController(text: data['caption'] as String? ?? '');
    _captionCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _captionCtrl.removeListener(_onChanged);
    _captionCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _parseData(String? content) {
    if (content == null || content.isEmpty) return {};
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _save() async {
    final json = jsonEncode({
      'filePath': _filePath ?? '',
      'caption': _captionCtrl.text,
    });
    final updated = widget.pin.copyWith(
      content: Value(json),
      modifiedAt: DateTime.now(),
    );
    await ref.read(pinRepositoryProvider).updatePin(updated);
    widget.onSaved();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      String? path;
      final res = await FilePicker.platform.pickFiles(type: FileType.image);
      if (res != null && res.files.single.path != null) {
        path = res.files.single.path;
      } else if (res == null) {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: source);
        if (picked != null) {
          path = picked.path;
        }
      }

      if (path != null && mounted) {
        setState(() => _filePath = path);
        _save();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final sunkenBg = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;

    final hasFile = _filePath != null && _filePath!.isNotEmpty && File(_filePath!).existsSync();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('IMAGE SOURCE'),
          const SizedBox(height: 8),
          if (hasFile)
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderSubtle),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_filePath!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: sunkenBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderSubtle),
              ),
              child: Center(
                child: Icon(Icons.image_outlined, size: 48, color: textTertiary),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('From Device Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EpicordiaColors.blue600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: BorderSide(color: borderStrong),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('CAPTION'),
          const SizedBox(height: 6),
          TextField(
            controller: _captionCtrl,
            decoration: _inputDeco('Optional image caption…', context),
            style: TextStyle(fontSize: 14, color: textPrimary),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DRAWING EDITOR
// ---------------------------------------------------------------------------

class _DrawingEditor extends ConsumerWidget {
  const _DrawingEditor({required this.pin, required this.onSaved});
  final PinEntity pin;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DrawingEditorCanvas(
      initialContent: pin.content,
      onChanged: (jsonContent) async {
        final updated = pin.copyWith(
          content: Value(jsonContent),
          modifiedAt: DateTime.now(),
        );
        await ref.read(pinRepositoryProvider).updatePin(updated);
        onSaved();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// HEADING EDITOR
// ---------------------------------------------------------------------------

class _HeadingEditor extends ConsumerStatefulWidget {
  const _HeadingEditor({required this.pin, required this.onSaved});
  final PinEntity pin;
  final VoidCallback onSaved;

  @override
  ConsumerState<_HeadingEditor> createState() => _HeadingEditorState();
}

class _HeadingEditorState extends ConsumerState<_HeadingEditor> {
  late final TextEditingController _ctrl;
  String _style = 'heading';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final data = _parseData(widget.pin.content);
    _style = data['style'] as String? ?? 'heading';
    _ctrl = TextEditingController(text: data['text'] as String? ?? widget.pin.content ?? '');
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _parseData(String? content) {
    if (content == null || content.isEmpty) return {};
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {'text': content};
    }
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _save);
  }

  Future<void> _save() async {
    final json = jsonEncode({'text': _ctrl.text, 'style': _style});
    final updated = widget.pin.copyWith(
      content: Value(json),
      modifiedAt: DateTime.now(),
    );
    await ref.read(pinRepositoryProvider).updatePin(updated);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('STYLE'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'heading', label: Text('Heading Text'), icon: Icon(Icons.title)),
              ButtonSegment(value: 'divider', label: Text('Divider Line'), icon: Icon(Icons.horizontal_rule)),
            ],
            selected: {_style},
            onSelectionChanged: (set) {
              setState(() => _style = set.first);
              _save();
            },
          ),
          if (_style == 'heading') ...[
            const SizedBox(height: 20),
            const _SectionLabel('HEADING TEXT'),
            const SizedBox(height: 6),
            TextField(
              controller: _ctrl,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
              decoration: _inputDeco('Enter section heading…', context),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// COLOR SWATCH EDITOR
// ---------------------------------------------------------------------------

class _ColorSwatchEditor extends ConsumerStatefulWidget {
  const _ColorSwatchEditor({required this.pin, required this.onSaved});
  final PinEntity pin;
  final VoidCallback onSaved;

  @override
  ConsumerState<_ColorSwatchEditor> createState() => _ColorSwatchEditorState();
}

class _ColorSwatchEditorState extends ConsumerState<_ColorSwatchEditor> {
  late String _hex;
  late String _label;
  late final TextEditingController _hexCtrl;
  late final TextEditingController _labelCtrl;
  Timer? _debounce;

  static const List<String> _swatchPalette = [
    '#3D68EE', '#F4C453', '#F0806B', '#5FC7A3', '#9C8CF0', '#5FA8F5',
    '#16181C', '#8E8E93', '#E5A030', '#D9534F', '#2E7D32', '#9C27B0',
    '#E91E63', '#00BCD4', '#009688', '#FF9800', '#795548', '#FFFFFF',
  ];

  @override
  void initState() {
    super.initState();
    final data = _parseData(widget.pin.content);
    _hex = data['hex'] ?? '#3D68EE';
    _label = data['label'] ?? '';
    _hexCtrl = TextEditingController(text: _hex);
    _labelCtrl = TextEditingController(text: _label);

    _hexCtrl.addListener(_onHexChanged);
    _labelCtrl.addListener(_onLabelChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _hexCtrl.removeListener(_onHexChanged);
    _labelCtrl.removeListener(_onLabelChanged);
    _hexCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  Map<String, String> _parseData(String? content) {
    if (content == null || content.isEmpty) return {'hex': '#3D68EE', 'label': ''};
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      final hex = map['hex'] as String? ?? map['color'] as String? ?? '#3D68EE';
      final label = map['label'] as String? ?? '';
      return {'hex': hex, 'label': label};
    } catch (_) {
      return {'hex': content.startsWith('#') ? content : '#3D68EE', 'label': ''};
    }
  }

  void _onHexChanged() {
    final text = _hexCtrl.text.trim();
    if (text.isNotEmpty && (text.length == 7 || text.length == 6)) {
      final formatted = text.startsWith('#') ? text : '#$text';
      if (_isValidHex(formatted)) {
        setState(() => _hex = formatted);
        _scheduleSave();
      }
    }
  }

  void _onLabelChanged() {
    setState(() => _label = _labelCtrl.text);
    _scheduleSave();
  }

  bool _isValidHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    return clean.length == 6 && int.tryParse(clean, radix: 16) != null;
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _save);
  }

  Future<void> _save() async {
    final json = jsonEncode({
      'hex': _hex,
      'label': _label,
    });
    final updated = widget.pin.copyWith(
      content: Value(json),
      colorTag: Value(_hex),
      modifiedAt: DateTime.now(),
    );
    await ref.read(pinRepositoryProvider).updatePin(updated);
    widget.onSaved();
  }

  void _selectPaletteColor(String hex) {
    setState(() {
      _hex = hex;
      _hexCtrl.text = hex;
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    final color = _hexToColor(_hex);
    final isLightColor = color.computeLuminance() > 0.5;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('COLOR PREVIEW'),
          const SizedBox(height: 8),
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderSubtle),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _hex.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isLightColor ? Colors.black87 : Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                if (_label.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: (isLightColor ? Colors.black54 : Colors.white70),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('HEX COLOR CODE'),
          const SizedBox(height: 6),
          TextField(
            controller: _hexCtrl,
            decoration: _inputDeco('e.g. #3D68EE', context).copyWith(
              prefixIcon: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderSubtle),
                  ),
                ),
              ),
            ),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('COLOR NAME / LABEL'),
          const SizedBox(height: 6),
          TextField(
            controller: _labelCtrl,
            decoration: _inputDeco('e.g. Primary Accent Blue', context),
            style: TextStyle(fontSize: 14, color: textPrimary),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('QUICK PALETTE'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _swatchPalette.map((h) {
              final isSelected = _hex.toUpperCase() == h.toUpperCase();
              final c = _hexToColor(h);
              return GestureDetector(
                onTap: () => _selectPaletteColor(h),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? activeBlue : borderStrong,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black87 : Colors.white, size: 20) : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    return Colors.blue;
  }
}

// ---------------------------------------------------------------------------
// TASK LIST EDITOR
// ---------------------------------------------------------------------------

class _TaskListEditor extends ConsumerStatefulWidget {
  const _TaskListEditor({required this.pin, required this.onSaved});
  final PinEntity pin;
  final VoidCallback onSaved;

  @override
  ConsumerState<_TaskListEditor> createState() => _TaskListEditorState();
}

class _TaskListEditorState extends ConsumerState<_TaskListEditor> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _newItemCtrl;

  @override
  void initState() {
    super.initState();
    final title = _parseTitle(widget.pin.content);
    _titleCtrl = TextEditingController(text: title);
    _newItemCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _newItemCtrl.dispose();
    super.dispose();
  }

  String _parseTitle(String? content) {
    if (content == null || content.isEmpty) return '';
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      return map['title'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _saveTitle() async {
    final json = jsonEncode({'title': _titleCtrl.text});
    final updated = widget.pin.copyWith(
      content: Value(json),
      modifiedAt: DateTime.now(),
    );
    await ref.read(pinRepositoryProvider).updatePin(updated);
    widget.onSaved();
  }

  Future<void> _addSubTask() async {
    final text = _newItemCtrl.text.trim();
    if (text.isEmpty) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final taskRepo = ref.read(taskRepositoryProvider);
    await taskRepo.createTask(
      TasksCompanion.insert(
        id: id,
        groupPinId: Value(widget.pin.id),
        boardId: Value(widget.pin.boardId),
        title: text,
        status: const Value('todo'),
      ),
    );

    _newItemCtrl.clear();
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final activeBlue = isDark ? EpicordiaColors.blue600 : EpicordiaColors.blue600;

    final tasksStream = ref.watch(tasksForGroupPinProvider(widget.pin.id));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('LIST TITLE'),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            onChanged: (_) => _saveTitle(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
            decoration: _inputDeco('e.g. Packing list, Sprint tasks…', context),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('SUB-TASKS'),
          const SizedBox(height: 6),
          Expanded(
            child: tasksStream.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading tasks: $err'),
              data: (tasks) {
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (ctx, i) {
                    final t = tasks[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              final next = t.status == 'done' ? 'todo' : 'done';
                              ref.read(taskRepositoryProvider).updateTask(t.copyWith(status: next));
                            },
                            child: _MiniStatusRing(isDone: t.status == 'done'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t.title,
                              style: TextStyle(
                                fontSize: 14,
                                color: t.status == 'done' ? textTertiary : textPrimary,
                                decoration: t.status == 'done' ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 18, color: textTertiary),
                            onPressed: () {
                              ref.read(taskRepositoryProvider).deleteTask(t.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newItemCtrl,
                  onSubmitted: (_) => _addSubTask(),
                  decoration: _inputDeco('Add a new task…', context),
                  style: TextStyle(fontSize: 14, color: textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addSubTask,
                icon: const Icon(Icons.add, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: activeBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FRAME EDITOR
// ---------------------------------------------------------------------------

class _FrameEditor extends ConsumerStatefulWidget {
  const _FrameEditor({required this.pin, required this.onSaved});
  final PinEntity pin;
  final VoidCallback onSaved;

  @override
  ConsumerState<_FrameEditor> createState() => _FrameEditorState();
}

class _FrameEditorState extends ConsumerState<_FrameEditor> {
  late final TextEditingController _titleCtrl;
  bool _isCollapsed = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final data = _parseData(widget.pin.content);
    _titleCtrl = TextEditingController(text: data['label'] as String? ?? '');
    _isCollapsed = data['collapsed'] as bool? ?? false;
    _titleCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleCtrl.removeListener(_onChanged);
    _titleCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _parseData(String? content) {
    if (content == null || content.isEmpty) return {};
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {'label': content};
    }
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _save);
  }

  Future<void> _save() async {
    final data = {
      'label': _titleCtrl.text,
      'collapsed': _isCollapsed,
    };
    final json = jsonEncode(data);
    final updated = widget.pin.copyWith(
      content: Value(json),
      modifiedAt: DateTime.now(),
    );
    await ref.read(pinRepositoryProvider).updatePin(updated);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final sunkenBg = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final primaryColor = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('COLUMN TITLE'),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
            decoration: _inputDeco('e.g. To Do, In Progress, Ideas…', context),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sunkenBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderSubtle),
            ),
            child: Row(
              children: [
                Icon(Icons.unfold_less_rounded, size: 20, color: primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Collapse Column',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                ),
                Switch.adaptive(
                  value: _isCollapsed,
                  activeTrackColor: primaryColor,
                  onChanged: (val) {
                    setState(() => _isCollapsed = val);
                    _save();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('COLUMN LAYOUT HINT'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sunkenBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderSubtle),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Drag any card into this column to add it to the vertical stack. Moving this column header moves all stacked items together as one unit.',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LINK EDITOR
// ---------------------------------------------------------------------------

class _LinkEditor extends ConsumerStatefulWidget {
  const _LinkEditor({required this.pin, required this.onSaved});
  final PinEntity pin;
  final VoidCallback onSaved;

  @override
  ConsumerState<_LinkEditor> createState() => _LinkEditorState();
}

class _LinkEditorState extends ConsumerState<_LinkEditor> {
  late final TextEditingController _urlCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final data = _parseData(widget.pin.content);
    _urlCtrl = TextEditingController(text: data['url'] as String? ?? widget.pin.content ?? '');
    _titleCtrl = TextEditingController(text: data['cachedTitle'] as String? ?? '');
    _descCtrl = TextEditingController(text: data['cachedDescription'] as String? ?? '');

    _urlCtrl.addListener(_onChanged);
    _titleCtrl.addListener(_onChanged);
    _descCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _urlCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _parseData(String? content) {
    if (content == null || content.isEmpty) return {};
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {'url': content};
    }
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _save() async {
    final json = jsonEncode({
      'url': _urlCtrl.text,
      'cachedTitle': _titleCtrl.text.isEmpty ? _urlCtrl.text : _titleCtrl.text,
      'cachedDescription': _descCtrl.text,
    });
    final updated = widget.pin.copyWith(
      content: Value(json),
      modifiedAt: DateTime.now(),
    );
    await ref.read(pinRepositoryProvider).updatePin(updated);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('URL'),
          const SizedBox(height: 6),
          TextField(
            controller: _urlCtrl,
            decoration: _inputDeco('https://example.com', context),
            style: TextStyle(fontSize: 14, color: textPrimary),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('LINK TITLE'),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            decoration: _inputDeco('Page title…', context),
            style: TextStyle(fontSize: 14, color: textPrimary),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('DESCRIPTION'),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: _inputDeco('Brief summary or note…', context),
            style: TextStyle(fontSize: 14, color: textPrimary),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FILE EDITOR
// ---------------------------------------------------------------------------

class _FileEditor extends ConsumerStatefulWidget {
  const _FileEditor({required this.pin, required this.onSaved});
  final PinEntity pin;
  final VoidCallback onSaved;

  @override
  ConsumerState<_FileEditor> createState() => _FileEditorState();
}

class _FileEditorState extends ConsumerState<_FileEditor> {
  late final TextEditingController _nameCtrl;
  String? _filePath;
  int? _fileSize;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final data = _parseData(widget.pin.content);
    _filePath = data['filePath'] as String?;
    _fileSize = data['fileSize'] as int?;
    _nameCtrl = TextEditingController(text: data['displayName'] as String? ?? '');
    _nameCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _parseData(String? content) {
    if (content == null || content.isEmpty) return {};
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _save() async {
    final json = jsonEncode({
      'filePath': _filePath ?? '',
      'displayName': _nameCtrl.text,
      'fileSize': _fileSize ?? 0,
    });
    final updated = widget.pin.copyWith(
      content: Value(json),
      modifiedAt: DateTime.now(),
    );
    await ref.read(pinRepositoryProvider).updatePin(updated);
    widget.onSaved();
  }

  Future<void> _pickFile() async {
    try {
      final res = await FilePicker.platform.pickFiles();
      if (res != null && res.files.single.path != null) {
        final f = res.files.single;
        setState(() {
          _filePath = f.path;
          _fileSize = f.size;
          if (_nameCtrl.text.isEmpty) {
            _nameCtrl.text = f.name;
          }
        });
        _save();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final sunkenBg = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    final hasFile = _filePath != null && _filePath!.isNotEmpty;
    final fileName = _filePath != null ? _filePath!.split(Platform.pathSeparator).last : 'No file selected';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('ATTACHED FILE'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: sunkenBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderSubtle),
            ),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file_outlined, size: 28, color: activeBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                  ),
                ),
                OutlinedButton(
                  onPressed: _pickFile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: borderStrong),
                  ),
                  child: Text(hasFile ? 'Replace' : 'Choose'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('DISPLAY NAME'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            decoration: _inputDeco('File display label…', context),
            style: TextStyle(fontSize: 14, color: textPrimary),
          ),
        ],
      ),
    );
  }
}

class _TableEditor extends ConsumerStatefulWidget {
  const _TableEditor({required this.pin, required this.onSaved});
  final PinEntity pin;
  final VoidCallback onSaved;

  @override
  ConsumerState<_TableEditor> createState() => _TableEditorState();
}

class _TableEditorState extends ConsumerState<_TableEditor> {
  late List<String> _columns;
  late List<List<String>> _rows;

  @override
  void initState() {
    super.initState();
    final data = _parseTable(widget.pin.content);
    _columns = data['columns'] as List<String>? ?? ['Item', 'Quantity', 'Notes'];
    _rows = data['rows'] as List<List<String>>? ?? [
      ['Item 1', '1', 'Details'],
      ['Item 2', '2', 'Details'],
    ];
  }

  Map<String, dynamic> _parseTable(String? content) {
    if (content == null || content.isEmpty) return {};
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      return {
        'columns': (map['columns'] as List<dynamic>? ?? []).cast<String>(),
        'rows': (map['rows'] as List<dynamic>? ?? []).map((r) => (r as List<dynamic>).cast<String>()).toList(),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _save() async {
    final json = jsonEncode({
      'columns': _columns,
      'rows': _rows,
    });
    final updated = widget.pin.copyWith(
      content: Value(json),
      modifiedAt: DateTime.now(),
    );
    await ref.read(pinRepositoryProvider).updatePin(updated);
    widget.onSaved();
  }

  void _addColumn() {
    setState(() {
      _columns.add('Col ${_columns.length + 1}');
      for (final r in _rows) {
        r.add('');
      }
    });
    _save();
  }

  void _addRow() {
    setState(() {
      _rows.add(List.filled(_columns.length, ''));
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionLabel('TABLE GRID'),
              const Spacer(),
              TextButton.icon(
                onPressed: _addColumn,
                icon: Icon(Icons.add, size: 16, color: activeBlue),
                label: Text('Add Column', style: TextStyle(color: activeBlue)),
              ),
              TextButton.icon(
                onPressed: _addRow,
                icon: Icon(Icons.add, size: 16, color: activeBlue),
                label: Text('Add Row', style: TextStyle(color: activeBlue)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: _columns
                      .asMap()
                      .entries
                      .map((entry) => DataColumn(
                            label: SizedBox(
                              width: 90,
                              child: TextFormField(
                                initialValue: entry.value,
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                                onChanged: (val) {
                                  _columns[entry.key] = val;
                                  _save();
                                },
                              ),
                            ),
                          ))
                      .toList(),
                  rows: _rows
                      .asMap()
                      .entries
                      .map((rowEntry) => DataRow(
                            cells: rowEntry.value
                                .asMap()
                                .entries
                                .map((colEntry) => DataCell(
                                      SizedBox(
                                        width: 90,
                                        child: TextFormField(
                                          initialValue: colEntry.value,
                                          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                                          style: TextStyle(fontSize: 12, color: textPrimary),
                                          onChanged: (val) {
                                            _rows[rowEntry.key][colEntry.key] = val;
                                            _save();
                                          },
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardTileEditor extends ConsumerStatefulWidget {
  const _BoardTileEditor({required this.pin, required this.onSaved});
  final PinEntity pin;
  final VoidCallback onSaved;

  @override
  ConsumerState<_BoardTileEditor> createState() => _BoardTileEditorState();
}

class _BoardTileEditorState extends ConsumerState<_BoardTileEditor> {
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
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _save);
  }

  Future<void> _save() async {
    final updated = widget.pin.copyWith(
      content: Value(_ctrl.text),
      modifiedAt: DateTime.now(),
    );
    await ref.read(pinRepositoryProvider).updatePin(updated);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('BOARD TILE NAME'),
          const SizedBox(height: 6),
          TextField(
            controller: _ctrl,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
            decoration: _inputDeco('Enter sub-board title…', context),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    final icon = _icons[pinType] ?? Icons.push_pin_outlined;
    final displayType =
        '${pinType[0].toUpperCase()}${pinType.substring(1)}';
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: textTertiary),
          const SizedBox(height: 12),
          Text(
            'Edit $displayType pin',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Full editor coming soon.',
            style: TextStyle(
                fontSize: 13, color: textTertiary),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final textPrimary = isDark ? Colors.white : EpicordiaColors.textPrimaryLight;
    final errorClr = isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: borderSubtle)),
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
                        ? textPrimary
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
                color: errorClr
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: errorClr
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline,
                      size: 17, color: errorClr),
                  const SizedBox(width: 5),
                  Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: errorClr,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        color: isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight,
      ),
    );
  }
}

class _MiniStatusRing extends StatelessWidget {
  final bool isDone;
  const _MiniStatusRing({required this.isDone});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final successClr = isDark ? EpicordiaColors.successDark : EpicordiaColors.successLight;
    final borderClr = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? successClr : Colors.transparent,
        border: Border.all(
          color: isDone ? successClr : borderClr,
          width: 1.5,
        ),
      ),
      child: isDone ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
    );
  }
}

// ---------------------------------------------------------------------------
// AUDIO EDITOR
// ---------------------------------------------------------------------------

class _AudioEditor extends ConsumerStatefulWidget {
  const _AudioEditor({required this.pin, required this.onSaved});
  final PinEntity pin;
  final VoidCallback onSaved;

  @override
  ConsumerState<_AudioEditor> createState() => _AudioEditorState();
}

class _AudioEditorState extends ConsumerState<_AudioEditor> {
  late final TextEditingController _titleCtrl;
  String? _filePath;
  int _durationSeconds = 42;
  bool _isRecording = false;
  Timer? _recordingTimer;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final data = _parseData(widget.pin.content);
    _titleCtrl = TextEditingController(text: data['title'] as String? ?? 'Voice Memo');
    _filePath = data['filePath'] as String?;
    _durationSeconds = (data['durationSeconds'] as num?)?.toInt() ?? 42;
    _titleCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _debounce?.cancel();
    _titleCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _parseData(String? content) {
    if (content == null || content.isEmpty) return {};
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _save() async {
    final json = jsonEncode({
      'title': _titleCtrl.text.isEmpty ? 'Voice Memo' : _titleCtrl.text,
      'durationSeconds': _durationSeconds,
      'filePath': _filePath ?? '',
    });
    final updated = widget.pin.copyWith(
      content: Value(json),
      modifiedAt: DateTime.now(),
    );
    await ref.read(pinRepositoryProvider).updatePin(updated);
    widget.onSaved();
  }

  void _toggleRecording() {
    if (_isRecording) {
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
      });
      _save();
    } else {
      setState(() {
        _isRecording = true;
        _durationSeconds = 0;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) {
          setState(() {
            _durationSeconds++;
          });
        }
      });
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (res != null && res.files.single.path != null) {
        final f = res.files.single;
        setState(() {
          _filePath = f.path;
          if (_titleCtrl.text == 'Voice Memo' || _titleCtrl.text.isEmpty) {
            _titleCtrl.text = f.name;
          }
        });
        _save();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick audio file: $e')),
        );
      }
    }
  }

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final sunkenBg = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;
    final errorClr = isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('AUDIO RECORDING / FILE'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sunkenBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isRecording ? errorClr : borderSubtle,
                width: _isRecording ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? errorClr : EpicordiaColors.blue600,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isRecording ? 'Recording in progress…' : 'Voice Memo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _isRecording ? errorClr : textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duration: ${_formatDuration(_durationSeconds)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: activeBlue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record, color: Colors.white, size: 18),
                  label: Text(_isRecording ? 'Stop Recording' : 'Record Voice Memo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? errorClr : EpicordiaColors.blue600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickAudioFile,
                icon: const Icon(Icons.audio_file_outlined, size: 18),
                label: const Text('Pick Audio File'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: BorderSide(color: borderStrong),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('MEMO TITLE'),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            decoration: _inputDeco('Voice memo title…', context),
            style: TextStyle(fontSize: 14, color: textPrimary),
          ),
        ],
      ),
    );
  }
}
