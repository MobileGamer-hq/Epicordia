import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

/// The Epicordia brand logo widget: logo image + "Epicordia" in bold blue
class EpicordiaLogo extends StatelessWidget {
  final double size;
  const EpicordiaLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoColor = EpicordiaColors.blue500;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/Logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        Text(
          'Epicordia',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: logoColor,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// Standard Epicordia app bar with logo, search, and settings button
class EpicordiaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showSearch;
  final bool showAvatar;
  final bool showSettings;
  final VoidCallback? onSearch;
  final VoidCallback? onSettings;

  const EpicordiaAppBar({
    super.key,
    this.showSearch = true,
    this.showAvatar = true,
    this.showSettings = true,
    this.onSearch,
    this.onSettings,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final iconColor = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      titleSpacing: 20,
      title: const EpicordiaLogo(),
      actions: [
        if (showSearch)
          IconButton(
            icon: Icon(Icons.search, color: iconColor),
            onPressed: onSearch,
          ),
        if (showSettings)
          IconButton(
            icon: Icon(Icons.settings_outlined, color: iconColor),
            tooltip: 'Settings',
            onPressed: onSettings ?? () => context.push('/settings'),
          ),
      ],
    );
  }
}

/// Simple app bar with only a search icon (for Tasks, Notes screens)
class EpicordiaSimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSearch;

  const EpicordiaSimpleAppBar({super.key, this.onSearch});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      titleSpacing: 20,
      title: const EpicordiaLogo(),
    );
  }
}
