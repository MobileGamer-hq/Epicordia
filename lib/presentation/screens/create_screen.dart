import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

/// The type-selector "Create" screen — routes to Note / Task / Board creation
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        backgroundColor: bgApp,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        // title: const EpicordiaLogo(),
        // centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _CreateTypeCard(
                      icon: Icons.check_box_outlined,
                      iconColor: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600,
                      iconBg: isDark ? EpicordiaColors.blue900.withValues(alpha: 0.4) : EpicordiaColors.blue50,
                      title: 'To-do List',
                      description: 'Tasks, checklists, and scheduled to-dos.',
                      previewWidget: const _TaskPreview(),
                      onTap: () => context.push('/create/task'),
                    ),
                    const SizedBox(height: 16),
                    _CreateTypeCard(
                      icon: Icons.description_outlined,
                      iconColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF785A00),
                      iconBg: isDark ? const Color(0xFF423300) : const Color(0xFFFFF3CD),
                      title: 'Note',
                      description: 'Rich text notes and quick ideas.',
                      previewWidget: const _NotePreview(),
                      onTap: () => context.push('/create/note'),
                    ),
                    const SizedBox(height: 16),
                    _CreateTypeCard(
                      icon: Icons.space_dashboard_outlined,
                      iconColor: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue700,
                      iconBg: isDark ? EpicordiaColors.blue800.withValues(alpha: 0.4) : EpicordiaColors.blue100,
                      title: 'Board',
                      description: 'Canvas for visual workspace cards.',
                      previewWidget: const _BoardPreview(),
                      onTap: () => context.push('/create/board'),
                    ),
                    const SizedBox(height: 16),
                    _CreateTypeCard(
                      icon: Icons.alarm_outlined,
                      iconColor: isDark ? const Color(0xFFB388FF) : const Color(0xFF673AB7),
                      iconBg: isDark ? const Color(0xFF311B92).withValues(alpha: 0.5) : const Color(0xFFEDE7F6),
                      title: 'Alarm & Timer',
                      description: 'Wake-up alerts and countdown timers.',
                      previewWidget: const _AlarmPreview(),
                      onTap: () => context.push('/alarms?tab=alarms'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Type card ──────────────────────────────────────────────────────────
class _CreateTypeCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;
  final Widget previewWidget;
  final VoidCallback onTap;

  const _CreateTypeCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.previewWidget,
    required this.onTap,
  });

  @override
  State<_CreateTypeCard> createState() => _CreateTypeCardState();
}

class _CreateTypeCardState extends State<_CreateTypeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final activeBorder = isDark ? EpicordiaColors.blue400 : EpicordiaColors.blue600;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? activeBorder : borderSubtle,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? (isDark ? 0.25 : 0.08) : (isDark ? 0.15 : 0.03)),
                blurRadius: _hovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: widget.iconBg, borderRadius: BorderRadius.circular(8)),
                            child: Icon(widget.icon, size: 20, color: widget.iconColor),
                          ),
                          const SizedBox(width: 12),
                          Text(widget.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(widget.description, style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(width: 100, child: widget.previewWidget),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Preview thumbnails ─────────────────────────────────────────────────
class _TaskPreview extends StatelessWidget {
  const _TaskPreview();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sunkenBg = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: sunkenBg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: const [
          _PreviewTaskRow(done: false),
          SizedBox(height: 6),
          _PreviewTaskRow(done: false),
          SizedBox(height: 6),
          _PreviewTaskRow(done: true),
        ],
      ),
    );
  }
}

class _PreviewTaskRow extends StatelessWidget {
  final bool done;
  const _PreviewTaskRow({required this.done});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? EpicordiaColors.blue400 : EpicordiaColors.blue600;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderStrongLight;
    final activeBar = isDark ? EpicordiaColors.blue800 : EpicordiaColors.blue200;
    final inactiveBar = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? activeColor : Colors.transparent,
            border: Border.all(color: done ? activeColor : borderClr, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: done ? activeBar : inactiveBar,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotePreview extends StatelessWidget {
  const _NotePreview();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sunkenBg = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final barClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: sunkenBg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 8, width: 60, decoration: BoxDecoration(color: textPrimary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          Container(height: 6, decoration: BoxDecoration(color: barClr, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 4),
          Container(height: 6, width: 70, decoration: BoxDecoration(color: barClr, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 4),
          Container(height: 6, width: 50, decoration: BoxDecoration(color: barClr, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }
}

class _BoardPreview extends StatelessWidget {
  const _BoardPreview();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sunkenBg = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: sunkenBg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _MiniCard(),
          _MiniCard(),
          _MiniCard(),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    return Container(
      width: 24,
      height: 32,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderClr),
      ),
    );
  }
}

class _AlarmPreview extends StatelessWidget {
  const _AlarmPreview();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sunkenBg = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;
    final activeColor = isDark ? const Color(0xFFB388FF) : const Color(0xFF673AB7);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: sunkenBg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm, size: 22, color: activeColor),
          const SizedBox(height: 4),
          Text(
            '07:00 AM',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }
}

