import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigationStateProvider = NotifierProvider<NavigationState, String?>(() {
  return NavigationState();
});

class NavigationState extends Notifier<String?> {
  @override
  String? build() {
    return null;
  }

  void setActiveBoard(String? boardId) {
    state = boardId;
  }
}
