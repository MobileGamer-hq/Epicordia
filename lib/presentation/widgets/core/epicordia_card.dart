import 'package:flutter/material.dart';

class EpicordiaCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? indicatorColor;

  const EpicordiaCard({
    super.key,
    required this.child,
    this.onTap,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget content = Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (indicatorColor != null)
              Container(
                width: 4,
                color: indicatorColor,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }
    
    return content;
  }
}
