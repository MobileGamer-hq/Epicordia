import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// The Epicordia brand logo widget: grid icon + "Epicordia" in bold blue
class EpicordiaLogo extends StatelessWidget {
  final double size;
  const EpicordiaLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GridIcon(size: size),
        const SizedBox(width: 8),
        Text(
          'Epicordia',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: EpicordiaColors.blue700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _GridIcon extends StatelessWidget {
  final double size;
  const _GridIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GridPainter()),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EpicordiaColors.blue700
      ..style = PaintingStyle.fill;

    final r = size.width * 0.22;
    final gap = size.width * 0.06;
    final step = r * 2 + gap;

    // 2x2 grid of rounded squares
    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 2; col++) {
        final x = col * step;
        final y = row * step;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, r * 2, r * 2),
            Radius.circular(r * 0.4),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        if (showAvatar) ...[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: EpicordiaColors.blue100,
              child: const Icon(Icons.person, size: 18, color: EpicordiaColors.blue700),
            ),
          ),
        ],
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
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: EpicordiaColors.textPrimaryLight),
          onPressed: onSearch,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
