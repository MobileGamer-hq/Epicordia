import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../layout/navigation_item.dart';
import '../core/epicordia_brand.dart';

/// Desktop: full labeled sidebar (>1024px)
/// Tablet:  icon-only rail (600–1024px)
/// Mobile:  bottom nav bar (<600px)
class ResponsiveScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const ResponsiveScaffold({super.key, required this.child, this.appBar});

  @override
  Widget build(BuildContext context) {
    // Wrap in SelectionArea so all text is selectable
    final content = SelectionArea(child: child);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        if (w >= 1024) {
          // ── Desktop: persistent full sidebar ──────────────────
          return Scaffold(
            backgroundColor: EpicordiaColors.surfaceAppLight,
            appBar: appBar,
            body: Row(
              children: [
                const _DesktopSidebar(),
                Expanded(child: content),
              ],
            ),
          );
        }

        if (w >= 600) {
          // ── Tablet: icon rail ─────────────────────────────────
          return Scaffold(
            backgroundColor: EpicordiaColors.surfaceAppLight,
            appBar: appBar,
            body: Row(
              children: [
                const _TabletRail(),
                Expanded(child: content),
              ],
            ),
          );
        }

        // ── Mobile: bottom nav ────────────────────────────────
        return Scaffold(
          backgroundColor: EpicordiaColors.surfaceAppLight,
          appBar: appBar,
          body: SafeArea(child: content),
          bottomNavigationBar: const _MobileBottomNav(),
        );
      },
    );
  }
}

// ── Desktop sidebar (>1024px) ─────────────────────────────────────────
class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        border: Border(
          right: BorderSide(color: EpicordiaColors.borderSubtleLight),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(children: const [EpicordiaLogoInline()]),
          ),

          // Nav items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: appNavItems.map((item) {
                  final isActive =
                      location == item.route ||
                      location.startsWith('${item.route}/');
                  return _SidebarItem(item: item, isActive: isActive);
                }).toList(),
              ),
            ),
          ),

          // Create button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: InkWell(
              onTap: () => context.push('/create'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: EpicordiaColors.blue600,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Create',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider + User + Settings
          const Divider(height: 1, color: EpicordiaColors.borderSubtleLight),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            child: Column(
              children: [
                // Settings link
                InkWell(
                  onTap: () => context.push('/settings'),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          size: 18,
                          color: EpicordiaColors.textSecondaryLight,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 14,
                            color: EpicordiaColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // User row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: EpicordiaColors.blue100,
                      child: const Icon(
                        Icons.person,
                        size: 18,
                        color: EpicordiaColors.blue700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alex Rivera',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: EpicordiaColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            'alex@epicordia.io',
                            style: TextStyle(
                              fontSize: 11,
                              color: EpicordiaColors.textTertiaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tablet icon rail (600–1024px) ─────────────────────────────────────
class _TabletRail extends StatelessWidget {
  const _TabletRail();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: 68,
      decoration: const BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        border: Border(
          right: BorderSide(color: EpicordiaColors.borderSubtleLight),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: EpicordiaColors.blue700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.space_dashboard,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 20),
          // Nav icons
          Expanded(
            child: Column(
              children: appNavItems.map((item) {
                final isActive = location == item.route;
                return Tooltip(
                  message: item.label,
                  child: InkWell(
                    onTap: () => context.go(item.route),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? EpicordiaColors.blue600.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        size: 22,
                        color: isActive
                            ? EpicordiaColors.blue600
                            : EpicordiaColors.textSecondaryLight,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Create FAB
          Tooltip(
            message: 'Create',
            child: InkWell(
              onTap: () => context.push('/create'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.all(10),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: EpicordiaColors.blue600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ),
          // Settings
          Tooltip(
            message: 'Settings',
            child: InkWell(
              onTap: () => context.push('/settings'),
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.settings_outlined,
                  size: 22,
                  color: EpicordiaColors.textSecondaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Mobile bottom nav (<600px) ────────────────────────────────────────
class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Container(
      decoration: const BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        border: Border(
          top: BorderSide(color: EpicordiaColors.borderSubtleLight),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              // Home, Boards
              _BottomNavItem(
                item: appNavItems[0],
                isActive: location == appNavItems[0].route,
              ),
              _BottomNavItem(
                item: appNavItems[1],
                isActive: location == appNavItems[1].route,
              ),

              // Center Create button (icon only)
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/create'),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: EpicordiaColors.blue600,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

              // Notes, Tasks
              _BottomNavItem(
                item: appNavItems[2],
                isActive: location == appNavItems[2].route,
              ),
              _BottomNavItem(
                item: appNavItems[3],
                isActive: location == appNavItems[3].route,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final NavigationItem item;
  final bool isActive;
  const _BottomNavItem({required this.item, required this.isActive});

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
              color: isActive
                  ? EpicordiaColors.blue600
                  : EpicordiaColors.textTertiaryLight,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? EpicordiaColors.blue600
                    : EpicordiaColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sidebar nav item ──────────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final NavigationItem item;
  final bool isActive;
  const _SidebarItem({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(item.route),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? EpicordiaColors.blue600.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isActive
                  ? EpicordiaColors.blue600
                  : EpicordiaColors.textSecondaryLight,
            ),
            const SizedBox(width: 10),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? EpicordiaColors.blue600
                    : EpicordiaColors.textSecondaryLight,
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: EpicordiaColors.blue600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Inline logo for sidebar ───────────────────────────────────────────
class EpicordiaLogoInline extends StatelessWidget {
  const EpicordiaLogoInline({super.key});

  @override
  Widget build(BuildContext context) {
    return const EpicordiaLogo(size: 18);
  }
}
