import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockState {
  final bool isEnabled;
  final bool isLocked;
  final bool hasPin;

  const AppLockState({
    required this.isEnabled,
    required this.isLocked,
    required this.hasPin,
  });

  AppLockState copyWith({
    bool? isEnabled,
    bool? isLocked,
    bool? hasPin,
  }) {
    return AppLockState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLocked: isLocked ?? this.isLocked,
      hasPin: hasPin ?? this.hasPin,
    );
  }
}

class AppLockNotifier extends Notifier<AppLockState> with WidgetsBindingObserver {
  static const _keyEnabled = 'app_lock_enabled';
  static const _keyPinHash = 'app_lock_pin_hash';

  String? _savedPinHash;

  @override
  AppLockState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
    });

    _loadInitialState();

    return const AppLockState(
      isEnabled: false,
      isLocked: false,
      hasPin: false,
    );
  }

  Future<void> _loadInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? false;
    _savedPinHash = prefs.getString(_keyPinHash);
    final hasPin = _savedPinHash != null && _savedPinHash!.isNotEmpty;

    // Lock on cold boot if app lock is enabled and pin is set
    state = AppLockState(
      isEnabled: enabled && hasPin,
      isLocked: enabled && hasPin,
      hasPin: hasPin,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (this.state.isEnabled && this.state.hasPin) {
        lock();
      }
    }
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool verifyPin(String pin) {
    if (_savedPinHash == null) return false;
    return _hashPin(pin) == _savedPinHash;
  }

  Future<bool> setPinAndEnable(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = _hashPin(newPin);
    await prefs.setString(_keyPinHash, hash);
    await prefs.setBool(_keyEnabled, true);

    _savedPinHash = hash;
    state = state.copyWith(
      isEnabled: true,
      hasPin: true,
      isLocked: false,
    );
    return true;
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    if (!verifyPin(oldPin)) return false;

    final prefs = await SharedPreferences.getInstance();
    final hash = _hashPin(newPin);
    await prefs.setString(_keyPinHash, hash);

    _savedPinHash = hash;
    state = state.copyWith(
      hasPin: true,
    );
    return true;
  }

  Future<void> disableAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, false);

    state = state.copyWith(
      isEnabled: false,
      isLocked: false,
    );
  }

  Future<void> enableAppLock() async {
    if (!state.hasPin) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, true);

    state = state.copyWith(
      isEnabled: true,
    );
  }

  void lock() {
    if (state.isEnabled && state.hasPin) {
      state = state.copyWith(isLocked: true);
    }
  }

  void unlock() {
    state = state.copyWith(isLocked: false);
  }
}

final appLockProvider = NotifierProvider<AppLockNotifier, AppLockState>(AppLockNotifier.new);
