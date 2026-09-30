import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'theme.dart';

class FeedbackService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static Color _getAppTint([BuildContext? context]) {
    final ctx = context ?? messengerKey.currentContext;
    if (ctx != null) {
      return Theme.of(ctx).colorScheme.primary;
    }
    return EpicordiaColors.blue600;
  }

  static void showSuccess(
    String message, {
    Duration duration = const Duration(seconds: 2),
    BuildContext? context,
  }) {
    _showSnackBar(
      message: message,
      icon: Remix.checkbox_circle_fill,
      backgroundColor: _getAppTint(context),
      iconColor: Colors.white,
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
      backgroundColor: _getAppTint(context),
      iconColor: Colors.white,
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
      backgroundColor: _getAppTint(context),
      iconColor: Colors.white,
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
      backgroundColor: _getAppTint(context),
      iconColor: Colors.white,
      duration: duration,
      context: context,
    );
  }

  static void _showSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    Duration duration = const Duration(seconds: 2),
    BuildContext? context,
  }) {
    final messenger = (context != null ? ScaffoldMessenger.maybeOf(context) : null) ??
        messengerKey.currentState;

    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}
