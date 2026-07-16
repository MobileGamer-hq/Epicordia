import 'package:flutter/material.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/epicordia_brand.dart';
import '../widgets/core/epicordia_card.dart';
import '../../core/theme.dart';

class TodayDashboard extends StatelessWidget {
  const TodayDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: const EpicordiaAppBar(),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── Activity Heatmap ─────────────────────────────────
          const _ActivityHeatmap(),
          const SizedBox(height: 28),

          // ── Unsorted Tray ───────────────────────────────────
          _SectionHeader(title: 'Unsorted Tray', actionLabel: 'View All', onAction: () {}),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _QuickCaptureCard(
                  category: 'QUICK CAPTURE',
                  title: 'Draft idea: Decentralized knowledge graphs',
                  preview: 'Exploration of how nodes... interact in a non-linear',
                ),
                SizedBox(width: 12),
                _QuickCaptureCard(
                  category: 'RECIPE',
                  title: 'Morning Coffee Recipe',
                  preview: null,
                  time: 'Added 2h ago',
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Today Tasks ─────────────────────────────────────
          _SectionHeader(title: 'Today', actionLabel: null, onAction: null),
          const SizedBox(height: 12),
          const _TodayTaskItem(title: 'Review Q3 Vision Board',    meta: 'Due 4:00 PM', isCompleted: false, isInProgress: false),
          const SizedBox(height: 8),
          const _TodayTaskItem(title: 'Update project timeline',   meta: 'Completed',   isCompleted: true,  isInProgress: true),
          const SizedBox(height: 8),
          const _TodayTaskItem(title: 'Call with Product Team',    meta: 'Due 6:30 PM', isCompleted: false, isInProgress: false),

          const SizedBox(height: 28),

          // ── Recent Boards ────────────────────────────────────
          _SectionHeader(title: 'Recent Boards', actionLabel: null, onAction: null),
          const SizedBox(height: 12),
          const _BoardCard(title: '2024 Product Launch',  meta: '14 items • Modified 10m ago', color: Color(0xFF8B9DC3)),
          const SizedBox(height: 12),
          const _BoardCard(title: 'Design System Sync',   meta: '32 items • Modified 1h ago',  color: Color(0xFFA8B4C8)),
          const SizedBox(height: 12),
          const _BoardCard(title: 'Inspiration Canvas',   meta: '8 items • Modified 3h ago',   color: Color(0xFF6B7FA0)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Activity Heatmap
// ────────────────────────────────────────────────────────────
class _ActivityHeatmap extends StatelessWidget {
  const _ActivityHeatmap();

  // 7 weeks × 7 days = 49 cells. 0=none, 1–4 = activity levels
  static final List<List<int>> _data = [
    [0, 1, 0, 2, 0, 1, 0],
    [1, 2, 3, 1, 0, 2, 1],
    [0, 1, 4, 3, 2, 1, 0],
    [2, 3, 2, 4, 3, 2, 1],
    [1, 0, 3, 2, 4, 3, 2],
    [0, 2, 1, 3, 2, 1, 0],
    [1, 1, 2, 1, 0, 2, 1],
  ];

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  Color _cellColor(int level) {
    switch (level) {
      case 1: return EpicordiaColors.blue200;
      case 2: return EpicordiaColors.blue300;
      case 3: return EpicordiaColors.blue400;
      case 4: return EpicordiaColors.blue500;
      default: return EpicordiaColors.borderSubtleLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Activity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryLight)),
            const Spacer(),
            _HeatmapLegend(),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels
            Column(
              children: _dayLabels.map((d) => SizedBox(
                height: 14,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(d, style: const TextStyle(fontSize: 9, color: EpicordiaColors.textTertiaryLight)),
                ),
              )).toList(),
            ),
            const SizedBox(width: 6),
            // Grid
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _data.map((week) {
                  return Column(
                    children: week.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200 + entry.key * 30),
                          width: double.infinity,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _cellColor(entry.value),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Less', style: TextStyle(fontSize: 9, color: EpicordiaColors.textTertiaryLight)),
        const SizedBox(width: 4),
        ...([EpicordiaColors.borderSubtleLight, EpicordiaColors.blue200, EpicordiaColors.blue300, EpicordiaColors.blue400, EpicordiaColors.blue500].map((c) =>
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
          ),
        )),
        const SizedBox(width: 4),
        const Text('More', style: TextStyle(fontSize: 9, color: EpicordiaColors.textTertiaryLight)),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// Section header
// ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: EpicordiaColors.blue600)),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// Quick capture card
// ────────────────────────────────────────────────────────────
class _QuickCaptureCard extends StatelessWidget {
  final String category;
  final String title;
  final String? preview;
  final String? time;

  const _QuickCaptureCard({required this.category, required this.title, this.preview, this.time});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: EpicordiaCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: EpicordiaColors.textTertiaryLight, letterSpacing: 0.8)),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
            if (preview != null) ...[
              const SizedBox(height: 8),
              Text(preview!, style: const TextStyle(fontSize: 11, color: EpicordiaColors.textTertiaryLight, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (time != null) ...[
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 11, color: EpicordiaColors.textTertiaryLight),
                  const SizedBox(width: 4),
                  Text(time!, style: const TextStyle(fontSize: 10, color: EpicordiaColors.textTertiaryLight)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Today task item
// ────────────────────────────────────────────────────────────
class _TodayTaskItem extends StatelessWidget {
  final String title;
  final String meta;
  final bool isCompleted;
  final bool isInProgress;

  const _TodayTaskItem({required this.title, required this.meta, required this.isCompleted, required this.isInProgress});

  @override
  Widget build(BuildContext context) {
    return EpicordiaCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isInProgress ? EpicordiaColors.blue600 : Colors.transparent,
              border: Border.all(
                color: isCompleted ? EpicordiaColors.blue600 : EpicordiaColors.borderStrongLight,
                width: 1.5,
              ),
            ),
            child: isCompleted ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: EpicordiaColors.textPrimaryLight,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: EpicordiaColors.textTertiaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(meta, style: const TextStyle(fontSize: 12, color: EpicordiaColors.textTertiaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Board card
// ────────────────────────────────────────────────────────────
class _BoardCard extends StatelessWidget {
  final String title;
  final String meta;
  final Color color;

  const _BoardCard({required this.title, required this.meta, required this.color});

  @override
  Widget build(BuildContext context) {
    return EpicordiaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Icon(Icons.dashboard_outlined, size: 36, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight)),
                const SizedBox(height: 2),
                Text(meta, style: const TextStyle(fontSize: 12, color: EpicordiaColors.textTertiaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
