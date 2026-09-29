import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../data/database/database.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../domain/models/note_model.dart';
import '../../core/theme.dart';
import '../widgets/core/link_preview_dialog.dart';
import '../widgets/features/pen_drawing_overlay.dart';
import '../../data/providers.dart';

class CreateNoteScreen extends ConsumerStatefulWidget {
  final String? noteId;
  const CreateNoteScreen({super.key, this.noteId});

  @override
  ConsumerState<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends ConsumerState<CreateNoteScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _bodyFocusNode = FocusNode();

  NoteDrawingData _drawingData = const NoteDrawingData();
  bool _isPenModeActive = false;
  bool _isStylusOnlyMode = false;
  bool _isPreviewMode = false;

  PenTool _selectedPenTool = PenTool.pen;
  String _selectedPenColor = '#16181C';
  double _selectedPenWidth = 3.0;
  final List<List<PenStroke>> _penUndoStack = [];
  final List<List<PenStroke>> _penRedoStack = [];

  PinEntity? _existingNote;
  String? _currentNoteId;
  Timer? _debounceTimer;
  String _saveStatus = 'Saved';
  bool _isLoadingNote = false;

  DateTime _entryDate = DateTime.now();
  String _selectedTag = 'Journal';
  bool _isLocked = false;
  String? _selectedBoardId;
  String? _selectedBoardTitle;

  @override
  void initState() {
    super.initState();
    _currentNoteId = widget.noteId;
    if (widget.noteId != null) {
      _isLoadingNote = true;
      _loadExistingNote();
    } else {
      _titleController.addListener(_onTitleChanged);
      _bodyController.addListener(_onBodyChanged);
    }
  }

  void _onTitleChanged() {
    _triggerAutoSave();
  }

  void _onBodyChanged() {
    _triggerAutoSave();
  }

  void _onPenStrokesChanged(List<PenStroke> newStrokes) {
    _penUndoStack.add(List.from(_drawingData.strokes));
    if (_penUndoStack.length > 30) _penUndoStack.removeAt(0);
    _penRedoStack.clear();

    setState(() {
      _drawingData = NoteDrawingData(strokes: newStrokes);
    });
    _triggerAutoSave();
  }

  void _undoPenStroke() {
    if (_drawingData.strokes.isEmpty) return;
    setState(() {
      _penRedoStack.add(List.from(_drawingData.strokes));
      final prev = _penUndoStack.isNotEmpty ? _penUndoStack.removeLast() : <PenStroke>[];
      _drawingData = NoteDrawingData(strokes: prev);
    });
    _triggerAutoSave();
  }

  void _redoPenStroke() {
    if (_penRedoStack.isEmpty) return;
    setState(() {
      _penUndoStack.add(List.from(_drawingData.strokes));
      final next = _penRedoStack.removeLast();
      _drawingData = NoteDrawingData(strokes: next);
    });
    _triggerAutoSave();
  }

  void _clearPenStrokes() {
    if (_drawingData.strokes.isEmpty) return;
    setState(() {
      _penUndoStack.add(List.from(_drawingData.strokes));
      _penRedoStack.clear();
      _drawingData = const NoteDrawingData();
    });
    _triggerAutoSave();
  }

  void _triggerAutoSave() {
    if (_isLoadingNote) return;
    if (mounted && _saveStatus != 'Saving...') {
      setState(() {
        _saveStatus = 'Saving...';
      });
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _autoSave);
  }

