import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/router.dart';
import '../../../domain/epi/floating_epi_chat_provider.dart';
import '../../screens/epi_chat_screen.dart';

/// Floating pop-up overlay for EpiChat on wider screens (tablets & desktop >= 600px).
/// Positioned at the bottom-right corner, smoothly transforms from a floating action
/// pill button into an interactive corner chat card while allowing full concurrent access
/// to the rest of the application.
class FloatingEpiChatOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const FloatingEpiChatOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<FloatingEpiChatOverlay> createState() => _FloatingEpiChatOverlayState();
}

class _FloatingEpiChatOverlayState extends ConsumerState<FloatingEpiChatOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curvedAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn.flipped,
    );
    _controller.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routerProvider).routerDelegate.addListener(_onRouteChanged);
    });
  }

  void _onRouteChanged() {
    if (mounted) {
      final currentRoute = ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path;
      if (currentRoute.startsWith('/epi')) {
        ref.read(floatingEpiChatProvider.notifier).collapse();
        _controller.value = 0.0;
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    ref.read(routerProvider).routerDelegate.removeListener(_onRouteChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Only display on wide screens (tablets, foldables, desktops >= 600px)
    if (screenWidth < 600) {
      return widget.child;
    }

    // Sync animation with provider state
    ref.listen<bool>(floatingEpiChatProvider, (prev, next) {
      if (next) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });

    // Check whether current route should hide the floating chat (e.g. Full screen epi, onboarding, focus)
    final router = ref.watch(routerProvider);
    final currentRoute = router.routerDelegate.currentConfiguration.uri.path;
    final shouldHide = currentRoute.startsWith('/epi') ||
        currentRoute == '/onboarding' ||
        currentRoute.endsWith('/focus');

    if (shouldHide) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? EpicordiaColors.surfaceCardDark
        : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark
        ? EpicordiaColors.borderSubtleDark
        : EpicordiaColors.borderSubtleLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    final t = _curvedAnimation.value;

    const collapsedWidth = 136.0;
    const collapsedHeight = 48.0;
    const collapsedRadius = 24.0;

    final targetWidth = math.min(410.0, screenWidth - 36.0);
    final availableHeight = screenHeight - mediaQuery.viewInsets.bottom - 48.0;
    final targetHeight = math.min(600.0, math.max(380.0, availableHeight));
    const targetRadius = 16.0;

    final currentWidth = ui.lerpDouble(collapsedWidth, targetWidth, t)!;
    final currentHeight = ui.lerpDouble(collapsedHeight, targetHeight, t)!;
    final currentRadius = ui.lerpDouble(collapsedRadius, targetRadius, t)!;

    final containerBg = Color.lerp(
      activeBlue,
      cardBg,
      (t * 1.6).clamp(0.0, 1.0),
    )!;

    final currentBorderColor = Color.lerp(
      Colors.white.withValues(alpha: 0.3),
      borderClr,
      t,
    )!;

    final currentShadow = [
      BoxShadow(
        color: Color.lerp(
          activeBlue.withValues(alpha: 0.4),
          Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
          t,
        )!,
        blurRadius: ui.lerpDouble(12.0, 28.0, t)!,
        spreadRadius: ui.lerpDouble(0.0, 1.0, t)!,
        offset: Offset(0, ui.lerpDouble(4.0, 8.0, t)!),
      ),
    ];

    final bottomOffset = 24.0 + mediaQuery.viewInsets.bottom;
    const rightOffset = 24.0;

    return Stack(
      children: [
        // Base application is fully interactive and unaffected
        widget.child,

        // Floating interactive corner chat widget
        Positioned(
          bottom: bottomOffset,
          right: rightOffset,
          width: currentWidth,
          height: currentHeight,
          child: Container(
            decoration: BoxDecoration(
              color: containerBg,
              borderRadius: BorderRadius.circular(currentRadius),
              border: Border.all(color: currentBorderColor, width: 1.2),
              boxShadow: currentShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(currentRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Collapsed Pill Button Content ──
                  if (t < 0.4)
                    IgnorePointer(
                      ignoring: t > 0.1,
                      child: Opacity(
                        opacity: (1.0 - t / 0.35).clamp(0.0, 1.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              ref.read(floatingEpiChatProvider.notifier).expand();
                            },
                            borderRadius: BorderRadius.circular(currentRadius),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Ask Epi',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF34D399),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── Expanded Corner Chat Content ──
                  if (t > 0.05)
                    IgnorePointer(
                      ignoring: t < 0.7,
                      child: Opacity(
                        opacity: ((t - 0.2) / 0.8).clamp(0.0, 1.0),
                        child: OverflowBox(
                          minWidth: targetWidth,
                          maxWidth: targetWidth,
                          minHeight: targetHeight,
                          maxHeight: targetHeight,
                          alignment: Alignment.bottomRight,
                          child: SizedBox(
                            width: targetWidth,
                            height: targetHeight,
                            child: Overlay(
                              initialEntries: [
                                OverlayEntry(
                                  builder: (overlayContext) => EpiChatScreen(
                                    isEmbedded: true,
                                    onClose: () {
                                      ref
                                          .read(floatingEpiChatProvider.notifier)
                                          .collapse();
                                    },
                                    onExpand: () {
                                      ref
                                          .read(floatingEpiChatProvider.notifier)
                                          .collapse();
                                      ref.read(routerProvider).push('/epi');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
