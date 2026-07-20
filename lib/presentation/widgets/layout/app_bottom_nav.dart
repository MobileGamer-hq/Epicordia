import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import 'navigation_item.dart';

/// 5-slot bottom nav: [Home] [Boards] [+Create] [Notes] [Tasks]
class AppBottomNav extends StatelessWidget {
  final VoidCallback? onCreateTap;
  const AppBottomNav({super.key, this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Container(
      decoration: const BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        border: Border(top: BorderSide(color: EpicordiaColors.borderSubtleLight)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              // Left 2: Home, Boards
              _NavItem(item: appNavItems[0], isActive: location == appNavItems[0].route),
              _NavItem(item: appNavItems[1], isActive: location == appNavItems[1].route),

              // Center: Create button (icon only)
              Expanded(
                child: GestureDetector(
                  onTap: onCreateTap,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: EpicordiaColors.blue600,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),

              // Right 2: Notes, Tasks
              _NavItem(item: appNavItems[2], isActive: location == appNavItems[2].route),
              _NavItem(item: appNavItems[3], isActive: location == appNavItems[3].route),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavigationItem item;
  final bool isActive;
  const _NavItem({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => context.go(item.route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 22,
              color: isActive ? EpicordiaColors.blue600 : EpicordiaColors.textTertiaryLight,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? EpicordiaColors.blue600 : EpicordiaColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
