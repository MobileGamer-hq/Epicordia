import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../domain/epi/proactive_checkin_provider.dart';

class ProactiveCheckinCard extends ConsumerWidget {
  const ProactiveCheckinCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinState = ref.watch(proactiveCheckinProvider);
    if (!checkinState.shouldShow) {
      return const SizedBox.shrink();
    }

    final result = checkinState.result!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark
        ? const Color(0xFF1E232A)
        : const Color(0xFFF0F5FA);
    final borderClr = isDark
        ? const Color(0xFF2C3540)
        : const Color(0xFFD6E2EE);
    final textPrimary = isDark
        ? EpicordiaColors.textPrimaryDark
        : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark
        ? EpicordiaColors.textSecondaryDark
        : EpicordiaColors.textSecondaryLight;
    final accentTeal = isDark ? Colors.tealAccent.shade200 : Colors.teal.shade700;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderClr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Epi badge and dismiss button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentTeal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: accentTeal,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Epi's Check-in",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accentTeal,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  ref.read(proactiveCheckinProvider.notifier).dismiss();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Check-in Message
          Text(
            result.message,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),

          // Action Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _ActionChip(
                label: 'Chat with Epi',
                icon: Icons.chat_bubble_outline_rounded,
                isPrimary: true,
                onTap: () {
                  ref.read(proactiveCheckinProvider.notifier).dismiss();
                  context.push('/epi', extra: {
                    'prompt': "Hey Epi, let's talk about what's on my radar today.",
                  });
                },
              ),
              _ActionChip(
                label: 'View Tasks',
                icon: Icons.checklist_rounded,
                isPrimary: false,
                onTap: () {
                  ref.read(proactiveCheckinProvider.notifier).dismiss();
                  context.push('/tasks');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBg = isDark ? Colors.teal.shade700 : Colors.teal.shade600;
    final secondaryBg = isDark ? const Color(0xFF262D35) : const Color(0xFFE2EBF4);
    final secondaryText = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;

    return Material(
      color: isPrimary ? primaryBg : secondaryBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isPrimary ? Colors.white : secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
