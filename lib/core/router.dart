import 'package:flutter/material.dart';
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
import '../presentation/screens/alarms_timers_screen.dart';
import '../presentation/screens/inbox_screen.dart';
import '../presentation/screens/report_screen.dart';
import '../presentation/screens/widgets_center_screen.dart';
import '../presentation/widgets/layout/responsive_scaffold.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/screens/task_focus_screen.dart';
import '../domain/models/in_app_alarm_model.dart';
import '../presentation/screens/create_alarm_screen.dart';
import '../presentation/screens/epi_chat_screen.dart';
import '../domain/epi/epi_models.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
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
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Main Shell with Persistent Navigation Bar ──────────────────
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return ResponsiveScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TodayDashboard(),
            ),
          ),
          GoRoute(
            path: '/boards',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BoardsTab(),
            ),
          ),
          GoRoute(
            path: '/notes',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotesTab(),
            ),
          ),
          GoRoute(
            path: '/tasks',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TasksTab(),
            ),
          ),
          GoRoute(
            path: '/report',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportScreen(),
            ),
          ),
        ],
      ),

      // ── Standalone Screens (Nav bar does NOT show) ─────────────────
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/activity',
        builder: (context, state) => const InboxScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/inbox',
        builder: (context, state) => const InboxScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/widgets',
        builder: (context, state) => const WidgetsCenterScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/sessions',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          int idx = 1; // Default to Alarms tab
          if (tab == 'timers') idx = 0;
          if (tab == 'scheduled' || tab == 'schedule') idx = 2;
          if (state.extra is int) idx = state.extra as int;
          return AlarmsTimersScreen(initialIndex: idx);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/alarms',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          int idx = 1; // Default to Alarms tab
          if (tab == 'timers') idx = 0;
          if (tab == 'scheduled' || tab == 'schedule') idx = 2;
          if (state.extra is int) idx = state.extra as int;
          return AlarmsTimersScreen(initialIndex: idx);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/board/:id',
        builder: (context, state) => BoardScreen(boardId: state.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/note/:id',
        builder: (context, state) => CreateNoteScreen(noteId: state.pathParameters['id']),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/task/:id',
        builder: (context, state) => EditTaskScreen(taskId: state.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/task/:id/focus',
        builder: (context, state) => TaskFocusScreen(taskId: state.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/epi',
        builder: (context, state) {
          final boardContext = state.uri.queryParameters['boardContext'] ??
              (state.extra is Map ? (state.extra as Map)['boardTitle'] as String? : null);
          final initialPrompt = state.uri.queryParameters['prompt'] ??
              (state.extra is Map ? (state.extra as Map)['prompt'] as String? : null);
          final initialAttachedItems = state.extra is Map
              ? (state.extra as Map)['attachedItems'] as List<EpiAttachedItem>?
              : (state.extra is List<EpiAttachedItem>
                  ? state.extra as List<EpiAttachedItem>
                  : null);
          return EpiChatScreen(
            initialBoardContext: boardContext,
            initialPrompt: initialPrompt,
            initialAttachedItems: initialAttachedItems,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // Create flow
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/create',
        builder: (context, state) => const CreateScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/create/note',
        builder: (context, state) => const CreateNoteScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/create/task',
        builder: (context, state) => const CreateTaskScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/create/board',
        builder: (context, state) => const CreateBoardScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/create/alarm',
        builder: (context, state) => CreateAlarmScreen(
          alarmToEdit: state.extra is InAppAlarm ? state.extra as InAppAlarm : null,
        ),
      ),
    ],
  );
});
