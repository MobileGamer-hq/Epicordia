import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

/// The type-selector "Create" screen — routes to Note / Task / Board creation
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EpicordiaColors.surfaceAppLight,
      appBar: AppBar(
        backgroundColor: EpicordiaColors.surfaceAppLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: EpicordiaColors.textPrimaryLight),
          onPressed: () => context.pop(),
        ),
        // title: const EpicordiaLogo(),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What would you\nlike to create?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: EpicordiaColors.textPrimaryLight,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a type to get started.',
                style: TextStyle(fontSize: 14, color: EpicordiaColors.textSecondaryLight),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Column(
                  children: [
                    _CreateTypeCard(
                      icon: Icons.check_box_outlined,
                      iconColor: EpicordiaColors.blue600,
                      iconBg: EpicordiaColors.blue50,
                      title: 'To-do List',
                      description: 'A structured list of tasks. Best for planning work, tracking checklists, and managing daily to-dos.',
                      previewWidget: const _TaskPreview(),
                      onTap: () => context.push('/create/task'),
                    ),
                    const SizedBox(height: 16),
                    _CreateTypeCard(
                      icon: Icons.description_outlined,
                      iconColor: const Color(0xFF785A00),
                      iconBg: const Color(0xFFFFF3CD),
                      title: 'Note',
                      description: 'Rich text notes and quick captures. Best for journaling, ideas, and meeting notes.',
                      previewWidget: const _NotePreview(),
                      onTap: () => context.push('/create/note'),
                    ),
                    const SizedBox(height: 16),
                    _CreateTypeCard(
                      icon: Icons.space_dashboard_outlined,
                      iconColor: EpicordiaColors.blue700,
                      iconBg: EpicordiaColors.blue100,
                      title: 'Board',
                      description: 'A visual, infinite canvas for spatial organization. Best for moodboarding, complex projects, and brainstorming.',
                      previewWidget: const _BoardPreview(),
                      onTap: () => context.push('/create/board'),
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: EpicordiaColors.surfaceCardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? EpicordiaColors.blue600 : EpicordiaColors.borderSubtleLight,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.08 : 0.03),
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
                          Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(widget.description, style: const TextStyle(fontSize: 13, color: EpicordiaColors.textSecondaryLight, height: 1.4)),
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: EpicordiaColors.surfaceSunkenLight, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          _PreviewTaskRow(done: false),
          const SizedBox(height: 6),
          _PreviewTaskRow(done: false),
          const SizedBox(height: 6),
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
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? EpicordiaColors.blue600 : Colors.transparent,
            border: Border.all(color: done ? EpicordiaColors.blue600 : EpicordiaColors.borderStrongLight, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: done ? EpicordiaColors.blue200 : EpicordiaColors.borderSubtleLight,
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: EpicordiaColors.surfaceSunkenLight, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 8, width: 60, decoration: BoxDecoration(color: EpicordiaColors.textPrimaryLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          Container(height: 6, decoration: BoxDecoration(color: EpicordiaColors.borderSubtleLight, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 4),
          Container(height: 6, width: 70, decoration: BoxDecoration(color: EpicordiaColors.borderSubtleLight, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 4),
          Container(height: 6, width: 50, decoration: BoxDecoration(color: EpicordiaColors.borderSubtleLight, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }
}

class _BoardPreview extends StatelessWidget {
  const _BoardPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: EpicordiaColors.surfaceSunkenLight, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MiniCard(),
          _MiniCard(),
          _MiniCard(),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 32,
      decoration: BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: EpicordiaColors.borderSubtleLight),
      ),
    );
  }
}
