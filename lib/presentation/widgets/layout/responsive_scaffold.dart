import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../layout/navigation_item.dart';
import '../core/epicordia_brand.dart';
import '../../screens/search_screen.dart';

/// Helper to trigger global search screen overlay
void _showSearchOverlay(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const EpicordiaSearchScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(0.0, -1.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.fastOutSlowIn));
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    ),
  );
}

/// Responsive Navigation Layout Scaffold
/// Desktop: Expandable sidebar (defaults expanded), NO app bar (>1024px)
/// Tablet:  Expandable sidebar (defaults compact rail), NO app bar (600–1024px)
/// Mobile:  Top app bar + Bottom nav bar (<600px)
class ResponsiveScaffold extends StatefulWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const ResponsiveScaffold({super.key, required this.child, this.appBar});

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  bool? _isSidebarExpanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final theme = Theme.of(context);

        // ── Mobile (<600px): Bottom navigation & Top AppBar ──────────
        if (w < 600) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: widget.appBar,
            body: SafeArea(child: SelectionArea(child: widget.child)),
            bottomNavigationBar: const _MobileBottomNav(),
          );
        }

        // ── Desktop & Tablet (>=600px): Expandable Sidebar + Main Content SafeArea
        final isDesktop = w >= 1024;
        final isExpanded = _isSidebarExpanded ?? isDesktop;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Row(
            children: [
              _ExpandableSidebar(
                isExpanded: isExpanded,
                onToggleExpand: () {
                  setState(() {
                    _isSidebarExpanded = !isExpanded;
                  });
                },
              ),
              Expanded(
                child: SafeArea(
                  top: true,
                  bottom: true,
                  left: false,
                  right: true,
                  child: SelectionArea(child: widget.child),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Expandable Sidebar / Rail (>=600px) ───────────────────────────────
class _ExpandableSidebar extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _ExpandableSidebar({
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sidebarBg = isDark
        ? EpicordiaColors.surfaceCardDark
        : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark
        ? EpicordiaColors.borderSubtleDark
        : EpicordiaColors.borderSubtleLight;
    final searchBg = isDark
        ? EpicordiaColors.surfaceSunkenDark
        : EpicordiaColors.surfaceSunkenLight;
    final textSecondary = isDark
        ? EpicordiaColors.textSecondaryDark
        : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark
        ? EpicordiaColors.textTertiaryDark
        : EpicordiaColors.textTertiaryLight;
    final textPrimary = isDark
        ? EpicordiaColors.textPrimaryDark
        : EpicordiaColors.textPrimaryLight;
    final userCardBg = isDark
        ? EpicordiaColors.surfaceSunkenDark
        : EpicordiaColors.surfaceSunkenLight;
    final userAvatarBg = isDark ? EpicordiaColors.blue900 : EpicordiaColors.blue100;
    final userAvatarIcon = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue700;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: isExpanded ? 230 : 70,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(color: borderClr, width: 1),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment:
              isExpanded ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            // ── Top Header (Logo + Toggle Button) ─────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                isExpanded ? 16 : 10,
                16,
                isExpanded ? 12 : 10,
                12,
              ),
              child: isExpanded
                  ? Row(
                      children: [
                        const EpicordiaLogo(size: 20),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.menu_open,
                            size: 20,
                            color: textSecondary,
                          ),
                          onPressed: onToggleExpand,
                          tooltip: 'Collapse Sidebar',
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: EpicordiaColors.blue700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.space_dashboard,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: Icon(
                            Icons.menu,
                            size: 20,
                            color: textSecondary,
                          ),
                          onPressed: onToggleExpand,
                          tooltip: 'Expand Sidebar',
                        ),
                      ],
                    ),
            ),

            // ── Search Action ─────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isExpanded ? 14 : 10,
                vertical: 4,
              ),
              child: isExpanded
                  ? InkWell(
                      onTap: () => _showSearchOverlay(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: searchBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: borderClr,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              size: 16,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Search...',
                              style: TextStyle(
                                fontSize: 13,
                                color: textTertiary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: borderClr,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(4)),
                              ),
                              child: Text(
                                '⌘K',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Tooltip(
                      message: 'Search (⌘K)',
                      child: InkWell(
                        onTap: () => _showSearchOverlay(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.search,
                            size: 22,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 12),

            // ── Section Divider / Label ───────────────────────────────
            if (isExpanded) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'WORKSPACE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textTertiary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ] else ...[
              Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
                color: borderClr,
              ),
              const SizedBox(height: 8),
            ],

            // ── Navigation Items List ──────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isExpanded ? 10 : 8),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: appNavItems.map((item) {
                    final isActive = location == item.route ||
                        (item.route != '/' &&
                            location.startsWith('${item.route}/'));
                    return _SidebarItem(
                      item: item,
                      isActive: isActive,
                      isExpanded: isExpanded,
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Create Button ──────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                isExpanded ? 14 : 10,
                8,
                isExpanded ? 14 : 10,
                16,
              ),
              child: isExpanded
                  ? InkWell(
                      onTap: () => context.push('/create'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: EpicordiaColors.blue600,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: EpicordiaColors.blue600
                                  .withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Create New',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Tooltip(
                      message: 'Create New',
                      child: InkWell(
                        onTap: () => context.push('/create'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: EpicordiaColors.blue600,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: EpicordiaColors.blue600
                                    .withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ),
            ),

            Divider(height: 1, color: borderClr),

            // ── Footer (Settings & User Profile) ───────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                isExpanded ? 12 : 8,
                12,
                isExpanded ? 12 : 8,
                16,
              ),
              child: Column(
                children: [
                  // Settings link
                  isExpanded
                      ? InkWell(
                          onTap: () => context.push('/settings'),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.settings_outlined,
                                  size: 18,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Settings',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Tooltip(
                          message: 'Settings',
                          child: InkWell(
                            onTap: () => context.push('/settings'),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                Icons.settings_outlined,
                                size: 22,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 6),
                  // User Profile info
                  isExpanded
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: userCardBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: userAvatarBg,
                                child: Icon(
                                  Icons.person,
                                  size: 16,
                                  color: userAvatarIcon,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Alex Rivera',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'alex@epicordia.io',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textTertiary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Tooltip(
                          message: 'Alex Rivera (alex@epicordia.io)',
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: userAvatarBg,
                            child: Icon(
                              Icons.person,
                              size: 18,
                              color: userAvatarIcon,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark
        ? EpicordiaColors.surfaceCardDark
        : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark
        ? EpicordiaColors.borderSubtleDark
        : EpicordiaColors.borderSubtleLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: borderClr),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
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
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: EpicordiaColors.blue600,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: EpicordiaColors.blue600
                                .withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTertiary = isDark
        ? EpicordiaColors.textTertiaryDark
        : EpicordiaColors.textTertiaryLight;
    final activeColor = isDark
        ? EpicordiaColors.blue300
        : EpicordiaColors.blue600;

    return Expanded(
      child: InkWell(
        onTap: () => context.go(item.route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 22,
              color: isActive ? activeColor : textTertiary,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sidebar Nav Item Widget ────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final NavigationItem item;
  final bool isActive;
  final bool isExpanded;

  const _SidebarItem({
    required this.item,
    required this.isActive,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark
        ? EpicordiaColors.blue300
        : EpicordiaColors.blue600;
    final activeBg = isDark
        ? EpicordiaColors.blue600.withValues(alpha: 0.2)
        : EpicordiaColors.blue600.withValues(alpha: 0.1);
    final textSecondary = isDark
        ? EpicordiaColors.textSecondaryDark
        : EpicordiaColors.textSecondaryLight;

    if (!isExpanded) {
      return Tooltip(
        message: item.label,
        child: InkWell(
          onTap: () => context.go(item.route),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.icon,
              size: 22,
              color: isActive ? activeColor : textSecondary,
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => context.go(item.route),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 20,
              color: isActive ? activeColor : textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive) ...[
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: activeColor,
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
