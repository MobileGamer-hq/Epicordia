import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../widgets/core/epicordia_brand.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0; // 0: Name, 1: Use Cases, 2: Workflow Preference
  final _nameController = TextEditingController();
  final List<String> _selectedUseCases = [];
  String? _selectedWorkflow = 'boards';

  final List<String> _useCaseOptions = [
    'Project Management',
    'Personal Development',
    'Note Taking / Journaling',
    'Academic Study',
    'Creative Ideas',
    'Daily To-dos',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setString('app_use_cases', _selectedUseCases.join(','));
    await prefs.setString('workflow_preference', _selectedWorkflow ?? 'boards');
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/');
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _isNextEnabled() {
    if (_currentStep == 0) {
      return _nameController.text.trim().isNotEmpty;
    }
    if (_currentStep == 1) {
      return _selectedUseCases.isNotEmpty;
    }
    return _selectedWorkflow != null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;

    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [0, 1, 2].map((step) {
                  final isActive = step <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isActive ? EpicordiaColors.blue600 : EpicordiaColors.borderSubtleLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildCurrentStepView(),
                ),
              ),
            ),

            // Bottom Navigation CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isNextEnabled() ? _nextStep : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _isNextEnabled() ? EpicordiaColors.blue600 : EpicordiaColors.textTertiaryLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _currentStep == 2 ? 'Get Started' : 'Continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _isNextEnabled() ? Colors.white : EpicordiaColors.textTertiaryLight,
                        ),
                      ),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _prevStep,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Text(
                          'Back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: EpicordiaColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Privacy-first. Your data never leaves your device without permission.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: EpicordiaColors.textTertiaryLight,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final surfaceCard = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;

    switch (_currentStep) {
      case 0:
        return Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EpicordiaLogo(size: 20),
            const SizedBox(height: 32),
            Text(
              'Welcome to\nEpicordia',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'What should we call you? Your name will be used to personalize your dashboard greeting.',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _nameController,
              autofocus: true,
              style: TextStyle(fontSize: 16, color: textPrimary, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Enter your name...',
                hintStyle: TextStyle(color: textTertiary, fontWeight: FontWeight.normal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderStrong),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderStrong),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: EpicordiaColors.blue600, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
          ],
        );

      case 1:
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EpicordiaLogo(size: 20),
            const SizedBox(height: 32),
            Text(
              'What will you\nuse it for?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select the purposes that match your workflow. This helps customize your productivity experience.',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _useCaseOptions.map((useCase) {
                final isSelected = _selectedUseCases.contains(useCase);
                return FilterChip(
                  label: Text(useCase),
                  selected: isSelected,
                  selectedColor: isDark ? EpicordiaColors.blue900 : EpicordiaColors.blue100,
                  checkmarkColor: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue700,
                  labelStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue700)
                        : textPrimary,
                  ),
                  backgroundColor: surfaceCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? EpicordiaColors.blue600 : borderSubtle,
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedUseCases.add(useCase);
                      } else {
                        _selectedUseCases.remove(useCase);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );

      case 2:
      default:
        return Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EpicordiaLogo(size: 20),
            const SizedBox(height: 32),
            Text(
              'How would you\nlike to start?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a workflow that fits your thinking style. You can change this later at any time.',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Boards option
            _WorkflowCard(
              id: 'boards',
              selected: _selectedWorkflow == 'boards',
              onTap: () => setState(() => _selectedWorkflow = 'boards'),
              icon: Icons.space_dashboard_outlined,
              iconBg: isDark ? EpicordiaColors.blue900 : EpicordiaColors.blue100,
              iconColor: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue700,
              title: 'Boards',
              description:
                  'A visual, infinite canvas for spatial organization. Best for moodboarding, complex projects, and brainstorming.',
              preview: const _BoardsPreview(),
            ),

            const SizedBox(height: 16),

            // Lists option
            _WorkflowCard(
              id: 'lists',
              selected: _selectedWorkflow == 'lists',
              onTap: () => setState(() => _selectedWorkflow = 'lists'),
              icon: Icons.description_outlined,
              iconBg: isDark ? const Color(0xFF3D3200) : const Color(0xFFFFF3CD),
              iconColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF785A00),
              title: 'Lists',
              description:
                  'Structured notes and sequential tasks. Best for rapid capturing, journaling, and daily to-do management.',
              preview: const _ListsPreview(),
            ),
          ],
        );
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final surfaceCard = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final borderStrong = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? EpicordiaColors.blue600
                : borderSubtle,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
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
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const Spacer(),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? EpicordiaColors.blue600
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? EpicordiaColors.blue600
                          : borderStrong,
                      width: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.45,
              ),
            ),
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
      decoration: BoxDecoration(
        color: EpicordiaColors.surfaceSunkenLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _MiniCanvasCard(width: 70, height: 60),
          const SizedBox(width: 8),
          const _MiniCanvasCard(width: 90, height: 68, hasLines: true),
          const SizedBox(width: 8),
          const _MiniCanvasCard(width: 70, height: 60),
        ],
      ),
    );
  }
}

class _MiniCanvasCard extends StatelessWidget {
  final double width;
  final double height;
  final bool hasLines;
  const _MiniCanvasCard({
    required this.width,
    required this.height,
    this.hasLines = false,
  });

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
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: EpicordiaColors.borderSubtleLight,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 6,
                  width: 50,
                  decoration: BoxDecoration(
                    color: EpicordiaColors.borderSubtleLight,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
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
      decoration: BoxDecoration(
        color: EpicordiaColors.surfaceSunkenLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
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
  const _MiniTaskRow({
    required this.checked,
    required this.width,
    this.active = false,
  });

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
            border: Border.all(
              color: active
                  ? EpicordiaColors.blue600
                  : EpicordiaColors.borderStrongLight,
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 8,
          width: width,
          decoration: BoxDecoration(
            color: active
                ? EpicordiaColors.blue300
                : EpicordiaColors.borderSubtleLight,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
