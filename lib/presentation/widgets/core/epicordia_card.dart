import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// Clean, flat card matching the mockup style - adapts to Light & Dark theme
class EpicordiaCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Color? indicatorColor;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;

  const EpicordiaCard({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.indicatorColor,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = backgroundColor ??
        (isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight);
    final borderClr =
        isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(16);

    Widget cardBody = Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: effectiveRadius,
        border: border ?? Border.all(color: borderClr, width: 1),
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
        borderRadius: effectiveRadius,
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

    if (onTap != null || onDoubleTap != null) {
      return GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap ?? onTap,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onDoubleTap: onDoubleTap ?? onTap,
            borderRadius: effectiveRadius as BorderRadius?,
            child: cardBody,
          ),
        ),
      );
    }

    return cardBody;
  }
}
