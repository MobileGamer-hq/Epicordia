import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// State of on-device speech-to-text recognition.
class SpeechRecognitionState {
  final bool isInitialized;
  final bool isListening;
  final bool isAvailable;
  final bool hasPermission;
  final String recognizedWords;
  final double soundLevel;
  final String? errorMessage;

  const SpeechRecognitionState({
    this.isInitialized = false,
    this.isListening = false,
    this.isAvailable = false,
    this.hasPermission = false,
    this.recognizedWords = '',
    this.soundLevel = 0.0,
    this.errorMessage,
  });

  SpeechRecognitionState copyWith({
    bool? isInitialized,
    bool? isListening,
    bool? isAvailable,
    bool? hasPermission,
    String? recognizedWords,
    double? soundLevel,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SpeechRecognitionState(
      isInitialized: isInitialized ?? this.isInitialized,
      isListening: isListening ?? this.isListening,
      isAvailable: isAvailable ?? this.isAvailable,
      hasPermission: hasPermission ?? this.hasPermission,
      recognizedWords: recognizedWords ?? this.recognizedWords,
      soundLevel: soundLevel ?? this.soundLevel,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Service controller implementing Route A: On-device, fully offline speech recognition.
/// Uses the device's built-in speech recognition engine (Google on Android, Apple on iOS)
/// with zero API keys and zero network calls, matching Epicordia's local-first identity.
class SpeechRecognitionNotifier extends Notifier<SpeechRecognitionState> {
  late final SpeechToText _speechToText;

  @override
  SpeechRecognitionState build() {
    _speechToText = SpeechToText();
    return const SpeechRecognitionState();
  }

  /// Initialize speech-to-text engine and request microphone/speech permissions if needed.
  Future<bool> initialize() async {
    if (state.isInitialized && state.isAvailable) {
      return true;
    }

    try {
      final available = await _speechToText.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
        debugLogging: kDebugMode,
      );

      final hasPerm = await _speechToText.hasPermission;

      state = state.copyWith(
        isInitialized: true,
        isAvailable: available,
        hasPermission: hasPerm,
        clearError: true,
      );

      return available;
    } catch (e) {
      state = state.copyWith(
        isInitialized: true,
        isAvailable: false,
        errorMessage: 'Speech recognition initialization failed: $e',
      );
      return false;
    }
  }

  /// Start listening for voice input.
  /// Prefers on-device offline recognition (`onDevice: true`).
  Future<bool> startListening({
    required void Function(String words, bool isFinal) onResult,
    void Function(double level)? onSoundLevel,
  }) async {
    if (!state.isInitialized) {
      final ok = await initialize();
      if (!ok) return false;
    }

    if (!state.isAvailable) {
      state = state.copyWith(
        errorMessage: 'Speech recognition is not available or microphone permission was denied.',
      );
      return false;
    }

    if (_speechToText.isListening) {
      await stopListening();
      return false;
    }

    _onResult = onResult;
    _onSoundLevel = onSoundLevel;

    state = state.copyWith(
      isListening: true,
      recognizedWords: '',
      soundLevel: 0.0,
      clearError: true,
    );

    return _listen(onDevice: _preferOnDevice);
  }

  /// Whether to request the on-device (offline) recognizer. Starts true
  /// (Route A) and flips to false for the rest of the app session if the
  /// device has no offline language model installed.
  bool _preferOnDevice = true;
  void Function(String words, bool isFinal)? _onResult;
  void Function(double level)? _onSoundLevel;

  Future<bool> _listen({required bool onDevice}) async {
    void handleResult(SpeechRecognitionResult res) {
      state = state.copyWith(recognizedWords: res.recognizedWords);
      _onResult?.call(res.recognizedWords, res.finalResult);
    }

    void handleSoundLevel(double level) {
      state = state.copyWith(soundLevel: level);
      _onSoundLevel?.call(level);
    }

    try {
      await _speechToText.listen(
        onResult: handleResult,
        onSoundLevelChange: handleSoundLevel,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          onDevice: onDevice,
        ),
      );
      return true;
    } catch (e) {
      if (onDevice) {
        // Platform rejected the on-device request synchronously.
        _preferOnDevice = false;
        return _listen(onDevice: false);
      }
      state = state.copyWith(
        isListening: false,
        errorMessage: 'Could not start voice input. Please try again.',
      );
      return false;
    }
  }

  /// Stop listening and finalize transcription.
  Future<void> stopListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (e) {
      debugPrint('Error stopping speech listening: $e');
    } finally {
      state = state.copyWith(isListening: false);
    }
  }

  /// Cancel listening and discard current phrase.
  Future<void> cancelListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.cancel();
      }
    } catch (e) {
      debugPrint('Error cancelling speech listening: $e');
    } finally {
      state = state.copyWith(isListening: false, recognizedWords: '');
    }
  }

  /// Set while we are restarting after an on-device failure, so the
  /// intermediate `notListening` status doesn't flicker the UI off.
  bool _isFallingBack = false;

  void _handleStatus(String status) {
    if (_isFallingBack) return;
    if (status == 'done' || status == 'notListening' || status == 'doneNoResult') {
      state = state.copyWith(isListening: false);
    } else if (status == 'listening') {
      state = state.copyWith(isListening: true);
    }
  }

  static const _offlineModelErrors = {
    'error_language_unavailable', // 13: offline model not downloaded
    'error_language_not_supported', // 12: locale not supported on-device
  };

  void _handleError(SpeechRecognitionError error) {
    // The device has no offline speech model for this language (common on
    // emulators and fresh devices). Retry once with the standard recognizer
    // and remember the choice for the rest of the session.
    if (_preferOnDevice && _offlineModelErrors.contains(error.errorMsg)) {
      debugPrint('Speech: on-device model unavailable (${error.errorMsg}); falling back to standard recognizer');
      _preferOnDevice = false;
      _isFallingBack = true;
      Future<void>.delayed(const Duration(milliseconds: 150), () async {
        await _listen(onDevice: false);
        _isFallingBack = false;
        state = state.copyWith(isListening: _speechToText.isListening);
      });
      return;
    }

    // Benign: user was silent or nothing recognized.
    if (error.errorMsg == 'error_speech_timeout' || error.errorMsg == 'error_no_match') {
      state = state.copyWith(isListening: false);
      return;
    }

    state = state.copyWith(
      isListening: false,
      errorMessage: _friendlyError(error.errorMsg),
    );
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'error_permission':
      case 'error_insufficient_permissions':
        return 'Microphone permission is required for voice input.';
      case 'error_audio_error':
      case 'error_audio':
        return 'Could not access the microphone.';
      case 'error_busy':
      case 'error_recognizer_busy':
        return 'Speech recognizer is busy. Try again in a moment.';
      case 'error_network':
      case 'error_network_timeout':
      case 'error_server':
      case 'error_server_disconnected':
        return 'Voice input is unavailable right now. Download an offline speech pack in your device settings to use it offline.';
      case 'error_language_unavailable':
      case 'error_language_not_supported':
        return 'Your language isn\'t available for speech recognition on this device.';
      default:
        return 'Voice input failed ($code).';
    }
  }
}

final speechRecognitionProvider =
    NotifierProvider<SpeechRecognitionNotifier, SpeechRecognitionState>(
  SpeechRecognitionNotifier.new,
);
