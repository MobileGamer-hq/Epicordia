import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/today_dashboard.dart';
import '../presentation/screens/boards_tab.dart';
import '../presentation/screens/notes_tab.dart';
import '../presentation/screens/tasks_tab.dart';
import '../presentation/screens/board_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const TodayDashboard(),
      ),
      GoRoute(
        path: '/boards',
        builder: (context, state) => const BoardsTab(),
      ),
      GoRoute(
        path: '/board/:id',
        builder: (context, state) {
          final boardId = state.pathParameters['id']!;
          return BoardScreen(boardId: boardId);
        },
      ),
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesTab(),
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TasksTab(),
      ),
    ],
  );
});
