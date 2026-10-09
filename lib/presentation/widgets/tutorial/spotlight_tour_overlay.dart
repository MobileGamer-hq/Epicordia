import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/tutorial_provider.dart';

class SpotlightStepInfo {
  final String title;
  final String description;
  final IconData icon;
  final Alignment cardAlignment;
  final EdgeInsets cardMargin;

  const SpotlightStepInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.cardAlignment,
    required this.cardMargin,
  });
}

const List<SpotlightStepInfo> spotlightSteps = [
  SpotlightStepInfo(
    title: 'Workspace Navigation',
    description: 'Switch between your Today Dashboard, Infinite Canvas Boards, Markdown Notes, Task lists, and Timetable.',
    icon: Icons.space_dashboard_outlined,
    cardAlignment: Alignment.topLeft,
    cardMargin: EdgeInsets.only(top: 100, left: 24, right: 24),
  ),
  SpotlightStepInfo(
    title: 'Global Search (⌘K / Ctrl+K)',
    description: 'Instantly search for any task, note, board pin, schedule slot, or alarm across your entire workspace.',
    icon: Icons.search_rounded,
    cardAlignment: Alignment.topCenter,
    cardMargin: EdgeInsets.only(top: 130, left: 24, right: 24),
  ),
  SpotlightStepInfo(
    title: 'Quick Capture & Create (+)',
    description: 'Capture quick thoughts, create tasks, set alarms, or launch new visual boards instantly from anywhere.',
    icon: Icons.add_circle_outline,
    cardAlignment: Alignment.bottomCenter,
    cardMargin: EdgeInsets.only(bottom: 120, left: 24, right: 24),
  ),
  SpotlightStepInfo(
    title: 'Epi AI Copilot & Voice Assistant',
    description: 'Chat or speak with Epi! Epi can auto-create tasks, break down complex projects, schedule alarms, and organize notes for you.',
    icon: Icons.auto_awesome,
    cardAlignment: Alignment.bottomRight,
    cardMargin: EdgeInsets.only(bottom: 110, left: 24, right: 24),
  ),
  SpotlightStepInfo(
    title: 'Today Overview & Proactive Suggestions',
    description: 'Stay on top of daily priorities, focus metrics, and smart proactive check-ins suggested by Epi AI.',
    icon: Icons.today_rounded,
    cardAlignment: Alignment.center,
    cardMargin: EdgeInsets.symmetric(horizontal: 24),
  ),
];

class SpotlightTourOverlay extends ConsumerWidget {
  const SpotlightTourOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tutorialProvider);
    final notifier = ref.read(tutorialProvider.notifier);

    if (!state.isSpotlightActive) return const SizedBox.shrink();

    final stepIndex = state.currentSpotlightStep.clamp(0, spotlightSteps.length - 1);
    final stepInfo = spotlightSteps[stepIndex];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : Colors.white;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    return Stack(
      children: [
        // Semi-transparent backdrop
        GestureDetector(
          onTap: () {}, // Prevent tapping items behind spotlight
          child: Container(
            color: Colors.black.withValues(alpha: 0.72),
          ),
        ),

        // Animated Tooltip Dialog Card
        Align(
          alignment: stepInfo.cardAlignment,
          child: Padding(
            padding: stepInfo.cardMargin,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: EpicordiaColors.blue500.withValues(alpha: 0.6), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: EpicordiaColors.blue600.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header badge + Step indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: EpicordiaColors.blue600.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(stepInfo.icon, color: EpicordiaColors.blue600, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FEATURE TOUR (${stepIndex + 1}/${spotlightSteps.length})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: EpicordiaColors.blue600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stepInfo.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: textSecondary, size: 20),
                          onPressed: () => notifier.cancelSpotlightTour(),
                          tooltip: 'Skip Tour',
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Description text
                    Text(
                      stepInfo.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dots progress bar
                    Row(
                      children: List.generate(spotlightSteps.length, (idx) {
                        final isActive = idx == stepIndex;
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isActive ? EpicordiaColors.blue600 : borderClr,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 20),

                    // Navigation Actions
                    Row(
                      children: [
                        if (stepIndex > 0)
                          OutlinedButton(
                            onPressed: () => notifier.prevSpotlightStep(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              side: BorderSide(color: borderClr),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              'Back',
                              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => notifier.nextSpotlightStep(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EpicordiaColors.blue600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                stepIndex == spotlightSteps.length - 1 ? 'Finish Tour' : 'Next Step',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                stepIndex == spotlightSteps.length - 1 ? Icons.check_circle : Icons.arrow_forward_rounded,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
