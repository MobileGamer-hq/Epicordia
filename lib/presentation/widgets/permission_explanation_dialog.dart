import 'package:epicordia/core/theme.dart';
import 'package:flutter/material.dart';

class PermissionExplanationDialog extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onContinue;

  const PermissionExplanationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onContinue,
  });

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PermissionExplanationDialog(
        title: title,
        description: description,
        icon: icon,
        onContinue: () => Navigator.of(ctx).pop(true),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final frontBlue = isDark ? EpicordiaColors.blue200 : EpicordiaColors.blue500;
    final backBlue = isDark ? EpicordiaColors.blue600  : EpicordiaColors.blue200;
    final text = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;



    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // radius-l
      ),
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: backBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: frontBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999), // pill
                      ),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Not Now', style: TextStyle(
                      color: text
                    ),),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999), // pill
                      ),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: onContinue,
                    child:  Text('Continue', style: TextStyle(
                        color:Colors.white
                    ),),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
