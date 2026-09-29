import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'epi_api_service.dart';
import 'epi_models.dart';

const String _kLastCheckinTimestampKey = 'epi_last_proactive_checkin_ts';

class ProactiveCheckinState {
  final bool isLoading;
  final ProactiveCheckinResult? result;
  final bool isDismissed;

  const ProactiveCheckinState({
    this.isLoading = false,
    this.result,
    this.isDismissed = false,
  });

  bool get shouldShow =>
      !isLoading &&
      !isDismissed &&
      result != null &&
      result!.shouldSpeak &&
      result!.message.isNotEmpty;

  ProactiveCheckinState copyWith({
    bool? isLoading,
    ProactiveCheckinResult? result,
    bool? isDismissed,
  }) {
    return ProactiveCheckinState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}

class ProactiveCheckinNotifier extends Notifier<ProactiveCheckinState> {
  bool _hasCheckedInThisSession = false;

  @override
  ProactiveCheckinState build() {
    // Initiate cold-start check-in automatically
    _checkColdStart();
    return const ProactiveCheckinState();
  }

  Future<void> _checkColdStart() async {
    if (_hasCheckedInThisSession) return;
    _hasCheckedInThisSession = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTs = prefs.getInt(_kLastCheckinTimestampKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // Rate limit: trigger only if > 4 hours since last check-in
      if (nowMs - lastTs < 4 * 60 * 60 * 1000) {
        return;
      }

      state = state.copyWith(isLoading: true);

      final apiService = ref.read(epiApiServiceProvider);
      final res = await apiService.fetchProactiveCheckin();

      // Record timestamp
      await prefs.setInt(_kLastCheckinTimestampKey, nowMs);

      state = state.copyWith(
        isLoading: false,
        result: res,
        isDismissed: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void dismiss() {
    state = state.copyWith(isDismissed: true);
  }

  /// Manually force a check-in re-run (e.g. pull to refresh or test)
  Future<void> forceCheckin() async {
    state = state.copyWith(isLoading: true, isDismissed: false);
    try {
      final apiService = ref.read(epiApiServiceProvider);
      final res = await apiService.fetchProactiveCheckin();
      state = state.copyWith(isLoading: false, result: res);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final proactiveCheckinProvider =
    NotifierProvider<ProactiveCheckinNotifier, ProactiveCheckinState>(
        ProactiveCheckinNotifier.new);
