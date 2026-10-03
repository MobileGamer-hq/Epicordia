import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'theme.dart';

class FeedbackService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(
    String message, {
    Duration duration = const Duration(seconds: 2),
    BuildContext? context,
  }) {
    _showSnackBar(
      message: message,
      icon: Remix.checkbox_circle_fill,
      duration: duration,
      context: context,
    );
  }

  static void showError(
    String message, {
    Duration duration = const Duration(seconds: 2),
    BuildContext? context,
  }) {
    _showSnackBar(
      message: message,
      icon: Remix.error_warning_fill,
      duration: duration,
      context: context,
    );
  }

  static void showInfo(
    String message, {
    Duration duration = const Duration(seconds: 2),
    BuildContext? context,
  }) {
    _showSnackBar(
      message: message,
      icon: Remix.information_fill,
      duration: duration,
      context: context,
    );
  }

  static void showWarning(
    String message, {
    Duration duration = const Duration(seconds: 2),
    BuildContext? context,
  }) {
    _showSnackBar(
      message: message,
      icon: Remix.alert_fill,
      duration: duration,
      context: context,
    );
  }

  static void _showSnackBar({
    required String message,
    required IconData icon,
    Duration duration = const Duration(seconds: 2),
    BuildContext? context,
  }) {
    final messenger = (context != null ? ScaffoldMessenger.maybeOf(context) : null) ??
        messengerKey.currentState;

    final ctx = context ?? messengerKey.currentContext;
    final isDark = ctx != null
        ? (Theme.of(ctx).brightness == Brightness.dark)
        : false;

    // Use app scheme primary tint for the icon & accent badge
    final appAccent = ctx != null
        ? Theme.of(ctx).colorScheme.primary
        : (isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600);

    // Glass card background based on app card colors
    final cardBg = (isDark ? EpicordiaColors.surfaceCardDark : Colors.white)
        .withValues(alpha: isDark ? 0.82 : 0.88);
    final borderColor = (isDark
            ? EpicordiaColors.borderSubtleDark
            : EpicordiaColors.borderSubtleLight)
        .withValues(alpha: isDark ? 0.8 : 0.9);
    final textColor =
        isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;

    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: borderColor,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: appAccent.withValues(alpha: isDark ? 0.20 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: appAccent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
