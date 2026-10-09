import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TutorialMode {
  slides,
  spotlight,
  hybrid,
}

extension TutorialModeExtension on TutorialMode {
  String get nameString {
    switch (this) {
      case TutorialMode.slides:
        return 'Visual Slide Walkthrough';
      case TutorialMode.spotlight:
        return 'Interactive Dashboard Spotlight';
      case TutorialMode.hybrid:
        return 'Hybrid (Slides + Spotlight)';
    }
  }

  String get description {
    switch (this) {
      case TutorialMode.slides:
        return 'Show interactive visual slides highlighting all core features.';
      case TutorialMode.spotlight:
        return 'Highlight UI elements (Sidebar, Search, Quick Capture, Epi AI) directly on the screen.';
      case TutorialMode.hybrid:
        return 'Show feature slides during onboarding followed by live spotlight tour on the dashboard.';
    }
  }
}

class TutorialState {
  final TutorialMode mode;
  final bool isSpotlightActive;
  final int currentSpotlightStep;
  final bool isCompleted;

  const TutorialState({
    required this.mode,
    required this.isSpotlightActive,
    required this.currentSpotlightStep,
    required this.isCompleted,
  });

  TutorialState copyWith({
    TutorialMode? mode,
    bool? isSpotlightActive,
    int? currentSpotlightStep,
    bool? isCompleted,
  }) {
    return TutorialState(
      mode: mode ?? this.mode,
      isSpotlightActive: isSpotlightActive ?? this.isSpotlightActive,
      currentSpotlightStep: currentSpotlightStep ?? this.currentSpotlightStep,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class TutorialNotifier extends Notifier<TutorialState> {
  static const String _modeKey = 'epicordia_tutorial_mode';
  static const String _completedKey = 'epicordia_tutorial_completed';

  @override
  TutorialState build() {
    _loadSavedState();
    return const TutorialState(
      mode: TutorialMode.slides,
      isSpotlightActive: false,
      currentSpotlightStep: 0,
      isCompleted: false,
    );
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_modeKey) ?? 'slides';
    final completed = prefs.getBool(_completedKey) ?? false;

    TutorialMode mode = TutorialMode.slides;
    if (modeStr == 'spotlight') mode = TutorialMode.spotlight;
    if (modeStr == 'hybrid') mode = TutorialMode.hybrid;

    state = state.copyWith(
      mode: mode,
      isCompleted: completed,
    );
  }

  Future<void> setTutorialMode(TutorialMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  Future<void> startSpotlightTour() async {
    state = state.copyWith(
      isSpotlightActive: true,
      currentSpotlightStep: 0,
    );
  }

  void nextSpotlightStep() {
    if (state.currentSpotlightStep < 4) {
      state = state.copyWith(currentSpotlightStep: state.currentSpotlightStep + 1);
    } else {
      completeTutorial();
    }
  }

  void prevSpotlightStep() {
    if (state.currentSpotlightStep > 0) {
      state = state.copyWith(currentSpotlightStep: state.currentSpotlightStep - 1);
    }
  }

  void goToSpotlightStep(int step) {
    state = state.copyWith(currentSpotlightStep: step);
  }

  Future<void> completeTutorial() async {
    state = state.copyWith(
      isSpotlightActive: false,
      isCompleted: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }

  void cancelSpotlightTour() {
    state = state.copyWith(isSpotlightActive: false);
  }

  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, false);
    state = state.copyWith(
      isCompleted: false,
      isSpotlightActive: false,
      currentSpotlightStep: 0,
    );
  }
}

final tutorialProvider = NotifierProvider<TutorialNotifier, TutorialState>(TutorialNotifier.new);
