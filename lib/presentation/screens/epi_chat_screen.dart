import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/feedback_service.dart';
import '../../data/providers.dart';
import '../../data/database/database.dart';
import '../../data/repository/task_repository.dart';
import '../../data/repository/board_repository.dart';
import '../../domain/models/task_subitem.dart';
import '../../domain/models/note_model.dart';
import '../../core/utils/task_date_formatter.dart';
import '../widgets/core/custom_circular_checkbox.dart';
import '../widgets/core/item_interaction_dialogs.dart';
import '../../domain/epi/epi_chat_controller.dart';
import '../../domain/epi/epi_models.dart';
import '../widgets/edit_timetable_slot_dialog.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/models/chat_attachment_model.dart';
import '../../domain/services/image_attachment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/services/speech_recognition_service.dart';
import '../widgets/permission_explanation_dialog.dart';

class EpiChatScreen extends ConsumerStatefulWidget {
  final String? initialBoardContext;
  final String? initialPrompt;
  final List<EpiAttachedItem>? initialAttachedItems;
  final bool isEmbedded;
  final VoidCallback? onClose;
  final VoidCallback? onExpand;

  const EpiChatScreen({
    super.key,
    this.initialBoardContext,
    this.initialPrompt,
    this.initialAttachedItems,
    this.isEmbedded = false,
    this.onClose,
    this.onExpand,
  });

  @override
  ConsumerState<EpiChatScreen> createState() => _EpiChatScreenState();
}

