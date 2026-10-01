import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../domain/epi/proactive_checkin_provider.dart';

class ProactiveCheckinCard extends ConsumerWidget {
  const ProactiveCheckinCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appPrimaryColorProvider);
    final checkinState = ref.watch(proactiveCheckinProvider);
    if (!checkinState.shouldShow) {
      return const SizedBox.shrink();
    }

    final result = checkinState.result!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final activePrimary = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderClr),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with subtle check-in label and dismiss button
          Row(
            children: [
              Text(
                "Epi's Check-in",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: activePrimary,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  ref.read(proactiveCheckinProvider.notifier).dismiss();
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Check-in Message
          Text(
            result.message,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),

          // Action Button
          _ActionButton(
            label: 'Chat with Epi',
            icon: Icons.auto_awesome,
            activePrimary: activePrimary,
            onTap: () {
              ref.read(proactiveCheckinProvider.notifier).dismiss();
              context.push('/epi', extra: {
                'prompt': "Hey Epi, let's talk about what's on my radar today.",
              });
            },
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color activePrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.activePrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: activePrimary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
