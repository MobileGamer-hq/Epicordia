import 'package:flutter_riverpod/flutter_riverpod.dart';

class FloatingEpiChatNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
  void toggle() => state = !state;
  void expand() => state = true;
  void collapse() => state = false;
}

final floatingEpiChatProvider =
    NotifierProvider<FloatingEpiChatNotifier, bool>(FloatingEpiChatNotifier.new);

/// Tracks whether full-screen Epi Chat is active in the foreground,
/// so the floating "Ask Epi" pill button is completely suppressed.
class FullScreenEpiActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setActive(bool active) => state = active;
}

final isFullScreenEpiActiveProvider =
    NotifierProvider<FullScreenEpiActiveNotifier, bool>(FullScreenEpiActiveNotifier.new);
