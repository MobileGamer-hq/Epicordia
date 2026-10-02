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
