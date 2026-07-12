import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/dashboard_screen.dart';
import '../presentation/screens/board_screen.dart';
import '../presentation/screens/inbox_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/board/:id',
        builder: (context, state) {
          final boardId = state.pathParameters['id']!;
          return BoardScreen(boardId: boardId);
        },
      ),
      GoRoute(
        path: '/inbox',
        builder: (context, state) => const InboxScreen(),
      ),
    ],
  );
});