class _EpiChatScreenState extends ConsumerState<EpiChatScreen>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<EpiAttachedItem> _attachedItems = [];
  ChatAttachment? _attachedImage;
  late final AnimationController _pulseController;
  String _textBeforeSpeech = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    if (widget.initialAttachedItems != null && widget.initialAttachedItems!.isNotEmpty) {
      _attachedItems.addAll(widget.initialAttachedItems!);
    }
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
    _pulseController.dispose();
    try {
      ref.read(speechRecognitionProvider.notifier).stopListening();
    } catch (_) {}
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

  Future<void> _toggleSpeechInput() async {
    final speechState = ref.read(speechRecognitionProvider);
    final speechNotifier = ref.read(speechRecognitionProvider.notifier);

    if (speechState.isListening) {
      await speechNotifier.stopListening();
      return;
    }

    if (!speechState.isInitialized) {
      final proceed = await PermissionExplanationDialog.show(
        context: context,
        title: 'Voice Input',
        description:
            'Epicordia uses on-device speech recognition to transcribe your voice completely offline. No audio or transcripts ever leave your device.',
        icon: Icons.mic_rounded,
      );
      if (!proceed) return;
    }

    HapticFeedback.lightImpact();
    _textBeforeSpeech = _textController.text.trim();

    final started = await speechNotifier.startListening(
      onResult: (words, isFinal) {
        if (!mounted) return;
        final base = _textBeforeSpeech;
        final newText = base.isEmpty ? words : '$base $words';
        _textController.text = newText;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: newText.length),
        );
      },
    );

    if (!started && mounted) {
      final current = ref.read(speechRecognitionProvider);
      if (current.errorMessage != null && current.errorMessage!.isNotEmpty) {
        FeedbackService.showError(current.errorMessage!, context: context);
      }
    }
  }

  Widget _buildSpeechMicButton(
    SpeechRecognitionState speechState,
    bool isDark,
    Color activeBlue,
    Color textSecondary,
  ) {
    final isListening = speechState.isListening;

    if (isListening) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.12);
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Material(
                color: Colors.redAccent,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _toggleSpeechInput,
                  child: const Center(
                    child: Icon(
                      Remix.mic_fill,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _toggleSpeechInput,
          child: Center(
            child: Icon(
              Remix.mic_line,
              size: 20,
              color: textSecondary.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleImageAttachment(
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderClr,
    Color activeBlue,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final noticeShown = prefs.getBool('epi_image_privacy_notice_shown') ?? false;

    if (!noticeShown && mounted) {
      final accepted = await showDialog<bool>(
        context: rootNavigatorKey.currentContext ?? context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: activeBlue),
              const SizedBox(width: 8),
              Text('Privacy Notice', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Photos attached to Epi are processed strictly on-demand to analyze their content (reading lists, notes, or schedules). Images are never stored on any server or used for training.',
            style: TextStyle(color: textSecondary, fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Got it', style: TextStyle(color: activeBlue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (accepted == true) {
        await prefs.setBool('epi_image_privacy_notice_shown', true);
      } else {
        return;
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: rootNavigatorKey.currentContext ?? context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        ImageSource? selectedSource;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final cardColor = borderClr.withValues(alpha: 0.35);
            final selectedColor = activeBlue.withValues(alpha: 0.15);
            final selectedBorder = activeBlue;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Title row ──
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Upload Photo',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // ── Option cards ──
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
            Navigator.pop(ctx);
            final attachment = await ImageAttachmentService.pickAndCompressImage(ImageSource.camera);
            if (attachment != null && mounted) {
              setState(() => _attachedImage = attachment);
            }},
          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              decoration: BoxDecoration(
                                color: selectedSource == ImageSource.camera ? selectedColor : cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selectedSource == ImageSource.camera ? selectedBorder : Colors.transparent,
                                  width: 1.8,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Remix.camera_line, size: 32, color: activeBlue),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Take a Picture',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: GestureDetector(
                            // onTap: () => setModalState(() => selectedSource = ImageSource.gallery),
                            onTap: () async {
            Navigator.pop(ctx);
            final attachment = await ImageAttachmentService.pickAndCompressImage(ImageSource.gallery);
            if (attachment != null && mounted) {
              setState(() => _attachedImage = attachment);
            }},
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              decoration: BoxDecoration(
                                color: selectedSource == ImageSource.gallery ? selectedColor : cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selectedSource == ImageSource.gallery ? selectedBorder : Colors.transparent,
                                  width: 1.8,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Remix.image_circle_line, size: 32, color: activeBlue),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Gallery',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 70),
                    // // ── Upload button ──
                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 48,
                    //   child: ElevatedButton(
                    //     onPressed: selectedSource == null
                    //         ? null
                    //         : () async {
                    //             Navigator.pop(ctx);
                    //             final attachment = await ImageAttachmentService.pickAndCompressImage(selectedSource!);
                    //             if (attachment != null && mounted) {
                    //               setState(() => _attachedImage = attachment);
                    //             }
                    //           },
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: activeBlue,
                    //       disabledBackgroundColor: activeBlue.withValues(alpha: 0.35),
                    //       foregroundColor: Colors.white,
                    //       disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                    //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    //       elevation: 0,
                    //     ),
                    //     child: const Text(
                    //       'Upload',
                    //       style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleSend([String? textOverride]) {
    if (ref.read(speechRecognitionProvider).isListening) {
      ref.read(speechRecognitionProvider.notifier).stopListening();
    }

    final rawText = textOverride ?? _textController.text;
    final imageToSend = _attachedImage;

    if (rawText.trim().isEmpty && imageToSend == null) return;

    final textToSend = rawText.trim();

    if (textOverride == null) {
      _textController.clear();
    }
    final attachedSnapshot = List<EpiAttachedItem>.from(_attachedItems);
    setState(() {
      _attachedItems.clear();
      _attachedImage = null;
    });

    ref.read(epiChatProvider.notifier).sendMessage(
      textToSend,
      context,
      attachment: imageToSend,
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

  Future<void> _openScheduleSlotById(String slotId) async {
    final timetableDao = ref.read(timetableDaoProvider);
    final allSlots = await timetableDao.getAllSlots();
    final slot = allSlots.where((s) => s.id == slotId).firstOrNull;
    if (!mounted) return;
    if (slot != null) {
      EditTimetableSlotDialog.show(context, slot: slot);
    } else {
      FeedbackService.showError('This schedule slot has been deleted', context: context);
    }
  }

  void _pushRoute(String route, {Object? extra}) {
    ref.read(routerProvider).push(route, extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(epiChatProvider);
    final speechState = ref.watch(speechRecognitionProvider);
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
    ref.listen<String?>(speechRecognitionProvider.select((s) => s.errorMessage), (prev, next) {
      if (next != null && next.isNotEmpty && mounted) {
        FeedbackService.showError(next, context: context);
      }
    });

    final chatBody = Column(
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
              child: chatState.messages.isEmpty && chatState.statusText == null
                  ? _buildEmptyGreeting(isDark, cardBg, textPrimary, textSecondary, borderClr, activeBlue)
                  : ListView.builder(
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
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          if (item.type == EpiAttachedItemType.task) {
                            final task = await ref.read(taskDaoProvider).getTask(item.id);
                            if (context.mounted) {
                              if (task != null) {
                                _pushRoute('/task/${item.id}');
                              } else {
                                FeedbackService.showError('This task has been deleted', context: context);
                              }
                            }
                          } else if (item.type == EpiAttachedItemType.note) {
                            final pin = await ref.read(pinDaoProvider).getPin(item.id);
                            if (context.mounted) {
                              if (pin != null) {
                                _pushRoute('/note/${item.id}');
                              } else {
                                FeedbackService.showError('This note has been deleted', context: context);
                              }
                            }
                          } else if (item.type == EpiAttachedItemType.schedule) {
                            if (item.id == 'sched_today' || item.id == 'sched_week') {
                              _pushRoute('/calendar');
                            } else {
                              _openScheduleSlotById(item.id);
                            }
                          }
                        },
                        child: Container(
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
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() => _attachedItems.removeAt(index));
                                },
                                child: Icon(Icons.close_rounded, size: 13, color: activeBlue),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Live speech listening status banner
            if (speechState.isListening)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: (isDark ? EpicordiaColors.blue900 : EpicordiaColors.blue100).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: activeBlue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Listening offline... Speak your prompt',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(speechRecognitionProvider.notifier).stopListening(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: activeBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: activeBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Image Attachment Preview Staging Area
            if (_attachedImage != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderClr),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _attachedImage!.bytes,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _attachedImage!.fileName,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _attachedImage!.formattedSize,
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: textSecondary,
                      onPressed: () => setState(() => _attachedImage = null),
                    ),
                  ],
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
                    IconButton(
                      icon: Icon(Remix.add_fill, size: 20, color: textSecondary.withValues(alpha: 0.85)),
                      tooltip: 'Attach Image',
                      onPressed: () => _handleImageAttachment(cardBg, textPrimary, textSecondary, borderClr, activeBlue),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 4,
                        style: TextStyle(fontSize: 14, color: textPrimary),
                        decoration: InputDecoration(
                          hintText: speechState.isListening ? "Listening (offline)..." : "Talk with Epi...",
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: textSecondary.withValues(alpha: 0.75),
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    // Speech Mic Button
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _buildSpeechMicButton(
                        speechState,
                        isDark,
                        activeBlue,
                        textSecondary,
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
        );

    if (widget.isEmbedded) {
      return Material(
        color: cardBg,
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderClr)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: activeBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.auto_awesome, size: 16, color: activeBlue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Epi Chat',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: chatState.isBackendOnline ? const Color(0xFF10B981) : Colors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                chatState.isBackendOnline ? 'Active' : 'Connecting...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10.5, color: textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Remix.add_large_line, size: 18),
                    tooltip: 'New chat',
                    color: textSecondary,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      ref.read(epiChatProvider.notifier).clearChat();
                      setState(() => _attachedItems.clear());
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.open_in_full_rounded, size: 17),
                    tooltip: 'Full screen',
                    color: textSecondary,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: widget.onExpand ?? () => ref.read(routerProvider).push('/epi'),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 19),
                    tooltip: 'Close',
                    color: textSecondary,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Expanded(child: chatBody),
          ],
        ),
      );
    }

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
                    'Epi Chat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),

                  Text(
                    chatState.isBackendOnline ? 'Active' : 'Connecting...',
                    style: TextStyle(fontSize: 11, color: textSecondary),
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
        child: chatBody,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.attachment != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200, maxWidth: 280),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderClr),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.memory(
                        message.attachment!.bytes,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (message.text.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.fromLTRB(16, 10, 10, 6),
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
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        message.text,
                        style: TextStyle(color: textPrimary, fontSize: 14, height: 1.35),
                      ),
                    ),
                  ),
                const SizedBox(height: 3),
                if (message.text.isNotEmpty)
                  _CopyMessageButton(
                    text: message.text,
                    color: textSecondary.withValues(alpha: 0.65),
                    activeColor: activeBlue,
                  ),
              ],
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

                // Copy button at the bottom of the reply
                if (!message.isWorking && !message.isStreaming && message.text.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CopyMessageButton(
                          text: message.text,
                          color: textSecondary.withValues(alpha: 0.65),
                          activeColor: activeBlue,
                        ),
                      ],
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

  Widget _buildEmptyGreeting(
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderClr,
    Color activeBlue,
  ) {
    final suggestions = const [
      'What can you do?',
      'I feel overwhelmed, help me figure out what is urgent',
      'Help me prepare for my exam next week',
      'Help me track my monthly expenses',
      'Help me build a workout schedule',
      'Help me stick to a daily reading habit',
      'I have a business idea, let us think through it',
      'Remind me to call my mum every Sunday',
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeBlue.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.auto_awesome, color: activeBlue, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              'Talk things through with Epi',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'From studying and habits to budgeting and daily overwhelm, I am here to help you get your thoughts organized.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions.map((s) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _handleSend(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: isDark
                            ? EpicordiaColors.surfaceSunkenDark
                            : EpicordiaColors.surfaceSunkenLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderClr),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 13, color: activeBlue),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              s,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Subtle collapsible timeline of intermediate tool steps: spinning when running, check when done.
  Widget _buildTimelineTile(List<EpiTimelineStep> steps, bool isWorking, bool isDark) {
    return _CollapsibleActionTimeline(
      steps: steps,
      isWorking: isWorking,
      isDark: isDark,
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
    // Only show chips for records that produced data or created/updated entities
    final richRecords = records.where((r) {
      if (r.status != ActionExecutionStatus.success) return false;
      if (r.outputData != null) {
        final data = r.outputData;
        if (data is List && data.isNotEmpty) return true;
        if (data is Map && data.isNotEmpty) return true;
      }
      if (r.createdEntityId != null || r.entityIds.isNotEmpty) return true;
      return false;
    }).toList();

    if (richRecords.isEmpty) return const SizedBox.shrink();

    final chips = <Widget>[];
    final seenIds = <String>{};
    final seenTitles = <String>{};

    bool registerIfNew({
      required String? id,
      required String title,
      required String type,
    }) {
      final cleanId = id?.trim();
      final normTitle = title.trim().toLowerCase();

      // If we already rendered this entity by ID, skip
      if (cleanId != null && cleanId.isNotEmpty && seenIds.contains(cleanId)) {
        return false;
      }

      // If we already rendered an entity with the exact same title and type, skip
      if (normTitle.isNotEmpty) {
        if (seenTitles.contains(normTitle) || seenTitles.contains('$type:$normTitle')) {
          return false;
        }
      }

      if (cleanId != null && cleanId.isNotEmpty) {
        seenIds.add(cleanId);
      }
      if (normTitle.isNotEmpty) {
        seenTitles.add(normTitle);
        seenTitles.add('$type:$normTitle');
      }
      return true;
    }

    String cleanChipTitle(String raw, String tool) {
      if (tool.contains('about_me') || tool.contains('profile') || raw.toLowerCase().contains('about me')) {
        return 'About Me';
      }
      var s = raw
          .replaceAll(RegExp(r'^(Created|Updated|Marked|Saved|Added(\s+\d+)?\s+subtasks?\s+to)\s+(task|note|schedule slot|timetable slot)?\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'^["“”\x27]+|["“”\x27]+$'), '')
          .replaceAll(RegExp(r'\s+profile$', caseSensitive: false), '')
          .trim();
      return s.isNotEmpty ? s : raw;
    }

    for (final record in richRecords) {
      final tool = record.action.tool;
      final data = record.outputData;

      if (data is List) {
        for (final item in data.take(5)) {
          if (item is Map<String, dynamic>) {
            final rawTitle = item['title'] as String? ?? item['name'] as String? ?? '';
            final title = cleanChipTitle(rawTitle, tool);
            if (title.isEmpty) continue;

            final explicitType = item['type']?.toString().toLowerCase();
            final String itemType = (tool.contains('task') || explicitType == 'task')
                ? 'task'
                : (tool.contains('schedule') || tool.contains('timetable') || explicitType == 'schedule')
                    ? 'schedule'
                    : (tool.contains('board') || tool.contains('project') || explicitType == 'board')
                        ? 'board'
                        : 'note';

            final id = item['id']?.toString();
            if (!registerIfNew(id: id, title: title, type: itemType)) continue;

            IconData icon;
            if (itemType == 'task') {
              icon = Icons.check_circle_outline_rounded;
            } else if (itemType == 'schedule') {
              icon = Icons.calendar_today_outlined;
            } else if (itemType == 'board') {
              icon = Icons.folder_outlined;
            } else {
              icon = Icons.description_outlined;
            }

            chips.add(_EpiInteractiveResultChip(
              title: title,
              defaultIcon: icon,
              isDark: isDark,
              cardBg: cardBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderClr: borderClr,
              activeBlue: activeBlue,
              tool: tool,
              extraData: item,
            ));
          }
        }
      } else if (data is Map<String, dynamic>) {
        final rawTitle = data['title'] as String? ?? data['name'] as String? ?? '';
        final title = cleanChipTitle(rawTitle, tool);
        if (title.isNotEmpty) {
          final explicitType = data['type']?.toString().toLowerCase();
          final String itemType = (tool.contains('task') || explicitType == 'task')
              ? 'task'
              : (tool.contains('schedule') || tool.contains('timetable') || explicitType == 'schedule')
                  ? 'schedule'
                  : (tool.contains('board') || tool.contains('project') || explicitType == 'board')
                      ? 'board'
                      : 'note';

          final id = data['id']?.toString();
          if (registerIfNew(id: id, title: title, type: itemType)) {
            IconData icon;
            if (itemType == 'task') {
              icon = Icons.check_circle_outline_rounded;
            } else if (itemType == 'schedule') {
              icon = Icons.calendar_today_outlined;
            } else if (itemType == 'board') {
              icon = Icons.folder_outlined;
            } else {
              icon = Icons.description_outlined;
            }

            chips.add(_EpiInteractiveResultChip(
              title: title,
              defaultIcon: icon,
              isDark: isDark,
              cardBg: cardBg,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              borderClr: borderClr,
              activeBlue: activeBlue,
              tool: tool,
              extraData: data,
            ));
          }
        }
      } else if (record.createdEntityId != null || record.entityIds.isNotEmpty) {
        final entityId = record.createdEntityId ?? record.entityIds.firstOrNull;
        final rawTitle = record.action.parameters['title']?.toString() ??
            record.action.parameters['name']?.toString() ??
            record.message;

        final effectiveTitle = cleanChipTitle(rawTitle, tool);
        String inferredType;
        if (tool.contains('task')) {
          inferredType = 'task';
        } else if (tool.contains('schedule') || tool.contains('timetable')) {
          inferredType = 'schedule';
        } else if (tool.contains('board') || tool.contains('project')) {
          inferredType = 'board';
        } else {
          inferredType = 'note';
        }

        if (registerIfNew(id: entityId, title: effectiveTitle, type: inferredType)) {
          IconData icon;
          if (inferredType == 'task') {
            icon = Icons.check_circle_outline_rounded;
          } else if (inferredType == 'schedule') {
            icon = Icons.calendar_today_outlined;
          } else if (inferredType == 'board') {
            icon = Icons.folder_outlined;
          } else {
            icon = Icons.description_outlined;
          }

          final fallbackData = <String, dynamic>{
            'id': entityId,
            'title': effectiveTitle,
            'type': inferredType,
            if (record.action.parameters.containsKey('due_date')) 'dueDate': record.action.parameters['due_date'],
            if (record.action.parameters.containsKey('priority')) 'priority': record.action.parameters['priority'],
            if (record.action.parameters.containsKey('status')) 'status': record.action.parameters['status'],
          };

          chips.add(_EpiInteractiveResultChip(
            title: effectiveTitle,
            defaultIcon: icon,
            isDark: isDark,
            cardBg: cardBg,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            borderClr: borderClr,
            activeBlue: activeBlue,
            tool: tool,
            extraData: fallbackData,
          ));
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
      context: rootNavigatorKey.currentContext ?? context,
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
      context: rootNavigatorKey.currentContext ?? context,
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
      context: rootNavigatorKey.currentContext ?? context,
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
      context: rootNavigatorKey.currentContext ?? context,
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

class _EpiInteractiveResultChip extends ConsumerStatefulWidget {
  final String title;
  final IconData defaultIcon;
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderClr;
  final Color activeBlue;
  final String tool;
  final Map<String, dynamic>? extraData;

  const _EpiInteractiveResultChip({
    required this.title,
    required this.defaultIcon,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderClr,
    required this.activeBlue,
    required this.tool,
    this.extraData,
  });

  @override
  ConsumerState<_EpiInteractiveResultChip> createState() => _EpiInteractiveResultChipState();
}

class _EpiInteractiveResultChipState extends ConsumerState<_EpiInteractiveResultChip> {
  String? _localStatus;

  @override
  void initState() {
    super.initState();
    _localStatus = widget.extraData?['status']?.toString();
  }

  void _handleTaskToggle(TaskEntity? liveTask, String taskId, String currentStatus) async {
    String nextStatus;
    if (currentStatus == 'todo') {
      nextStatus = 'in_progress';
    } else if (currentStatus == 'in_progress') {
      nextStatus = 'done';
    } else {
      nextStatus = 'todo';
    }

    setState(() {
      _localStatus = nextStatus;
    });

    final taskRepo = ref.read(taskRepositoryProvider);
    final taskDao = ref.read(taskDaoProvider);
    final existing = liveTask ?? await taskDao.getTask(taskId);
    if (existing != null) {
      setState(() {
        _localStatus = nextStatus;
      });
      await taskRepo.updateTask(existing.copyWith(
        status: nextStatus,
        modifiedAt: DateTime.now(),
      ));
    } else {
      if (mounted) {
        FeedbackService.showError('This task has been deleted', context: context);
      }
    }
  }

  void _onEnterItem(BuildContext context, bool isTask, bool isNote, bool isSchedule, bool isBoard, String? id) async {
    if (isTask) {
      if (id != null && id.isNotEmpty) {
        final taskDao = ref.read(taskDaoProvider);
        final task = await taskDao.getTask(id);
        if (context.mounted) {
          if (task != null) {
            ref.read(routerProvider).push('/task/$id');
          } else {
            FeedbackService.showError('This task has been deleted', context: context);
          }
        }
      } else {
        final taskDao = ref.read(taskDaoProvider);
        final allTasks = await taskDao.getAllTasks();
        final match = allTasks.where((t) => t.title.trim().toLowerCase() == widget.title.trim().toLowerCase()).firstOrNull;
        if (context.mounted) {
          if (match != null) {
            ref.read(routerProvider).push('/task/${match.id}');
          } else {
            FeedbackService.showError('This task has been deleted', context: context);
          }
        }
      }
    } else if (isNote) {
      if (id != null && id.isNotEmpty) {
        final pinDao = ref.read(pinDaoProvider);
        final pin = await pinDao.getPin(id);
        if (context.mounted) {
          if (pin != null) {
            ref.read(routerProvider).push('/note/$id');
          } else {
            FeedbackService.showError('This note has been deleted', context: context);
          }
        }
      } else {
        final pinDao = ref.read(pinDaoProvider);
        final allNotes = await pinDao.getAllNotes();
        final isAboutMe = widget.title.toLowerCase().contains('about me') || widget.tool.toLowerCase().contains('about_me');
        final match = allNotes.where((n) {
          if (isAboutMe && (n.tags != null && n.tags!.toLowerCase().contains('profile'))) return true;
          final b = NoteDocument.decodeBlocks(n.content ?? '');
          if (b.isNotEmpty) {
            final firstText = b.first.text.trim().toLowerCase();
            if (isAboutMe && (firstText == 'about me' || firstText == '# about me')) {
              return true;
            }
            if (firstText.contains(widget.title.trim().toLowerCase())) {
              return true;
            }
          }
          return false;
        }).firstOrNull;
        if (context.mounted) {
          if (match != null) {
            ref.read(routerProvider).push('/note/${match.id}');
          } else {
            FeedbackService.showError('This note has been deleted', context: context);
          }
        }
      }
    } else if (isSchedule) {
      if (id != null && id.isNotEmpty) {
        final timetableDao = ref.read(timetableDaoProvider);
        final allSlots = await timetableDao.getAllSlots();
        final slot = allSlots.where((s) => s.id == id).firstOrNull;
        if (context.mounted) {
          if (slot != null) {
            EditTimetableSlotDialog.show(rootNavigatorKey.currentContext ?? context, slot: slot);
          } else {
            FeedbackService.showError('This schedule slot has been deleted', context: context);
          }
        }
      } else {
        ref.read(routerProvider).push('/calendar');
      }
    } else if (isBoard) {
      if (id != null && id.isNotEmpty) {
        final boardRepo = ref.read(boardRepositoryProvider);
        final board = await boardRepo.getBoard(id);
        if (context.mounted) {
          if (board != null) {
            ref.read(routerProvider).push('/board/$id');
          } else {
            FeedbackService.showError('This board has been deleted', context: context);
          }
        }
      } else {
        FeedbackService.showError('This board has been deleted', context: context);
      }
    } else {
      FeedbackService.showError('This item has been deleted', context: context);
    }
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

  String _formatDayOfWeek(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (day >= 1 && day <= 7) return days[day - 1];
    return 'Day $day';
  }

  @override
  Widget build(BuildContext context) {
    final extraData = widget.extraData;
    final id = extraData?['id']?.toString();
    final tool = widget.tool.toLowerCase();
    final explicitType = extraData?['type']?.toString().toLowerCase();

    final isTask = explicitType == 'task' || tool.contains('task');
    final isBoard = explicitType == 'board' || tool.contains('board') || tool.contains('project');
    final isSchedule = explicitType == 'schedule' || tool.contains('schedule') || tool.contains('timetable');
    final isNote = explicitType == 'note' ||
        tool.contains('note') ||
        tool.contains('about_me') ||
        tool.contains('profile') ||
        widget.title.toLowerCase().contains('about me') ||
        (!isTask && !isSchedule && !isBoard);

    if (isTask && id != null && id.isNotEmpty) {
      final taskDao = ref.watch(taskDaoProvider);
      return StreamBuilder<TaskEntity?>(
        stream: taskDao.watchTask(id),
        builder: (context, snapshot) {
          final liveTask = snapshot.data;
          final currentTitle = liveTask?.title ?? widget.title;
          final currentStatus = liveTask?.status ?? _localStatus ?? extraData?['status']?.toString() ?? 'todo';
          final dueDate = liveTask?.dueDate?.toIso8601String() ?? extraData?['dueDate'] as String?;
          final priority = liveTask?.priority ?? extraData?['priority'];

          return _buildChip(
            context: context,
            title: currentTitle,
            isTask: true,
            isNote: false,
            isSchedule: false,
            isBoard: false,
            id: id,
            status: currentStatus,
            dueDate: dueDate,
            priority: priority,
            extraData: extraData,
            onTaskToggle: () => _handleTaskToggle(liveTask, id, currentStatus),
          );
        },
      );
    }

    return _buildChip(
      context: context,
      title: widget.title,
      isTask: isTask,
      isNote: isNote,
      isSchedule: isSchedule,
      isBoard: isBoard,
      id: id,
      status: _localStatus ?? extraData?['status']?.toString(),
      dueDate: extraData?['dueDate'] as String?,
      priority: extraData?['priority'],
      extraData: extraData,
      onTaskToggle: isTask && id != null
          ? () => _handleTaskToggle(null, id, _localStatus ?? 'todo')
          : null,
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String title,
    required bool isTask,
    required bool isNote,
    required bool isSchedule,
    required bool isBoard,
    required String? id,
    String? status,
    String? dueDate,
    dynamic priority,
    Map<String, dynamic>? extraData,
    VoidCallback? onTaskToggle,
  }) {
    final isDark = widget.isDark;
    final activeBlue = widget.activeBlue;
    final borderClr = widget.borderClr;
    final textPrimary = widget.textPrimary;
    final textSecondary = widget.textSecondary;

    final inProgressClr = const Color(0xFFF59E0B);
    final successClr = isDark ? EpicordiaColors.successDark : EpicordiaColors.successLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;

    final isCompleted = status == 'done';
    final isInProgress = status == 'in_progress';

    // Subtitle construction - omit status string for tasks as requested!
    final metaParts = <String>[];

    if (isTask) {
      if (priority != null) {
        if (priority == 2 || priority == '2' || priority == 'high' || priority == 'High') {
          metaParts.add('High Priority');
        } else if (priority == 1 || priority == '1' || priority == 'medium' || priority == 'Medium') {
          metaParts.add('Medium Priority');
        }
      }
      if (dueDate != null) {
        metaParts.add(_formatDueDateShort(dueDate));
      }
    } else if (isSchedule) {
      final dayOfWeek = extraData?['dayOfWeek'] ?? extraData?['day_of_week'];
      final startTime = extraData?['startTime'] ?? extraData?['start_time'];
      final endTime = extraData?['endTime'] ?? extraData?['end_time'];
      final location = extraData?['location'] as String?;

      if (dayOfWeek is num) {
        metaParts.add(_formatDayOfWeek(dayOfWeek.toInt()));
      }
      if (startTime != null && endTime != null) {
        metaParts.add('$startTime - $endTime');
      } else if (startTime != null) {
        metaParts.add(startTime.toString());
      }
      if (location != null && location.trim().isNotEmpty) {
        metaParts.add(location.trim());
      }
    } else if (isNote) {
      final tags = extraData?['tags'] as String?;
      if (tags != null && tags.trim().isNotEmpty) {
        metaParts.add(tags.trim());
      }
    } else if (isBoard) {
      metaParts.add('Board');
    }

    // Leading widget
    Widget leadingWidget;
    if (isTask) {
      leadingWidget = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTaskToggle,
        child: Container(
          width: 19,
          height: 19,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? successClr
                : isInProgress
                    ? inProgressClr.withValues(alpha: 0.15)
                    : Colors.transparent,
            border: Border.all(
              color: isCompleted
                  ? successClr
                  : isInProgress
                      ? inProgressClr
                      : borderStrong,
              width: isInProgress ? 2 : 1.5,
            ),
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : isInProgress
                  ? Icon(Icons.play_arrow_rounded, size: 12, color: inProgressClr)
                  : null,
        ),
      );
    } else {
      leadingWidget = Icon(
        isNote && widget.defaultIcon == Icons.calendar_today_outlined
            ? Icons.description_outlined
            : widget.defaultIcon,
        size: 14,
        color: activeBlue.withValues(alpha: 0.85),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _onEnterItem(context, isTask, isNote, isSchedule, isBoard, id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
              leadingWidget,
              const SizedBox(width: 7),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
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
                        color: isCompleted ? textSecondary : textPrimary,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: textSecondary,
                      ),
                    ),
                    if (metaParts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          metaParts.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 9,
                color: textSecondary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
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
                  context: rootNavigatorKey.currentContext ?? context,
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
                  context: rootNavigatorKey.currentContext ?? context,
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

class _CollapsibleActionTimeline extends StatefulWidget {
  final List<EpiTimelineStep> steps;
  final bool isWorking;
  final bool isDark;

  const _CollapsibleActionTimeline({
    required this.steps,
    required this.isWorking,
    required this.isDark,
  });

  @override
  State<_CollapsibleActionTimeline> createState() => _CollapsibleActionTimelineState();
}

class _CollapsibleActionTimelineState extends State<_CollapsibleActionTimeline> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final dullColor = widget.isDark
        ? EpicordiaColors.textTertiaryDark
        : EpicordiaColors.textTertiaryLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: 14,
                    color: dullColor.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Actions (${widget.steps.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dullColor.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(widget.steps.length, (index) {
                  final step = widget.steps[index];
                  final isLast = index == widget.steps.length - 1;
                  final isRunning = step.status == EpiTimelineStepStatus.running;
                  final isSuccess = step.status == EpiTimelineStepStatus.success;
                  final isCancelled = step.status == EpiTimelineStepStatus.cancelled;

                  final Color stepColor = isRunning
                      ? dullColor.withValues(alpha: 0.6)
                      : isSuccess
                          ? dullColor.withValues(alpha: 0.75)
                          : dullColor.withValues(alpha: 0.5);

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline track with dot/icon and connecting vertical line
                        SizedBox(
                          width: 14,
                          child: Column(
                            children: [
                              const SizedBox(height: 2),
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
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 1.2,
                                    margin: const EdgeInsets.symmetric(vertical: 2),
                                    color: dullColor.withValues(alpha: 0.25),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Timeline content
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 2 : 6),
                            child: Text(
                              step.title,
                              style: TextStyle(
                                fontSize: 12,
                                color: stepColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CopyMessageButton extends StatefulWidget {
  final String text;
  final Color color;
  final Color activeColor;

  const _CopyMessageButton({
    required this.text,
    required this.color,
    required this.activeColor,
  });

  @override
  State<_CopyMessageButton> createState() => _CopyMessageButtonState();
}

class _CopyMessageButtonState extends State<_CopyMessageButton> {
  bool _copied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleCopy() async {
    if (widget.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: widget.text));
    HapticFeedback.selectionClick();

    if (!mounted) return;
    setState(() => _copied = true);

    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });

    FeedbackService.showSuccess('Copied to clipboard', context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleCopy,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              _copied ? Remix.check_line : Remix.file_copy_line,
              key: ValueKey<bool>(_copied),
              size: 15,
              color: _copied ? (Colors.green[600] ?? widget.activeColor) : widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
