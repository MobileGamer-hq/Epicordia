import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_lock_provider.dart';
import '../screens/pin_lock_screen.dart';

class AppLockWrapper extends ConsumerWidget {
  final Widget child;

  const AppLockWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(appLockProvider);

    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Stack(
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        children: [
          child,
          if (lockState.isLocked)
            Positioned.fill(
              child: Material(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: const PinLockScreen(mode: PinLockMode.unlock),
              ),
            ),
        ],
      ),
    );
  }
}
