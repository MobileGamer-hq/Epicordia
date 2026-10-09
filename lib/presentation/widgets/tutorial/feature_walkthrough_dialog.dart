import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../core/epicordia_brand.dart';

class FeatureSlide {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<String> bulletPoints;

  const FeatureSlide({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.bulletPoints,
  });
}

final List<FeatureSlide> featureSlides = [
  FeatureSlide(
    title: 'Welcome to Epicordia',
    subtitle: 'Your all-in-one personal productivity & management workspace.',
    icon: Icons.space_dashboard_rounded,
    accentColor: EpicordiaColors.blue600,
    bulletPoints: const [
      'Seamlessly manage tasks, visual boards, notes, and schedules in one clean app.',
      '100% offline-first & privacy focused — your data stays safe on your device.',
      'Adaptive layout tuned for Mobile, Tablet, and Desktop screens.',
    ],
  ),
  FeatureSlide(
    title: 'Smart Tasks & Focus Sessions',
    subtitle: 'Stay organized with structured task lists and Pomodoro timer mode.',
    icon: Icons.check_circle_rounded,
    accentColor: const Color(0xFF10B981),
    bulletPoints: const [
      'Organize with Priorities (Low to Urgent), Due Dates, and Recurrence.',
      'Break complex projects down into subtasks with step-by-step progress tracking.',
      'Enter Focus Mode with built-in timer sessions to eliminate distractions.',
    ],
  ),
  FeatureSlide(
    title: 'Infinite Canvas & Visual Boards',
    subtitle: 'Map out ideas visually with infinite canvas, pins, and drawings.',
    icon: Icons.grid_view_rounded,
    accentColor: const Color(0xFF8B5CF6),
    bulletPoints: const [
      'Create multi-pin boards for project brainstorming and visual mind mapping.',
      'Add Text, Tasks, Images, and Web Link cards anywhere on the canvas.',
      'Connect pins with connector lines and sketch freehand directly on boards.',
    ],
  ),
  FeatureSlide(
    title: 'Notes & Daily Journaling',
    subtitle: 'Capture quick thoughts, markdown notes, and daily reflections.',
    icon: Icons.description_rounded,
    accentColor: const Color(0xFFF59E0B),
    bulletPoints: const [
      'Rich Markdown text notes with full preview and image attachments.',
      'Folder categorization, tags, and pinned notes for quick access.',
      'Daily journaling habit tracker with custom reminders.',
    ],
  ),
  FeatureSlide(
    title: 'Personalization & Customization',
    subtitle: 'Tailor your workspace with custom themes, colors, and security.',
    icon: Icons.tune_rounded,
    accentColor: const Color(0xFFEC4899),
    bulletPoints: const [
      'Switch between Light & Dark themes and select custom primary accent colors.',
      'Protect sensitive notes and personal management data with PIN App Lock.',
      'Export workspace data (JSON/CSV) and customize OS home screen widgets.',
    ],
  ),
  FeatureSlide(
    title: 'Epi AI Copilot & Voice Assistant',
    subtitle: 'Your smart AI assistant capable of performing real app actions for you.',
    icon: Icons.auto_awesome,
    accentColor: const Color(0xFF3B82F6),
    bulletPoints: const [
      'Hands-free voice recognition — speak to Epi to manage your day.',
      'Automated tool execution: Epi creates tasks, sets alarms, and updates notes.',
      'Proactive daily check-ins, smart task breakdowns, and personal memory.',
    ],
  ),
];

class FeatureWalkthroughDialog extends StatefulWidget {
  final VoidCallback onFinish;

  const FeatureWalkthroughDialog({
    super.key,
    required this.onFinish,
  });

  static Future<void> show(BuildContext context, {required VoidCallback onFinish}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FeatureWalkthroughDialog(onFinish: onFinish),
    );
  }

  @override
  State<FeatureWalkthroughDialog> createState() => _FeatureWalkthroughDialogState();
}

class _FeatureWalkthroughDialogState extends State<FeatureWalkthroughDialog> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < featureSlides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
      widget.onFinish();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? EpicordiaColors.surfaceCardDark : Colors.white;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 620),
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderClr),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Header Bar with Logo & Skip button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              child: Row(
                children: [
                  EpicordiaLogo(size: 18),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onFinish();
                    },
                    child: Text(
                      'Skip Tour',
                      style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: borderClr),

            // Page View Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: featureSlides.length,
                itemBuilder: (context, index) {
                  final slide = featureSlides[index];
                  return Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon badge
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: slide.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: slide.accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Icon(slide.icon, color: slide.accentColor, size: 36),
                        ),

                        const SizedBox(height: 20),

                        // Title & Subtitle
                        Text(
                          slide.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          slide.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Bullet points list
                        Expanded(
                          child: ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: slide.bulletPoints.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, bIdx) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: slide.accentColor.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.check, color: slide.accentColor, size: 12),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      slide.bulletPoints[bIdx],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textPrimary,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Divider(height: 1, color: borderClr),

            // Bottom Navigation Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(featureSlides.length, (idx) {
                      final isActive = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isActive ? 16 : 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: isActive ? featureSlides[_currentPage].accentColor : borderClr,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),

                  const Spacer(),

                  if (_currentPage > 0)
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      icon: Icon(Icons.arrow_back, color: textSecondary, size: 20),
                      onPressed: _prevPage,
                      tooltip: 'Previous Slide',
                    ),

                  const SizedBox(width: 4),

                  Flexible(
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: featureSlides[_currentPage].accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _currentPage == featureSlides.length - 1 ? 'Start Using Epicordia' : 'Next',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _currentPage == featureSlides.length - 1 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                            size: 15,
                          ),
                        ],
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
