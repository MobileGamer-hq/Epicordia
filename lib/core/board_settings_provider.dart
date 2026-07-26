import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CanvasToolMode { select, pan, zoom }

enum ToolbarPosition { left, right, bottom }

class CanvasToolModeNotifier extends Notifier<CanvasToolMode> {
  @override
  CanvasToolMode build() => CanvasToolMode.select;

  void setMode(CanvasToolMode mode) {
    state = mode;
  }
}

final canvasToolModeProvider =
    NotifierProvider<CanvasToolModeNotifier, CanvasToolMode>(
  CanvasToolModeNotifier.new,
);

class ToolbarPositionNotifier extends Notifier<ToolbarPosition> {
  static const String _prefKey = 'board_toolbar_position';

  @override
  ToolbarPosition build() {
    _loadSavedPosition();
    return ToolbarPosition.left;
  }

  Future<void> _loadSavedPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved == 'left') {
      state = ToolbarPosition.left;
    } else if (saved == 'right') {
      state = ToolbarPosition.right;
    } else if (saved == 'bottom') {
      state = ToolbarPosition.bottom;
    }
  }

  Future<void> setPosition(ToolbarPosition position) async {
    state = position;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, position.name);
  }

  void cyclePosition() {
    switch (state) {
      case ToolbarPosition.left:
        setPosition(ToolbarPosition.right);
        break;
      case ToolbarPosition.right:
        setPosition(ToolbarPosition.bottom);
        break;
      case ToolbarPosition.bottom:
        setPosition(ToolbarPosition.left);
        break;
    }
  }
}

final toolbarPositionProvider =
    NotifierProvider<ToolbarPositionNotifier, ToolbarPosition>(
  ToolbarPositionNotifier.new,
);
