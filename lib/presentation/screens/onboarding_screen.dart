import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../widgets/core/epicordia_brand.dart';

/// First-run onboarding: "How would you like to start?"
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _selected; // 'boards' or 'lists'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EpicordiaColors.surfaceAppLight,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo mark
                    const EpicordiaLogo(size: 20),
                    const SizedBox(height: 32),
                    // Headline
                    const Text(
                      'How would you\nlike to start?',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: EpicordiaColors.textPrimaryLight, height: 1.2, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose a workflow that fits your thinking style. You can change this later at any time.',
                      style: TextStyle(fontSize: 14, color: EpicordiaColors.textSecondaryLight, height: 1.5),
                    ),
                    const SizedBox(height: 28),

                    // Boards option
                    _WorkflowCard(
                      id: 'boards',
                      selected: _selected == 'boards',
                      onTap: () => setState(() => _selected = 'boards'),
                      icon: Icons.space_dashboard_outlined,
                      iconBg: EpicordiaColors.blue100,
                      iconColor: EpicordiaColors.blue700,
                      title: 'Boards',
                      description: 'A visual, infinite canvas for spatial organization. Best for moodboarding, complex projects, and brainstorming.',
                      preview: const _BoardsPreview(),
                    ),

                    const SizedBox(height: 16),

                    // Lists option
                    _WorkflowCard(
                      id: 'lists',
                      selected: _selected == 'lists',
                      onTap: () => setState(() => _selected = 'lists'),
                      icon: Icons.description_outlined,
                      iconBg: const Color(0xFFFFF3CD),
                      iconColor: const Color(0xFF785A00),
                      title: 'Lists',
                      description: 'Structured notes and sequential tasks. Best for rapid capturing, journaling, and daily to-do management.',
                      preview: const _ListsPreview(),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // App Lock button
                  GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('onboarding_complete', true);
                      if (context.mounted) context.go('/');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: EpicordiaColors.surfaceCardLight,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: EpicordiaColors.blue600, width: 2),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, color: EpicordiaColors.blue600, size: 20),
                          SizedBox(width: 10),
                          Text('Set up App Lock', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: EpicordiaColors.blue600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Privacy-first. Your data never leaves your device without permission.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: EpicordiaColors.textTertiaryLight, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  // Skip / Continue
                  GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('onboarding_complete', true);
                      if (context.mounted) context.go('/');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: EpicordiaColors.blue600,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
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

// ── Workflow option card ──────────────────────────────────────────────
class _WorkflowCard extends StatelessWidget {
  final String id;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final Widget preview;

  const _WorkflowCard({
    required this.id,
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: EpicordiaColors.surfaceCardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? EpicordiaColors.blue600 : EpicordiaColors.borderSubtleLight,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const Spacer(),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? EpicordiaColors.blue600 : Colors.transparent,
                    border: Border.all(color: selected ? EpicordiaColors.blue600 : EpicordiaColors.borderStrongLight, width: 1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: EpicordiaColors.textPrimaryLight)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 14, color: EpicordiaColors.textSecondaryLight, height: 1.45)),
            const SizedBox(height: 16),
            preview,
          ],
        ),
      ),
    );
  }
}

// ── Boards preview (mini canvas cards) ───────────────────────────────
class _BoardsPreview extends StatelessWidget {
  const _BoardsPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(color: EpicordiaColors.surfaceSunkenLight, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MiniCanvasCard(width: 70, height: 60),
          const SizedBox(width: 8),
          _MiniCanvasCard(width: 90, height: 68, hasLines: true),
          const SizedBox(width: 8),
          _MiniCanvasCard(width: 70, height: 60),
        ],
      ),
    );
  }
}

class _MiniCanvasCard extends StatelessWidget {
  final double width;
  final double height;
  final bool hasLines;
  const _MiniCanvasCard({required this.width, required this.height, this.hasLines = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EpicordiaColors.borderSubtleLight),
      ),
      padding: const EdgeInsets.all(8),
      child: hasLines
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 6, decoration: BoxDecoration(color: EpicordiaColors.borderSubtleLight, borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 4),
                Container(height: 6, width: 50, decoration: BoxDecoration(color: EpicordiaColors.borderSubtleLight, borderRadius: BorderRadius.circular(3))),
              ],
            )
          : null,
    );
  }
}

// ── Lists preview (mini task rows) ────────────────────────────────────
class _ListsPreview extends StatelessWidget {
  const _ListsPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: EpicordiaColors.surfaceSunkenLight, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          _MiniTaskRow(checked: false, width: 140),
          const SizedBox(height: 10),
          _MiniTaskRow(checked: false, width: 110),
          const SizedBox(height: 10),
          _MiniTaskRow(checked: true, width: 130, active: true),
        ],
      ),
    );
  }
}

class _MiniTaskRow extends StatelessWidget {
  final bool checked;
  final double width;
  final bool active;
  const _MiniTaskRow({required this.checked, required this.width, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? EpicordiaColors.blue600 : Colors.transparent,
            border: Border.all(color: active ? EpicordiaColors.blue600 : EpicordiaColors.borderStrongLight, width: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 8,
          width: width,
          decoration: BoxDecoration(
            color: active ? EpicordiaColors.blue300 : EpicordiaColors.borderSubtleLight,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