  Future<void> _loadExistingNote() async {
    _isLoadingNote = true;
    final note = await ref.read(pinDaoProvider).getPin(_currentNoteId!);
    if (note != null && mounted) {
      final rawContent = note.content ?? '';
      final payload = NoteDocument.decode(rawContent);

      String title = '';
      List<NoteBlock> loadedBlocks = payload.blocks;

      if (loadedBlocks.isNotEmpty && loadedBlocks.first.type == BlockType.heading) {
        title = loadedBlocks.first.text;
        loadedBlocks = loadedBlocks.sublist(1);
      }

      final bodyText = NoteDocument.exportToMarkdown(loadedBlocks);

      String? boardTitle;
      if (note.boardId != null) {
        final board = await ref.read(boardDaoProvider).getBoard(note.boardId!);
        boardTitle = board?.title;
      }

      _titleController.removeListener(_onTitleChanged);
      _titleController.text = title;
      _titleController.addListener(_onTitleChanged);

      _bodyController.removeListener(_onBodyChanged);
      _bodyController.text = bodyText;
      _bodyController.addListener(_onBodyChanged);

      setState(() {
        _existingNote = note;
        _drawingData = payload.drawing;
        _selectedTag = note.tags ?? 'Journal';
        _isLocked = note.isLocked;
        _entryDate = note.entryDate ?? note.createdAt;
        _selectedBoardId = note.boardId;
        _selectedBoardTitle = boardTitle;
        _saveStatus = 'Saved';
        _isLoadingNote = false;
      });
    } else if (mounted) {
      _titleController.addListener(_onTitleChanged);
      _bodyController.addListener(_onBodyChanged);
      setState(() {
        _isLoadingNote = false;
      });
    }
  }

  void _showBoardPickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
        final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
        final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
        final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
        final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

