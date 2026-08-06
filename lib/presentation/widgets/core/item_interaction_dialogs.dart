import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/utils/markdown_formatter.dart';
import '../../../data/database/database.dart';
import '../../../data/repository/task_repository.dart';
import '../../../data/repository/pin_repository.dart';
import '../../../data/providers.dart';
import '../../../domain/models/task_subitem.dart';
import '../edit_timetable_slot_dialog.dart';
import 'link_preview_dialog.dart';

class ItemInteractionDialogs {
  /// Displays a floating detail popup for a Note over a blurred background.
  static void showNoteDetailDialog({
    required BuildContext context,
    required WidgetRef ref,
    required PinEntity note,
    required String boardTitle,
  }) {
    final lines = (note.content ?? '').split('\n');
    final title = lines.isNotEmpty && lines[0].trim().isNotEmpty ? lines[0] : 'Untitled Note';
    final body = lines.length > 1 ? lines.sublist(1).join('\n').trim() : note.content ?? '';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Note Details',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
        final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
        final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
        final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
        final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
        final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderClr, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Badge & Close
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: activeBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.sticky_note_2_outlined, size: 14, color: activeBlue),
                                const SizedBox(width: 6),
                                Text(
                                  'NOTE PREVIEW',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: activeBlue,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, size: 20, color: textTertiary),
                            onPressed: () => Navigator.of(ctx).pop(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text.rich(
                        MarkdownFormatter.formatToTextSpan(
                          title,
                          baseStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                          activeBlue: activeBlue,
                          isTitle: true,
                          onLinkTap: (label, url) => LinkPreviewDialog.show(context, label, url),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Board & Modified Metadata
                      Row(
                        children: [
                          Icon(Icons.dashboard_outlined, size: 13, color: textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            boardTitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: activeBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.schedule, size: 13, color: textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(note.modifiedAt),
                            style: TextStyle(fontSize: 12, color: textTertiary),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Scrollable Note Content
                      Flexible(
                        child: SingleChildScrollView(
                          child: SelectionArea(
                            child: Text.rich(
                              MarkdownFormatter.formatToTextSpan(
                                body.isEmpty ? 'No additional content.' : body,
                                baseStyle: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: textSecondary,
                                ),
                                activeBlue: activeBlue,
                                onLinkTap: (label, url) => LinkPreviewDialog.show(context, label, url),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Action Toolbar
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceSunkenLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderClr),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _ActionButton(
                              icon: Icons.copy_rounded,
                              label: 'Copy',
                              onTap: () {
                                Navigator.of(ctx).pop();
                                copyToClipboard(context, '$title\n\n$body');
                              },
                            ),
                            _ActionButton(
                              icon: Icons.share_outlined,
                              label: 'Share',
                              onTap: () {
                                Navigator.of(ctx).pop();
                                shareContent(context, '$title\n\n$body');
                              },
                            ),
                            _ActionButton(
                              icon: Icons.edit_note_rounded,
                              label: 'Edit',
                              onTap: () {
                                Navigator.of(ctx).pop();
                                context.push('/note/${note.id}');
                              },
                            ),
                            _ActionButton(
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete',
                              color: EpicordiaColors.errorLight,
                              onTap: () async {
                                Navigator.of(ctx).pop();
                                final confirm = await _showDeleteConfirmDialog(context, 'Note');
                                if (confirm == true) {
                                  await ref.read(pinRepositoryProvider).deletePin(note.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Note deleted'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Displays a floating detail popup for a Task over a blurred background.
  static void showTaskDetailDialog({
    required BuildContext context,
    required WidgetRef ref,
    required TaskEntity task,
    required String boardTitle,
    required Color boardColor,
  }) {
    final isCompleted = task.status == 'done';
    final isInProgress = task.status == 'in_progress';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Task Details',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
        final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
        final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
        final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
        final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
        final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;
        final successClr = isDark ? EpicordiaColors.successDark : EpicordiaColors.successLight;
        final inProgressClr = const Color(0xFFF59E0B);

        final statusLabel = isCompleted
            ? 'COMPLETED'
            : isInProgress
                ? 'IN PROGRESS'
                : 'TO DO';

        final statusColor = isCompleted
            ? successClr
            : isInProgress
                ? inProgressClr
                : textTertiary;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderClr, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Badge & Close
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCompleted
                                      ? Icons.check_circle_outline
                                      : isInProgress
                                          ? Icons.pending_outlined
                                          : Icons.radio_button_unchecked,
                                  size: 13,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, size: 20, color: textTertiary),
                            onPressed: () => Navigator.of(ctx).pop(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: textTertiary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Metadata Rows
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.dashboard_outlined, size: 14, color: boardColor),
                              const SizedBox(width: 4),
                              Text(
                                boardTitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: boardColor,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_outlined, size: 14, color: textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                task.dueDate != null
                                    ? 'Due: ${_formatFullDateTime(task.dueDate!)}'
                                    : 'No due date',
                                style: TextStyle(fontSize: 12, color: textTertiary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          if (task.recurrenceRule != null && task.recurrenceRule!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.repeat_rounded, size: 14, color: activeBlue),
                                const SizedBox(width: 4),
                                Text(
                                  'Recurring: ${task.recurrenceRule}',
                                  style: TextStyle(fontSize: 12, color: activeBlue),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Notes & Subtask Checklist
                      Flexible(
                        child: SingleChildScrollView(
                          child: Builder(
                            builder: (ctx) {
                              final notesPayload = TaskSubitem.decodeNotes(task.notes);
                              final hasNotes = notesPayload.userNotes != null && notesPayload.userNotes!.trim().isNotEmpty;
                              final hasSubitems = notesPayload.hasSubitems;

                              if (!hasNotes && !hasSubitems) {
                                return Text(
                                  'No additional notes or subtasks provided.',
                                  style: TextStyle(fontSize: 14, color: textTertiary, fontStyle: FontStyle.italic),
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasNotes) ...[
                                    Text(
                                      'DESCRIPTION / NOTES',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: textTertiary,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SelectionArea(
                                      child: Text(
                                        notesPayload.userNotes!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (hasSubitems) ...[
                                    Row(
                                      children: [
                                        Text(
                                          'SUBTASKS (${notesPayload.completedCount}/${notesPayload.totalCount})',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: textTertiary,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: notesPayload.progress,
                                              minHeight: 5,
                                              backgroundColor: borderClr,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                notesPayload.allCompleted ? successClr : activeBlue,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...notesPayload.subitems.asMap().entries.map((entry) {
                                      final idx = entry.key;
                                      final sub = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 3),
                                        child: Row(
                                          children: [
                                            Icon(
                                              sub.isDone ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                              size: 18,
                                              color: sub.isDone ? successClr : textTertiary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                sub.title,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: sub.isDone ? textTertiary : textPrimary,
                                                  decoration: sub.isDone ? TextDecoration.lineThrough : null,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Toolbar
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceSunkenLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderClr),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _ActionButton(
                              icon: isCompleted ? Icons.undo_rounded : Icons.check_circle_outline,
                              label: isCompleted ? 'Reopen' : 'Complete',
                              color: statusColor,
                              onTap: () {
                                Navigator.of(ctx).pop();
                                final next = isCompleted ? 'todo' : 'done';
                                ref.read(taskRepositoryProvider).updateTask(task.copyWith(status: next));
                              },
                            ),
                            _ActionButton(
                              icon: Icons.copy_rounded,
                              label: 'Copy',
                              onTap: () {
                                Navigator.of(ctx).pop();
                                final decoded = TaskSubitem.decodeNotes(task.notes);
                                final subStr = decoded.hasSubitems
                                    ? '\nSubtasks:\n' + decoded.subitems.map((s) => '${s.isDone ? "[x]" : "[ ]"} ${s.title}').join('\n')
                                    : '';
                                final notesStr = decoded.userNotes != null ? '\nNotes: ${decoded.userNotes}' : '';
                                copyToClipboard(context, 'Task: ${task.title}\nStatus: $statusLabel$notesStr$subStr');
                              },
                            ),
                            _ActionButton(
                              icon: Icons.share_outlined,
                              label: 'Share',
                              onTap: () {
                                Navigator.of(ctx).pop();
                                final decoded = TaskSubitem.decodeNotes(task.notes);
                                final subStr = decoded.hasSubitems
                                    ? '\nSubtasks:\n' + decoded.subitems.map((s) => '${s.isDone ? "[x]" : "[ ]"} ${s.title}').join('\n')
                                    : '';
                                final notesStr = decoded.userNotes != null ? '\nNotes: ${decoded.userNotes}' : '';
                                shareContent(context, 'Task: ${task.title}\nStatus: $statusLabel$notesStr$subStr');
                              },
                            ),
                            _ActionButton(
                              icon: Icons.edit_outlined,
                              label: 'Edit',
                              onTap: () {
                                Navigator.of(ctx).pop();
                                context.push('/task/${task.id}');
                              },
                            ),
                            _ActionButton(
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete',
                              color: EpicordiaColors.errorLight,
                              onTap: () async {
                                Navigator.of(ctx).pop();
                                final confirm = await _showDeleteConfirmDialog(context, 'Task');
                                if (confirm == true) {
                                  await ref.read(taskRepositoryProvider).deleteTask(task.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Task deleted'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Displays a floating detail popup for a Schedule Slot over a blurred background.
  static void showScheduleDetailDialog({
    required BuildContext context,
    required WidgetRef ref,
    required TimetableSlotEntity slot,
  }) {
    const dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final dayName = (slot.dayOfWeek >= 1 && slot.dayOfWeek <= 7)
        ? dayNames[slot.dayOfWeek - 1]
        : 'Day ${slot.dayOfWeek}';

    Color accentColor = EpicordiaColors.blue600;
    if (slot.colorTag != null && slot.colorTag!.isNotEmpty) {
      try {
        accentColor = Color(int.parse(slot.colorTag!.replaceFirst('#', '0xff')));
      } catch (_) {}
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Schedule Details',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
        final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
        final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
        final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
        final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderClr, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Badge & Close
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  dayName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, size: 20, color: textTertiary),
                            onPressed: () => Navigator.of(ctx).pop(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        slot.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Time range & location
                      Row(
                        children: [
                          Icon(Icons.access_time_filled, size: 14, color: accentColor),
                          const SizedBox(width: 6),
                          Text(
                            '${slot.startTime} - ${slot.endTime}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      if (slot.location != null && slot.location!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: textTertiary),
                            const SizedBox(width: 6),
                            Text(
                              slot.location!,
                              style: TextStyle(fontSize: 13, color: textSecondary),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 24),

                      // Notes / description
                      Flexible(
                        child: SingleChildScrollView(
                          child: SelectionArea(
                            child: Text(
                              (slot.notes != null && slot.notes!.trim().isNotEmpty)
                                  ? slot.notes!
                                  : 'No additional details for this schedule event.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Toolbar
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceSunkenLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderClr),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _ActionButton(
                              icon: Icons.copy_rounded,
                              label: 'Copy',
                              onTap: () {
                                Navigator.of(ctx).pop();
                                copyToClipboard(context, '${slot.title}\nDay: $dayName\nTime: ${slot.startTime} - ${slot.endTime}\nLocation: ${slot.location ?? ''}');
                              },
                            ),
                            _ActionButton(
                              icon: Icons.share_outlined,
                              label: 'Share',
                              onTap: () {
                                Navigator.of(ctx).pop();
                                shareContent(context, '${slot.title}\nDay: $dayName\nTime: ${slot.startTime} - ${slot.endTime}\nLocation: ${slot.location ?? ''}');
                              },
                            ),
                            _ActionButton(
                              icon: Icons.edit_calendar_rounded,
                              label: 'Edit',
                              onTap: () {
                                Navigator.of(ctx).pop();
                                EditTimetableSlotDialog.show(context, slot: slot);
                              },
                            ),
                            _ActionButton(
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete',
                              color: EpicordiaColors.errorLight,
                              onTap: () async {
                                Navigator.of(ctx).pop();
                                final confirm = await _showDeleteConfirmDialog(context, 'Schedule event');
                                if (confirm == true) {
                                  await ref.read(timetableDaoProvider).deleteSlot(slot.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Schedule event deleted'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Displays a double-tap action menu modal sheet over a blurred background.
  static void showDoubleTapMenu({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<DoubleTapMenuItem> items,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Action Menu',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
        final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
        final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
        final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderClr, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => Navigator.of(ctx).pop(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 12, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Divider(height: 20),
                      Column(
                        children: items.map((item) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (item.color ?? textPrimary).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item.icon,
                                size: 18,
                                color: item.color ?? textPrimary,
                              ),
                            ),
                            title: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: item.color ?? textPrimary,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              item.onTap();
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Clipboard & Share helpers ──────────────────────────────
  static void copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Copied to clipboard!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  static void shareContent(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.share, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Content ready to share (copied to clipboard)!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  static Future<bool?> _showDeleteConfirmDialog(BuildContext context, String itemType) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $itemType'),
        content: Text('Are you sure you want to delete this $itemType? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: EpicordiaColors.errorLight),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String _formatFullDateTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)} at $hour:$minute $ampm';
  }
}

class DoubleTapMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  DoubleTapMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultClr = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final clr = color ?? defaultClr;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: clr),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: clr),
            ),
          ],
        ),
      ),
    );
  }
}
