import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// Clean, flat card matching the mockup style - adapts to Light & Dark theme
class EpicordiaCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? indicatorColor;
  final EdgeInsetsGeometry padding;

  const EpicordiaCard({
    super.key,
    required this.child,
    this.onTap,
    this.indicatorColor,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr =
        isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    Widget cardBody = Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderClr, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (indicatorColor != null)
                Container(width: 4, color: indicatorColor),
              Expanded(
                child: Padding(
                  padding: padding,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: cardBody,
        ),
      );
    }

    return cardBody;
  }
}
