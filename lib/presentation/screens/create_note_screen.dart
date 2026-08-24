import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/database.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../domain/models/note_model.dart';
import '../../core/theme.dart';
import '../widgets/core/block_note_editor.dart';
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
  final GlobalKey<BlockNoteEditorStateController> _editorKey = GlobalKey();

  List<NoteBlock> _blocks = [NoteBlock(type: BlockType.paragraph, text: '')];
  NoteDrawingData _drawingData = const NoteDrawingData();
  bool _isPenModeActive = false;
  bool _isStylusOnlyMode = false;

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
    _titleController.addListener(_onTitleChanged);
    if (widget.noteId != null) {
      _loadExistingNote();
    }
  }

  void _onTitleChanged() {
    _triggerAutoSave();
  }

  void _onBlocksChanged(List<NoteBlock> blocks) {
    _blocks = blocks;
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

      if (loadedBlocks.isEmpty) {
        loadedBlocks = [NoteBlock(type: BlockType.paragraph, text: '')];
      }

      String? boardTitle;
      if (note.boardId != null) {
        final board = await ref.read(boardDaoProvider).getBoard(note.boardId!);
        boardTitle = board?.title;
      }

      setState(() {
        _existingNote = note;
        _titleController.text = title;
        _blocks = loadedBlocks;
        _drawingData = payload.drawing;
        _selectedTag = note.tags ?? 'Journal';
        _isLocked = note.isLocked;
        _entryDate = note.entryDate ?? note.createdAt;
        _selectedBoardId = note.boardId;
        _selectedBoardTitle = boardTitle;
        _saveStatus = 'Saved';
      });
    }
    _isLoadingNote = false;
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
    final title = _titleController.text.trim();
    if (title.isEmpty && _blocks.every((b) => b.text.trim().isEmpty) && _drawingData.isEmpty) return;

    final allBlocks = <NoteBlock>[];
    if (title.isNotEmpty) {
      allBlocks.add(NoteBlock(type: BlockType.heading, text: title));
    }
    allBlocks.addAll(_blocks);

    final payload = NoteDocumentPayload(
      blocks: allBlocks,
      drawing: _drawingData,
    );
    final contentJson = NoteDocument.encode(payload);

    if (_currentNoteId != null && _existingNote != null) {
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
      if (mounted) context.go('/notes');
    }
  }

  Future<void> _save() async {
    await _autoSave();
    if (mounted) context.go('/notes');
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
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;

    final editorState = _editorKey.currentState;

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
          title: Row(
            children: [
              Text(
                isEditing ? 'Edit Note' : 'New Note',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _saveStatus == 'Saving...'
                      ? activeBlue.withValues(alpha: 0.15)
                      : (isDark ? const Color(0xFF2B2E34) : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
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
                    const SizedBox(width: 6),
                    Text(
                      _saveStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _saveStatus == 'Saving...' ? activeBlue : textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isPenModeActive ? Icons.edit_note : Icons.gesture_outlined,
                color: _isPenModeActive ? activeBlue : textTertiary,
                size: 22,
              ),
              tooltip: _isPenModeActive ? 'Exit Pen Mode' : 'Pen / Stylus Drawing Mode',
              onPressed: () {
                setState(() {
                  _isPenModeActive = !_isPenModeActive;
                });
              },
            ),
            IconButton(
              icon: Icon(
                _isLocked ? Icons.lock : Icons.lock_open_outlined,
                color: _isLocked ? activeBlue : textTertiary,
                size: 20,
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
                icon: Icon(
                  Icons.delete_outline,
                  color: isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight,
                  size: 20,
                ),
                onPressed: _delete,
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _save,
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: activeBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: (_isPenModeActive && !_isStylusOnlyMode)
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Picker + Tag Chips Row
                      Row(
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
                      const SizedBox(height: 16),
                      // Title Input
                      TextField(
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
                      const SizedBox(height: 12),
                      Divider(color: borderClr.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      // Block Editor & Pen Overlay Drawing Layer Stack
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 550),
                        child: Stack(
                          children: [
                            BlockNoteEditor(
                              key: _editorKey,
                              initialBlocks: _blocks,
                              onChanged: _onBlocksChanged,
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
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              // Floating Bottom Toolbar: Pen Controls or Text Formatting Toolbar
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
                )
              else
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderClr, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Pen Mode Quick Switch Button
                        _ToolBtn(
                          icon: Icons.gesture,
                          label: 'Draw / Pen Mode',
                          isActive: false,
                          onTap: () => setState(() => _isPenModeActive = true),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          height: 20,
                          width: 1,
                          color: borderClr,
                        ),
                        // Block type controls
                        _ToolBtn(
                          icon: Icons.title,
                          label: 'Heading',
                          isActive: editorState?.isBlockTypeActive(BlockType.heading) ?? false,
                          onTap: () => _editorKey.currentState?.toggleBlockType(BlockType.heading),
                        ),
                        _ToolBtn(
                          icon: Icons.format_list_bulleted,
                          label: 'Bullet List',
                          isActive: editorState?.isBlockTypeActive(BlockType.bulletListItem) ?? false,
                          onTap: () => _editorKey.currentState?.toggleBlockType(BlockType.bulletListItem),
                        ),
                        _ToolBtn(
                          icon: Icons.format_list_numbered,
                          label: 'Numbered List',
                          isActive: editorState?.isBlockTypeActive(BlockType.numberedListItem) ?? false,
                          onTap: () => _editorKey.currentState?.toggleBlockType(BlockType.numberedListItem),
                        ),
                        _ToolBtn(
                          icon: Icons.check_box_outlined,
                          label: 'Checklist',
                          isActive: editorState?.isBlockTypeActive(BlockType.checklistItem) ?? false,
                          onTap: () => _editorKey.currentState?.toggleBlockType(BlockType.checklistItem),
                        ),
                        _ToolBtn(
                          icon: Icons.format_quote,
                          label: 'Quote',
                          isActive: editorState?.isBlockTypeActive(BlockType.quote) ?? false,
                          onTap: () => _editorKey.currentState?.toggleBlockType(BlockType.quote),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          height: 20,
                          width: 1,
                          color: borderClr,
                        ),
                        // Inline format controls
                        _ToolBtn(
                          icon: Icons.format_bold,
                          label: 'Bold',
                          isActive: editorState?.isMarkActive(MarkType.bold) ?? false,
                          onTap: () => _editorKey.currentState?.toggleMark(MarkType.bold),
                        ),
                        _ToolBtn(
                          icon: Icons.format_italic,
                          label: 'Italic',
                          isActive: editorState?.isMarkActive(MarkType.italic) ?? false,
                          onTap: () => _editorKey.currentState?.toggleMark(MarkType.italic),
                        ),
                        _ToolBtn(
                          icon: Icons.format_underline,
                          label: 'Underline',
                          isActive: editorState?.isMarkActive(MarkType.underline) ?? false,
                          onTap: () => _editorKey.currentState?.toggleMark(MarkType.underline),
                        ),
                        _ToolBtn(
                          icon: Icons.strikethrough_s,
                          label: 'Strikethrough',
                          isActive: editorState?.isMarkActive(MarkType.strikethrough) ?? false,
                          onTap: () => _editorKey.currentState?.toggleMark(MarkType.strikethrough),
                        ),
                        _ToolBtn(
                          icon: Icons.link,
                          label: 'Link',
                          isActive: editorState?.isMarkActive(MarkType.link) ?? false,
                          onTap: () => _editorKey.currentState?.insertLink(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;
    final inactiveColor = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final iconColor = isActive ? activeColor : inactiveColor;
    final bgColor = isActive ? activeColor.withValues(alpha: 0.15) : Colors.transparent;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        canRequestFocus: false,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: iconColor),
        ),
      ),
    );
  }
}