import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kUseSystemClockAppKey = 'use_system_clock_app';

class AlarmSettingsNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadPreference();
    return false;
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(kUseSystemClockAppKey) ?? false;
  }

  Future<void> setUseSystemClockApp(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kUseSystemClockAppKey, value);
  }
}

final alarmSettingsProvider =
    NotifierProvider<AlarmSettingsNotifier, bool>(AlarmSettingsNotifier.new);
