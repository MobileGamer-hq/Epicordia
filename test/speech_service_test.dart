import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remixicon/remixicon.dart';
import 'package:epicordia/domain/services/speech_recognition_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpeechRecognitionService & State Tests', () {
    test('Initial SpeechRecognitionState has expected default values', () {
      const state = SpeechRecognitionState();
      expect(state.isInitialized, false);
      expect(state.isListening, false);
      expect(state.isAvailable, false);
      expect(state.hasPermission, false);
      expect(state.recognizedWords, '');
      expect(state.soundLevel, 0.0);
      expect(state.errorMessage, isNull);
    });

    test('SpeechRecognitionState.copyWith updates fields properly', () {
      const state = SpeechRecognitionState();
      final updated = state.copyWith(
        isInitialized: true,
        isListening: true,
        isAvailable: true,
        hasPermission: true,
        recognizedWords: 'Hello world',
        soundLevel: 0.85,
        errorMessage: 'Some error',
      );

      expect(updated.isInitialized, true);
      expect(updated.isListening, true);
      expect(updated.isAvailable, true);
      expect(updated.hasPermission, true);
      expect(updated.recognizedWords, 'Hello world');
      expect(updated.soundLevel, 0.85);
      expect(updated.errorMessage, 'Some error');

      final cleared = updated.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });

    test('Required UI icons are available', () {
      expect(Remix.file_copy_line, isNotNull);
      expect(Remix.mic_line, isNotNull);
      expect(Remix.mic_fill, isNotNull);
      expect(Remix.check_line, isNotNull);
    });
  });

  group('Clipboard functionality test', () {
    testWidgets('Clipboard correctly stores message text on copy', (tester) async {
      String? copiedData;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final args = methodCall.arguments as Map<dynamic, dynamic>?;
            copiedData = args?['text'] as String?;
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': copiedData};
          }
          return null;
        },
      );

      await Clipboard.setData(const ClipboardData(text: 'Test agent reply or prompt'));
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      expect(data?.text, 'Test agent reply or prompt');
    });
  });
}
