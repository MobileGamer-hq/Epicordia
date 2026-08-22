import 'package:flutter/material.dart';

enum EpicordiaButtonType { primary, secondary, ghost, destructive }

class EpicordiaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final EpicordiaButtonType type;
  final IconData? icon;

  const EpicordiaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = EpicordiaButtonType.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (type) {
      case EpicordiaButtonType.primary:
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: _buildContent(),
        );
      case EpicordiaButtonType.secondary:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.textTheme.bodyLarge?.color,
            side: BorderSide(color: theme.dividerColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: _buildContent(),
        );
      case EpicordiaButtonType.ghost:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: theme.textTheme.bodySmall?.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: _buildContent(),
        );
      case EpicordiaButtonType.destructive:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(color: theme.colorScheme.error, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: _buildContent(),
        );
    }
  }

  Widget _buildContent() {
    if (icon == null) {
      return Text(label, style: const TextStyle(fontWeight: FontWeight.w600));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
