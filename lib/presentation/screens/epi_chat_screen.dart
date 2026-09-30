import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/feedback_service.dart';
import '../../data/providers.dart';
import '../../data/database/database.dart';
import '../../data/repository/task_repository.dart';
import '../../domain/models/task_subitem.dart';
import '../../domain/models/note_model.dart';
import '../../core/utils/task_date_formatter.dart';
import '../widgets/core/custom_circular_checkbox.dart';
import '../widgets/core/item_interaction_dialogs.dart';
import '../../domain/epi/epi_chat_controller.dart';
import '../../domain/epi/epi_models.dart';
import 'package:remixicon/remixicon.dart';

class EpiChatScreen extends ConsumerStatefulWidget {
  final String? initialBoardContext;
  final String? initialPrompt;

  const EpiChatScreen({
    super.key,
    this.initialBoardContext,
    this.initialPrompt,
  });

  @override
  ConsumerState<EpiChatScreen> createState() => _EpiChatScreenState();
}

class _EpiChatScreenState extends ConsumerState<EpiChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<EpiAttachedItem> _attachedItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSend(widget.initialPrompt!.trim());
      });
    }
  }

  final List<String> _quickPrompts = [
    "What's on my plate today?",
    "Help me decide what to do first",
    "Remind me to submit the lab report Friday, high priority",
    "Save these meeting points as a note",
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend([String? textOverride]) {
    final rawText = textOverride ?? _textController.text;
    if (rawText.trim().isEmpty) return;

    final textToSend = rawText.trim();

    if (textOverride == null) {
      _textController.clear();
    }
    final attachedSnapshot = List<EpiAttachedItem>.from(_attachedItems);
    setState(() => _attachedItems.clear());

    ref.read(epiChatProvider.notifier).sendMessage(
      textToSend,
      context,
      attachedItems: attachedSnapshot,
    );
    _scrollToBottom();
  }

  Future<void> _handleUndo() async {
    final result = await ref.read(epiChatProvider.notifier).undoLastAction();
    if (!mounted) return;
    if (result != null) {
      FeedbackService.showSuccess(result);
    } else {
      FeedbackService.showInfo('No recent actions to undo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(epiChatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    // Trigger scroll when new messages arrive or text streams
    ref.listen(epiChatProvider.select((s) => s.messages.length), (prev, next) {
      _scrollToBottom();
    });
    ref.listen(epiChatProvider.select((s) => s.messages.isNotEmpty ? s.messages.last.text.length : 0), (prev, next) {
      _scrollToBottom();
    });
    ref.listen(epiChatProvider.select((s) => s.statusText), (prev, next) {
      if (next != null) _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: bgApp,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: bgApp,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Epi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: chatState.isBackendOnline
                              ? activeBlue
                              : (isDark ? EpicordiaColors.warningDark : EpicordiaColors.warningLight),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        chatState.isBackendOnline ? 'Companion' : 'Connecting...',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Remix.history_line, size: 20),
              tooltip: 'Past chats',
              color: textSecondary,
              onPressed: () => _showHistorySheet(cardBg, textPrimary, textSecondary, borderClr, activeBlue),
            ),
            IconButton(
              icon: const Icon(Remix.arrow_go_back_line, size: 20),
              tooltip: 'Undo last action',
              color: textSecondary,
              onPressed: _handleUndo,
            ),
            IconButton(
              icon: const Icon(Remix.add_large_line, size: 20),
              tooltip: 'New chat',
              color: textSecondary,
              onPressed: () {
                ref.read(epiChatProvider.notifier).clearChat();
                setState(() => _attachedItems.clear());
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Error banner if any
            if (chatState.error != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatState.error!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Message list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: chatState.messages.length + (chatState.statusText != null ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < chatState.messages.length) {
                    final message = chatState.messages[index];
                    return _buildMessageItem(message, isDark, cardBg, textPrimary, textSecondary, borderClr, activeBlue);
                  }
                  return _buildActivityStatusIndicator(chatState.statusText!, isDark);
                },
              ),
            ),

            // Context & Action Pills Row
            Container(
              height: 34,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildPillButton(
                    icon: Icons.description_outlined,
                    label: '+ Note',
                    isDark: isDark,
                    cardBg: cardBg,
                    borderClr: borderClr,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    activeBlue: activeBlue,
                    onTap: () => _showNotePicker(cardBg, textPrimary, textSecondary, borderClr, activeBlue),
                  ),
                  const SizedBox(width: 8),
                  _buildPillButton(
                    icon: Icons.check_circle_outline_rounded,
                    label: '+ Task',
                    isDark: isDark,
                    cardBg: cardBg,
                    borderClr: borderClr,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    activeBlue: activeBlue,
                    onTap: () => _showTaskPicker(cardBg, textPrimary, textSecondary, borderClr, activeBlue),
                  ),
                  const SizedBox(width: 8),
                  _buildPillButton(
                    icon: Icons.calendar_today_outlined,
                    label: '+ Schedule',
                    isDark: isDark,
                    cardBg: cardBg,
                    borderClr: borderClr,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    activeBlue: activeBlue,
                    onTap: () => _showSchedulePicker(cardBg, textPrimary, textSecondary, borderClr, activeBlue),
                  ),
                  const SizedBox(width: 8),
                  _buildPillButton(
                    icon: Remix.eraser_line,
                    label: 'Wipe thread',
                    isDark: isDark,
                    cardBg: cardBg,
                    borderClr: borderClr,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    activeBlue: activeBlue,
                    onTap: () {
                      ref.read(epiChatProvider.notifier).clearChat();
                      setState(() => _attachedItems.clear());
                      FeedbackService.showInfo('Thread wiped. Fresh start!');
                    },
                  ),
                  if (chatState.messages.length <= 2) ...[
                    const SizedBox(width: 8),
                    for (final prompt in _quickPrompts) ...[
                      ActionChip(
                        label: Text(
                          prompt,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        backgroundColor: isDark
                            ? EpicordiaColors.surfaceSunkenDark
                            : EpicordiaColors.surfaceSunkenLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: borderClr),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onPressed: () => _handleSend(prompt),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ],
              ),
            ),

            // Attached Context Items Chips Bar
            if (_attachedItems.isNotEmpty)
              Container(
                height: 32,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _attachedItems.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final item = _attachedItems[index];
                    final IconData icon;
                    switch (item.type) {
                      case EpiAttachedItemType.note:
                        icon = Icons.description_outlined;
                        break;
                      case EpiAttachedItemType.task:
                        icon = Icons.check_circle_outline_rounded;
                        break;
                      case EpiAttachedItemType.schedule:
                        icon = Icons.calendar_today_outlined;
                        break;
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: activeBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: activeBlue.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 12, color: activeBlue),
                          const SizedBox(width: 5),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: activeBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() => _attachedItems.removeAt(index));
                            },
                            child: Icon(Icons.close_rounded, size: 13, color: activeBlue),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Bottom Pill Input Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? EpicordiaColors.surfaceSunkenDark
                      : EpicordiaColors.surfaceSunkenLight,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: borderClr),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 4,
                        style: TextStyle(fontSize: 14, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: "Talk with Epi...",
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: textSecondary.withValues(alpha: 0.75),
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Material(
                          color: activeBlue,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: chatState.isLoading ? null : () => _handleSend(),
                            child: Center(
                              child: chatState.isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 19,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(
    EpiChatMessage message,
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderClr,
    Color activeBlue,
  ) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4),
              ),
              border: Border.all(color: borderClr),
            ),
            child: Text(
              message.text,
              style: TextStyle(color: textPrimary, fontSize: 14, height: 1.35),
            ),
          ),
        ),
      );
    }

    // Epi's message
    if (message.text.trim().isEmpty && message.actionRecords.isEmpty && message.timelineSteps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: activeBlue.withValues(alpha: 0.15),
            child: Icon(Icons.auto_awesome, color: activeBlue, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline steps (dull, muted) shown while working or after
                if (message.timelineSteps.isNotEmpty)
                  _buildTimelineTile(message.timelineSteps, message.isWorking, isDark),

                if (message.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    child: MarkdownBody(
                      data: message.isStreaming ? '${message.text} ▊' : message.text,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: TextStyle(fontSize: 14.5, color: textPrimary, height: 1.45),
                      ),
                    ),
                  ),

                // Rich output chips for queried/created entities
                if (!message.isWorking && message.actionRecords.isNotEmpty)
                  _buildRichOutputChips(message.actionRecords, isDark, cardBg, textPrimary, textSecondary, borderClr, activeBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Subtle timeline of intermediate tool steps: spinning when running, check when done.
  Widget _buildTimelineTile(List<EpiTimelineStep> steps, bool isWorking, bool isDark) {
    final dullColor = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps.map((step) {
          final isRunning = step.status == EpiTimelineStepStatus.running;
          final isSuccess = step.status == EpiTimelineStepStatus.success;
          final isCancelled = step.status == EpiTimelineStepStatus.cancelled;

          final Color stepColor = isRunning
              ? dullColor.withValues(alpha: 0.6)
              : isSuccess
                  ? dullColor.withValues(alpha: 0.75)
                  : dullColor.withValues(alpha: 0.5);

          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRunning)
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.2,
                      valueColor: AlwaysStoppedAnimation<Color>(stepColor),
                    ),
                  )
                else
                  Icon(
                    isSuccess
                        ? Icons.check_rounded
                        : isCancelled
                            ? Icons.remove_circle_outline_rounded
                            : Icons.error_outline_rounded,
                    size: 11,
                    color: stepColor,
                  ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: stepColor,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Compact rich output chips for tasks/notes found or created by Epi.
  Widget _buildRichOutputChips(
    List<EpiActionExecutionRecord> records,
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderClr,
    Color activeBlue,
  ) {
    // Only show chips for records that produced data
    final richRecords = records.where((r) {
      if (r.status != ActionExecutionStatus.success) return false;
      if (r.outputData == null) return false;
      final data = r.outputData;
      if (data is List && data.isEmpty) return false;
      if (data is Map && data.isEmpty) return false;
      return true;
    }).toList();

    if (richRecords.isEmpty) return const SizedBox.shrink();

    final chips = <Widget>[];
    final seenKeys = <String>{};

    for (final record in richRecords) {
      final tool = record.action.tool;
      final data = record.outputData;

      if (data is List) {
        for (final item in data.take(5)) {
          if (item is Map<String, dynamic>) {
            final title = item['title'] as String? ?? item['name'] as String? ?? '';
            if (title.isEmpty) continue;
            final key = '${item['id'] ?? ''}_$title';
            if (seenKeys.contains(key)) continue;
            seenKeys.add(key);

            IconData icon;
            if (tool.contains('task')) {
              icon = Icons.check_circle_outline_rounded;
            } else if (tool.contains('note')) {
              icon = Icons.description_outlined;
            } else if (tool.contains('board') || tool.contains('project')) {
              icon = Icons.folder_outlined;
            } else {
              icon = Icons.calendar_today_outlined;
            }

            chips.add(_buildResultChip(title, icon, isDark, cardBg, textPrimary, textSecondary, borderClr, activeBlue, extraData: item));
          }
        }
      } else if (data is Map<String, dynamic>) {
        final title = data['title'] as String? ?? data['name'] as String? ?? '';
        if (title.isNotEmpty) {
          final key = '${data['id'] ?? ''}_$title';
          if (seenKeys.contains(key)) continue;
          seenKeys.add(key);

          IconData icon;
          if (tool.contains('task')) {
            icon = Icons.check_circle_outline_rounded;
          } else if (tool.contains('note')) {
            icon = Icons.description_outlined;
          } else {
            icon = Icons.star_outline_rounded;
          }
          chips.add(_buildResultChip(title, icon, isDark, cardBg, textPrimary, textSecondary, borderClr, activeBlue, extraData: data));
        }
      }
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: chips,
      ),
    );
  }

  Widget _buildResultChip(
    String title,
    IconData icon,
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderClr,
    Color activeBlue, {
    Map<String, dynamic>? extraData,
  }) {
    final dueDate = extraData?['dueDate'] as String?;
    final status = extraData?['status'] as String?;
    final priority = extraData?['priority'] as String?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? EpicordiaColors.surfaceSunkenDark
            : EpicordiaColors.surfaceSunkenLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderClr),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: activeBlue.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                if (dueDate != null || status != null || priority != null)
                  Text(
                    [
                      ?status,
                      ?priority,
                      if (dueDate != null) _formatDueDateShort(dueDate),
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDueDateShort(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = dt.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (diff == 0) return 'today';
      if (diff == 1) return 'tomorrow';
      if (diff == -1) return 'yesterday';
      if (diff < 0) return '${diff.abs()}d overdue';
      if (diff <= 7) return 'in ${diff}d';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return isoDate;
    }
  }

  Widget _buildActivityStatusIndicator(String statusText, bool isDark) {
    final dullColor = isDark
        ? EpicordiaColors.textTertiaryDark
        : EpicordiaColors.textTertiaryLight;

    return Padding(
      padding: const EdgeInsets.only(left: 42, top: 2, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(dullColor.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: dullColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotePicker(Color cardBg, Color textPrimary, Color textSecondary, Color borderClr, Color activeBlue) async {
    final pinDao = ref.read(pinDaoProvider);
    final allNotes = await pinDao.getAllNotes();
    final nonLockedNotes = allNotes.where((n) => !n.isLocked).toList();

    if (!mounted) return;

    if (nonLockedNotes.isEmpty) {
      FeedbackService.showInfo('No notes found. Create a note first!');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.description_outlined, color: activeBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Attach Note Context',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: nonLockedNotes.length,
                    itemBuilder: (context, index) {
                      final n = nonLockedNotes[index];
                      final blocks = NoteDocument.decodeBlocks(n.content ?? '');
                      final title = blocks.isNotEmpty && blocks.first.text.trim().isNotEmpty
                          ? blocks.first.text.trim()
                          : 'Untitled Note';
                      final preview = blocks.length > 1
                          ? blocks.sublist(1).map((b) => b.text).take(3).join(' ')
                          : '';

                      final isAttached = _attachedItems.any((a) => a.id == n.id);

                      return ListTile(
                        leading: Icon(
                          Icons.description_outlined,
                          color: isAttached ? activeBlue : textSecondary,
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: isAttached ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: preview.isNotEmpty
                            ? Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis)
                            : null,
                        trailing: isAttached ? Icon(Icons.check_rounded, color: activeBlue) : null,
                        onTap: () {
                          if (!isAttached) {
                            setState(() {
                              _attachedItems.add(EpiAttachedItem(
                                id: n.id,
                                title: title,
                                type: EpiAttachedItemType.note,
                                preview: preview,
                              ));
                            });
                          }
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTaskPicker(Color cardBg, Color textPrimary, Color textSecondary, Color borderClr, Color activeBlue) async {
    final taskDao = ref.read(taskDaoProvider);
    final allTasks = await taskDao.getAllTasks();

    if (!mounted) return;

    if (allTasks.isEmpty) {
      FeedbackService.showInfo('No tasks found. Create a task first!');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: activeBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Attach Task Context',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: allTasks.length,
                    itemBuilder: (context, index) {
                      final t = allTasks[index];
                      final isAttached = _attachedItems.any((a) => a.id == t.id);

                      return ListTile(
                        leading: Icon(
                          Icons.task_alt_rounded,
                          color: isAttached ? activeBlue : textSecondary,
                        ),
                        title: Text(
                          t.title,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: isAttached ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          'Status: ${t.status} • Priority: ${t.priority}',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                        trailing: isAttached ? Icon(Icons.check_rounded, color: activeBlue) : null,
                        onTap: () {
                          if (!isAttached) {
                            setState(() {
                              _attachedItems.add(EpiAttachedItem(
                                id: t.id,
                                title: t.title,
                                type: EpiAttachedItemType.task,
                                preview: t.notes,
                              ));
                            });
                          }
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSchedulePicker(Color cardBg, Color textPrimary, Color textSecondary, Color borderClr, Color activeBlue) async {
    final timetableDao = ref.read(timetableDaoProvider);
    final allSlots = await timetableDao.getAllSlots();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: activeBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Attach Schedule Context',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.today_rounded, color: activeBlue),
                  title: Text(
                    "Today's Schedule",
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text("Attach today's timetable blocks and routine", style: TextStyle(color: textSecondary, fontSize: 12)),
                  onTap: () {
                    setState(() {
                      if (!_attachedItems.any((a) => a.id == 'sched_today')) {
                        _attachedItems.add(const EpiAttachedItem(
                          id: 'sched_today',
                          title: "Today's Schedule",
                          type: EpiAttachedItemType.schedule,
                        ));
                      }
                    });
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.calendar_view_week_rounded, color: activeBlue),
                  title: Text(
                    "Weekly Timetable",
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text("Attach full weekly timetable schedule", style: TextStyle(color: textSecondary, fontSize: 12)),
                  onTap: () {
                    setState(() {
                      if (!_attachedItems.any((a) => a.id == 'sched_week')) {
                        _attachedItems.add(const EpiAttachedItem(
                          id: 'sched_week',
                          title: "Weekly Timetable",
                          type: EpiAttachedItemType.schedule,
                        ));
                      }
                    });
                    Navigator.pop(ctx);
                  },
                ),
                if (allSlots.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Text(
                      'Specific Slots',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textSecondary),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: allSlots.length,
                      itemBuilder: (context, index) {
                        final slot = allSlots[index];
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final dayLabel = (slot.dayOfWeek >= 1 && slot.dayOfWeek <= 7)
                            ? days[slot.dayOfWeek - 1]
                            : 'Day ${slot.dayOfWeek}';
                        final label = '$dayLabel ${slot.startTime}-${slot.endTime}: ${slot.title}';
                        final isAttached = _attachedItems.any((a) => a.id == slot.id);

                        return ListTile(
                          dense: true,
                          leading: Icon(Icons.access_time_rounded, size: 18, color: isAttached ? activeBlue : textSecondary),
                          title: Text(label, style: TextStyle(fontSize: 13, color: textPrimary)),
                          trailing: isAttached ? Icon(Icons.check_rounded, color: activeBlue, size: 18) : null,
                          onTap: () {
                            if (!isAttached) {
                              setState(() {
                                _attachedItems.add(EpiAttachedItem(
                                  id: slot.id,
                                  title: '${slot.title} ($dayLabel)',
                                  type: EpiAttachedItemType.schedule,
                                  preview: '${slot.startTime}-${slot.endTime} ${slot.location ?? ""}',
                                ));
                              });
                            }
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardBg,
    required Color borderClr,
    required Color textPrimary,
    required Color textSecondary,
    required Color activeBlue,
    IconData? trailingIcon,
    bool isSelected = false,
  }) {
    final bgColor = isSelected
        ? activeBlue.withValues(alpha: isDark ? 0.25 : 0.12)
        : (isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight);
    final borderColor = isSelected ? activeBlue.withValues(alpha: 0.5) : borderClr;
    final contentColor = isSelected ? activeBlue : textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: contentColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: contentColor,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(trailingIcon, size: 13, color: contentColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showHistorySheet(
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderClr,
    Color activeBlue,
  ) async {
    final notifier = ref.read(epiChatProvider.notifier);
    final convs = await notifier.getConversations();
    final currentSessionId = ref.read(epiChatProvider).sessionId;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.history_rounded, size: 20, color: activeBlue),
                              const SizedBox(width: 8),
                              Text(
                                'Past Chats',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              notifier.clearChat();
                              setState(() => _attachedItems.clear());
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Remix.add_large_line, size: 16),
                            label: const Text('New Chat'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    if (convs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Center(
                          child: Text(
                            'No saved chats yet. Start talking with Epi!',
                            style: TextStyle(fontSize: 13, color: textSecondary),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: convs.length,
                          itemBuilder: (context, index) {
                            final conv = convs[index];
                            final isCurrent = conv.id == currentSessionId;
                            final formattedDate = _formatConvDate(conv.updatedAt);

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: isCurrent
                                    ? activeBlue.withValues(alpha: 0.2)
                                    : textSecondary.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 15,
                                  color: isCurrent ? activeBlue : textSecondary,
                                ),
                              ),
                              title: Text(
                                conv.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                                  color: isCurrent ? activeBlue : textPrimary,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    formattedDate,
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                  ),
                                  if (conv.boardContext != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '• ${conv.boardContext}',
                                      style: TextStyle(fontSize: 11, color: activeBlue),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: textSecondary.withValues(alpha: 0.7),
                                ),
                                onPressed: () async {
                                  await notifier.deleteConversation(conv.id);
                                  setSheetState(() {
                                    convs.removeAt(index);
                                  });
                                },
                              ),
                              onTap: () async {
                                await notifier.switchConversation(conv.id);
                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                }
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatConvDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}

// ignore: unused_element
class _EpiChatTaskCard extends ConsumerWidget {
  final String taskId;
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color borderClr;
  final Color activeBlue;

  const _EpiChatTaskCard({
    required this.taskId,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderClr,
    required this.activeBlue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskDao = ref.watch(taskDaoProvider);

    return StreamBuilder<TaskEntity?>(
      stream: taskDao.watchTask(taskId),
      builder: (context, snapshot) {
        final task = snapshot.data;
        if (task == null) return const SizedBox.shrink();

        final isCompleted = task.status == 'done';
        final notesPayload = TaskSubitem.decodeNotes(task.notes);
        final subitems = notesPayload.subitems;

        return Container(
          margin: const EdgeInsets.only(top: 4, bottom: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderClr),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                ItemInteractionDialogs.showTaskDetailDialog(
                  context: context,
                  ref: ref,
                  task: task,
                  boardTitle: task.boardId ?? 'Inbox',
                  boardColor: activeBlue,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2, right: 10),
                          child: CustomCircularCheckbox(
                            isChecked: isCompleted,
                            size: 19,
                            activeColor: activeBlue,
                            borderColor: textTertiary,
                            onTap: () {
                              final newStatus = isCompleted ? 'todo' : 'done';
                              ref.read(taskRepositoryProvider).updateTask(
                                task.copyWith(
                                  status: newStatus,
                                  modifiedAt: DateTime.now(),
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted ? textTertiary : textPrimary,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  decorationColor: textTertiary,
                                ),
                              ),
                              if (notesPayload.userNotes != null && notesPayload.userNotes!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  notesPayload.userNotes!.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (subitems.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Column(
                          children: subitems.take(3).map((sub) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    sub.isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                    size: 13,
                                    color: sub.isDone ? activeBlue : textTertiary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      sub.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: sub.isDone ? textTertiary : textSecondary,
                                        decoration: sub.isDone ? TextDecoration.lineThrough : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (task.dueDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: activeBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_outlined, size: 12, color: activeBlue),
                                const SizedBox(width: 4),
                                Text(
                                  TaskDateFormatter.formatDueDate(task.dueDate),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: activeBlue),
                                ),
                              ],
                            ),
                          ),
                        if (task.priority > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: (task.priority == 2
                                      ? (isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight)
                                      : (isDark ? EpicordiaColors.warningDark : EpicordiaColors.warningLight))
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task.priority == 2 ? 'High Priority' : 'Medium Priority',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: task.priority == 2
                                    ? (isDark ? EpicordiaColors.errorDark : EpicordiaColors.errorLight)
                                    : (isDark ? EpicordiaColors.warningDark : EpicordiaColors.warningLight),
                              ),
                            ),
                          ),
                        if (task.boardId != null && task.boardId!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: textTertiary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.dashboard_outlined, size: 11, color: textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  task.boardId!,
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ignore: unused_element
class _EpiChatNoteCard extends ConsumerWidget {
  final String noteId;
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color borderClr;
  final Color activeBlue;

  const _EpiChatNoteCard({
    required this.noteId,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderClr,
    required this.activeBlue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinDao = ref.watch(pinDaoProvider);

    return StreamBuilder<PinEntity?>(
      stream: pinDao.watchPin(noteId),
      builder: (context, snapshot) {
        final note = snapshot.data;
        if (note == null) return const SizedBox.shrink();

        final rawContent = note.content ?? '';
        final blocks = NoteDocument.decodeBlocks(rawContent);

        String title = 'Untitled Note';
        String previewText = '';

        if (blocks.isNotEmpty) {
          if (blocks.first.type == BlockType.heading) {
            title = blocks.first.text.isNotEmpty ? blocks.first.text : 'Untitled Note';
            final bodyBlocks = blocks.sublist(1);
            if (bodyBlocks.isNotEmpty) {
              previewText = bodyBlocks.map((b) => b.text).where((t) => t.isNotEmpty).join(' ');
            }
          } else {
            title = blocks.first.text.isNotEmpty ? blocks.first.text : 'Untitled Note';
          }
        }

        final tag = note.tags ?? 'Note';

        return Container(
          margin: const EdgeInsets.only(top: 4, bottom: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderClr),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                ItemInteractionDialogs.showNoteDetailDialog(
                  context: context,
                  ref: ref,
                  note: note,
                  boardTitle: note.boardId ?? '',
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description_outlined, size: 14, color: activeBlue),
                        const SizedBox(width: 6),
                        Text(
                          tag.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: activeBlue,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios_rounded, size: 11, color: textTertiary),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    if (previewText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        previewText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
