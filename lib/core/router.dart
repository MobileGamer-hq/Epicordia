import 'package:go_router/go_router.dart';
import '../presentation/screens/dashboard_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
);
