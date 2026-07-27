import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/onboarding_screen.dart';
import '../presentation/screens/today_dashboard.dart';
import '../presentation/screens/boards_tab.dart';
import '../presentation/screens/notes_tab.dart';
import '../presentation/screens/tasks_tab.dart';
import '../presentation/screens/board_screen.dart';
import '../presentation/screens/create_screen.dart';
import '../presentation/screens/create_note_screen.dart';
import '../presentation/screens/create_task_screen.dart';
import '../presentation/screens/create_board_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/edit_task_screen.dart';
import '../presentation/screens/calendar_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!onboardingComplete && !isOnboarding) {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/',       builder: (context, state) => const TodayDashboard()),
      GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen()),
      // GoRoute(path: '/',       builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/boards', builder: (context, state) => const BoardsTab()),
      GoRoute(
        path: '/board/:id',
        builder: (context, state) => BoardScreen(boardId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/notes',    builder: (context, state) => const NotesTab()),
      GoRoute(
        path: '/note/:id',
        builder: (context, state) => CreateNoteScreen(noteId: state.pathParameters['id']),
      ),
      GoRoute(path: '/tasks',    builder: (context, state) => const TasksTab()),
      GoRoute(
        path: '/task/:id',
        builder: (context, state) => EditTaskScreen(taskId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      // Create flow
      GoRoute(path: '/create',       builder: (context, state) => const CreateScreen()),
      GoRoute(path: '/create/note',  builder: (context, state) => const CreateNoteScreen()),
      GoRoute(path: '/create/task',  builder: (context, state) => const CreateTaskScreen()),
      GoRoute(path: '/create/board', builder: (context, state) => const CreateBoardScreen()),
    ],
  );
});
