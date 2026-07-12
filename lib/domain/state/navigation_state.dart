import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_state.g.dart';

@riverpod
class NavigationState extends _$NavigationState {
  @override
  String? build() {
    // Null indicates we are not on a specific board (e.g. Dashboard or Inbox)
    return null;
  }

  void setActiveBoard(String? boardId) {
    state = boardId;
  }
}
