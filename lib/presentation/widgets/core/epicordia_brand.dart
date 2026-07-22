import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// The Epicordia brand logo widget: logo image + "Epicordia" in bold blue
class EpicordiaLogo extends StatelessWidget {
  final double size;
  const EpicordiaLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
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
            color: EpicordiaColors.blue500,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}




/// Standard Epicordia app bar with logo, search, and optional avatar
class EpicordiaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showSearch;
  final bool showAvatar;
  final VoidCallback? onSearch;

  const EpicordiaAppBar({
    super.key,
    this.showSearch = true,
    this.showAvatar = true,
    this.onSearch,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EpicordiaColors.surfaceAppLight,
      elevation: 0,
      titleSpacing: 20,
      title: const EpicordiaLogo(),
      actions: [
        if (showSearch)
          IconButton(
            icon: const Icon(Icons.search, color: EpicordiaColors.textPrimaryLight),
            onPressed: onSearch,
          ),
        // if (showAvatar) ...[
        //   Padding(
        //     padding: const EdgeInsets.only(right: 16),
        //     child: CircleAvatar(
        //       radius: 16,
        //       backgroundColor: EpicordiaColors.blue100,
        //       child: const Icon(Icons.person, size: 18, color: EpicordiaColors.blue700),
        //     ),
        //   ),
        // ],
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
    return AppBar(
      backgroundColor: EpicordiaColors.surfaceAppLight,
      elevation: 0,
      titleSpacing: 20,
      title: const EpicordiaLogo(),
      // actions: [
      //   IconButton(
      //     icon: const Icon(Icons.settings, color: EpicordiaColors.textPrimaryLight),
      //     onPressed: onSearch,
      //   ),
      //   const SizedBox(width: 8),
      // ],
    );
  }
}