        final boardsAsync = ref.watch(allBoardsProvider);
        final boards = boardsAsync.value ?? [];

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderClr, width: 1.5),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderClr,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.push_pin_rounded, color: activeBlue, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Pin Note to Board',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Select a board to pin this note for quick access on your workspace canvas.',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: _selectedBoardId == null ? activeBlue.withValues(alpha: 0.12) : null,
                leading: Icon(
                  Icons.inbox_rounded,
                  color: _selectedBoardId == null ? activeBlue : textSecondary,
                ),
                title: Text(
                  'Inbox (Unpinned)',
                  style: TextStyle(
                    fontWeight: _selectedBoardId == null ? FontWeight.bold : FontWeight.normal,
                    color: _selectedBoardId == null ? activeBlue : textPrimary,
                  ),
                ),
                trailing: _selectedBoardId == null
                    ? Icon(Icons.check_circle, color: activeBlue, size: 20)
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _selectedBoardId = null;
                    _selectedBoardTitle = null;
                    _saveStatus = 'Saving...';
                  });
                  _triggerAutoSave();
                },
              ),
              const Divider(height: 16),
              if (boards.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('No boards created yet.', style: TextStyle(color: textSecondary, fontSize: 13)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: boards.length,
                    itemBuilder: (context, index) {
                      final board = boards[index];
                      final isSelected = _selectedBoardId == board.id;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: isSelected ? activeBlue.withValues(alpha: 0.12) : null,
                        leading: Icon(
                          Icons.dashboard_customize_outlined,
                          color: isSelected ? activeBlue : textSecondary,
                        ),
                        title: Text(
                          board.title,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? activeBlue : textPrimary,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: activeBlue, size: 20)
                            : null,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          setState(() {
                            _selectedBoardId = board.id;
                            _selectedBoardTitle = board.title;
                            _saveStatus = 'Saving...';
                          });
                          _triggerAutoSave();
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _autoSave() async {
    if (_isLoadingNote) return;
    final title = _titleController.text.trim();
    final body = _bodyController.text;
    if (title.isEmpty && body.trim().isEmpty && _drawingData.isEmpty) return;

    final allBlocks = <NoteBlock>[];
    if (title.isNotEmpty) {
      allBlocks.add(NoteBlock(type: BlockType.heading, text: title));
    }
    if (body.isNotEmpty) {
      allBlocks.addAll(NoteDocument.parseLegacyMarkdown(body));
    }

    final payload = NoteDocumentPayload(
      blocks: allBlocks,
      drawing: _drawingData,
    );
    final contentJson = NoteDocument.encode(payload);

    if (_currentNoteId != null) {
      _existingNote ??= await ref.read(pinDaoProvider).getPin(_currentNoteId!);
      if (_existingNote != null) {
        final updatedPin = _existingNote!.copyWith(
          content: drift.Value(contentJson),
          tags: drift.Value(_selectedTag),
          isLocked: _isLocked,
          entryDate: drift.Value(_entryDate),
          boardId: drift.Value(_selectedBoardId),
          modifiedAt: DateTime.now(),
        );
        await ref.read(pinRepositoryProvider).updatePin(updatedPin);
        _existingNote = updatedPin;
      }
    } else {
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      _currentNoteId = newId;
      final companion = PinsCompanion.insert(
        id: newId,
        boardId: drift.Value(_selectedBoardId),
        type: 'note',
        content: drift.Value(contentJson),
        tags: drift.Value(_selectedTag),
        isLocked: drift.Value(_isLocked),
        entryDate: drift.Value(_entryDate),
      );
      await ref.read(pinRepositoryProvider).createPin(companion);
      _existingNote = await ref.read(pinDaoProvider).getPin(newId);
    }
    if (mounted) {
      setState(() {
        _saveStatus = 'Saved';
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: EpicordiaColors.errorLight),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (_currentNoteId != null) {
        await ref.read(pinRepositoryProvider).deletePin(_currentNoteId!);
      }
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/notes');
        }
      }
    }
  }

  Future<void> _save() async {
    await _autoSave();
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/notes');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.noteId != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        await _autoSave();
      },
      child: Scaffold(
        backgroundColor: bgApp,
        appBar: AppBar(
          backgroundColor: bgApp,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textPrimary),
            onPressed: () async {
              await _autoSave();
              if (context.mounted) {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/notes');
                }
              }
            },
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? 'Edit Note' : 'New Note',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _saveStatus == 'Saving...'
                          ? activeBlue
                          : (isDark ? EpicordiaColors.successDark : EpicordiaColors.successLight),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _saveStatus,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _saveStatus == 'Saving...' ? activeBlue : textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Preview Markdown Toggle Button
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                _isPreviewMode ? Icons.edit_outlined : Icons.visibility_outlined,
                color: _isPreviewMode ? activeBlue : textTertiary,
                size: 20,
              ),
              tooltip: _isPreviewMode ? 'Switch to Editor' : 'Preview Markdown',
              onPressed: () {
                setState(() {
                  _isPreviewMode = !_isPreviewMode;
                  if (_isPreviewMode) {
                    _isPenModeActive = false;
                  }
                });
              },
            ),
            // Pen Drawing Mode Toggle Button
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                _isPenModeActive ? Icons.edit_note : Icons.gesture_outlined,
                color: _isPenModeActive ? activeBlue : textTertiary,
                size: 20,
              ),
              tooltip: _isPenModeActive ? 'Exit Pen Mode' : 'Pen / Stylus Drawing Mode',
              onPressed: () {
                setState(() {
                  _isPenModeActive = !_isPenModeActive;
                  if (_isPenModeActive) {
                    _isPreviewMode = false;
                  }
                });
              },
            ),
            // Lock Note Button
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                _isLocked ? Icons.lock : Icons.lock_open_outlined,
                color: _isLocked ? activeBlue : textTertiary,
                size: 19,
              ),
              tooltip: _isLocked ? 'Note Locked' : 'Lock Note',
              onPressed: () {
                setState(() {
                  _isLocked = !_isLocked;
                  _saveStatus = 'Saving...';
                });
                _autoSave();
              },
            ),
            if (isEditing)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.delete_outline,
                  color: isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight,
                  size: 20,
                ),
                onPressed: _delete,
              ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TextButton(
                onPressed: _save,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: activeBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _isLoadingNote
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    // Date Picker + Board Picker + Tag Chips Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _entryDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  _entryDate = picked;
                                  _saveStatus = 'Saving...';
                                });
                                _autoSave();
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderClr),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 13, color: activeBlue),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_entryDate.year}-${_entryDate.month.toString().padLeft(2, '0')}-${_entryDate.day.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Board Pin Chip
                          InkWell(
                            onTap: _showBoardPickerModal,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _selectedBoardId != null
                                    ? activeBlue.withValues(alpha: 0.15)
                                    : (isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _selectedBoardId != null ? activeBlue : borderClr),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _selectedBoardId != null ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                    size: 13,
                                    color: activeBlue,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedBoardTitle ?? 'Pin to Board',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedBoardId != null ? activeBlue : textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ['Journal', 'Idea', 'Task', 'Personal', 'Work'].map((tag) {
                                  final selected = _selectedTag == tag;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(tag),
                                      selected: selected,
                                      visualDensity: VisualDensity.compact,
                                      selectedColor: activeBlue.withValues(alpha: 0.15),
                                      side: BorderSide(
                                        color: selected ? activeBlue : borderClr,
                                      ),
                                      labelStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                        color: selected ? activeBlue : textSecondary,
                                      ),
                                      onSelected: (_) {
                                        setState(() {
                                          _selectedTag = tag;
                                          _saveStatus = 'Saving...';
                                        });
                                        _autoSave();
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title Input or Preview
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _isPreviewMode
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _titleController.text.trim().isEmpty
                                    ? 'Untitled Note'
                                    : _titleController.text.trim(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            )
                          : TextField(
                              controller: _titleController,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.4,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Note title...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintStyle: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: textTertiary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(color: borderClr.withValues(alpha: 0.5), height: 1),
                    ),
                    // Body Editor & Pen Drawing Overlay
                    Expanded(
                      child: Stack(
                        children: [
                          if (_isPreviewMode)
                            Positioned.fill(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                child: _bodyController.text.trim().isEmpty
                                    ? Text(
                                        'Empty note',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontStyle: FontStyle.italic,
                                          color: textTertiary,
                                          height: 1.6,
                                        ),
                                      )
                                    : MarkdownBody(
                                        data: _bodyController.text,
                                        selectable: true,
                                        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                          p: TextStyle(fontSize: 16, height: 1.6, color: textPrimary),
                                          h1: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textPrimary),
                                          h2: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: textPrimary),
                                          h3: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
                                          listBullet: TextStyle(fontSize: 16, color: textPrimary),
                                          blockquote: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: textSecondary),
                                        ),
                                        onTapLink: (text, href, title) {
                                          if (href != null) {
                                            LinkPreviewDialog.show(context, text, href);
                                          }
                                        },
                                      ),
                              ),
                            )
                          else
                            Positioned.fill(
                              child: TextField(
                                controller: _bodyController,
                                focusNode: _bodyFocusNode,
                                autofocus: widget.noteId == null,
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textPrimary,
                                  height: 1.6,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Start writing...',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  hintStyle: TextStyle(
                                    fontSize: 16,
                                    color: textTertiary,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: PenDrawingOverlay(
                              strokes: _drawingData.strokes,
                              isPenActive: _isPenModeActive,
                              isStylusOnlyMode: _isStylusOnlyMode,
                              selectedTool: _selectedPenTool,
                              selectedColor: _selectedPenColor,
                              selectedWidth: _selectedPenWidth,
                              onChanged: _onPenStrokesChanged,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Floating Bottom Toolbar: Only when Pen Mode is Active!
                    if (_isPenModeActive)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: PenControlToolbar(
                          activeTool: _selectedPenTool,
                          activeColor: _selectedPenColor,
                          activeWidth: _selectedPenWidth,
                          isStylusOnlyMode: _isStylusOnlyMode,
                          canUndo: _drawingData.strokes.isNotEmpty,
                          canRedo: _penRedoStack.isNotEmpty,
                          onToolSelected: (tool) {
                            setState(() {
                              _selectedPenTool = tool;
                              if (tool == PenTool.highlighter && _selectedPenWidth < 12.0) {
                                _selectedPenWidth = 14.0;
                              } else if (tool == PenTool.pen && _selectedPenWidth > 10.0) {
                                _selectedPenWidth = 3.0;
                              }
                            });
                          },
                          onColorSelected: (color) {
                            setState(() {
                              _selectedPenColor = color;
                              if (_selectedPenTool == PenTool.eraser) {
                                _selectedPenTool = PenTool.pen;
                              }
                            });
                          },
                          onWidthSelected: (width) {
                            setState(() => _selectedPenWidth = width);
                          },
                          onStylusOnlyToggle: (val) {
                            setState(() => _isStylusOnlyMode = val);
                          },
                          onUndo: _undoPenStroke,
                          onRedo: _redoPenStroke,
                          onClear: _clearPenStrokes,
                          onClosePenMode: () {
                            setState(() => _isPenModeActive = false);
                          },
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}