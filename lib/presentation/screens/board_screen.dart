import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/core/epicordia_brand.dart';
import '../../core/theme.dart';

class BoardScreen extends StatefulWidget {
  final String boardId;
  const BoardScreen({super.key, required this.boardId});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  String _viewMode = 'Canvas';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEDE9), // warm canvas background
      appBar: _BoardAppBar(boardId: widget.boardId),
      body: Column(
        children: [
          // View mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _ViewToggle(
                  selected: _viewMode,
                  options: const ['Canvas', 'List', 'Focus'],
                  onSelect: (v) => setState(() => _viewMode = v),
                ),
              ],
            ),
          ),
          // Unsorted banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5A030).withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 16, color: Color(0xFFB5730A)),
                  SizedBox(width: 8),
                  Text('4 items unsorted', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFB5730A))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Canvas area with left toolbar
          Expanded(
            child: Stack(
              children: [
                // Canvas background
                const _CanvasArea(),
                // Left toolbar
                Positioned(
                  left: 12,
                  top: 20,
                  child: _CanvasToolbar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── App bar with breadcrumb ───────────────────────────────────────────
class _BoardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String boardId;
  const _BoardAppBar({required this.boardId});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EpicordiaColors.surfaceAppLight,
      elevation: 0,
      leadingWidth: 160,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: EpicordiaLogo(size: 16),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => context.go('/boards'),
              child: const Text('Home', style: TextStyle(fontSize: 13, color: EpicordiaColors.textSecondaryLight)),
            ),
            const Icon(Icons.chevron_right, size: 14, color: EpicordiaColors.textTertiaryLight),
            const Text('Project Alpha', style: TextStyle(fontSize: 13, color: EpicordiaColors.textSecondaryLight)),
          ],
        ),
      ),
      title: Text(
        'Product Vision',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: EpicordiaColors.blue700),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_outlined, color: EpicordiaColors.textPrimaryLight), onPressed: () {}),
        IconButton(icon: const Icon(Icons.settings_outlined, color: EpicordiaColors.textPrimaryLight), onPressed: () {}),
      ],
    );
  }
}

// ── View mode toggle ─────────────────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  final String selected;
  final List<String> options;
  final ValueChanged<String> onSelect;
  const _ViewToggle({required this.selected, required this.options, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EpicordiaColors.borderSubtleLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isActive = opt == selected;
          return GestureDetector(
            onTap: () => onSelect(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? EpicordiaColors.blue700 : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : EpicordiaColors.textSecondaryLight,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Canvas area (placeholder) ─────────────────────────────────────────
class _CanvasArea extends StatelessWidget {
  const _CanvasArea();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFFEEEDE9),
        child: Stack(
          children: [
            // A sample note card drifting in the canvas
            Positioned(
              right: 20,
              top: 40,
              child: _CanvasCard(
                header: 'CONCEPT NOTE',
                title: 'UX Research Needs',
                body: 'Defining the core needs of our end-users...\nWe need to identify what works and what doesn\'t work.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanvasCard extends StatelessWidget {
  final String header;
  final String title;
  final String body;
  const _CanvasCard({required this.header, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EpicordiaColors.borderSubtleLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(header, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: EpicordiaColors.textTertiaryLight, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 11, color: EpicordiaColors.textSecondaryLight, height: 1.4)),
        ],
      ),
    );
  }
}

// ── Canvas toolbar ────────────────────────────────────────────────────
class _CanvasToolbar extends StatelessWidget {
  final _tools = const [
    (Icons.sticky_note_2_outlined, false),
    (Icons.check_circle_outline, false),
    (Icons.link, false),
    (Icons.image_outlined, false),
    (Icons.draw_outlined, false),
    (Icons.show_chart, false),
    (Icons.crop_free, false),
    (Icons.delete_outline, true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(_tools.length, (i) {
            final (icon, isDanger) = _tools[i];
            final showDivider = i == 4; // divider before draw tools
            return Column(
              children: [
                if (showDivider) const Divider(height: 1, thickness: 1, color: EpicordiaColors.borderSubtleLight),
                _ToolButton(icon: icon, isDanger: isDanger),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final bool isDanger;
  const _ToolButton({required this.icon, this.isDanger = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, size: 20, color: isDanger ? EpicordiaColors.errorLight : EpicordiaColors.textSecondaryLight),
      ),
    );
  }
}
