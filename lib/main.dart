import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'core/router.dart';
import 'core/widgets/widget_service.dart';
import 'core/widgets/widget_deep_link_handler.dart';
import 'presentation/widgets/app_lock_wrapper.dart';
import 'domain/services/notification_service.dart';
import 'data/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const ProviderScope(child: EpicordiaApp()));
}

class EpicordiaApp extends ConsumerStatefulWidget {
  const EpicordiaApp({super.key});

  @override
  ConsumerState<EpicordiaApp> createState() => _EpicordiaAppState();
}

class _EpicordiaAppState extends ConsumerState<EpicordiaApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(widgetServiceProvider);
      final router = ref.read(routerProvider);
      WidgetDeepLinkHandler.init(context, router);

      // Perform initial background sync of task and timetable notifications
      final notificationService = NotificationService();
      final taskDao = ref.read(taskDaoProvider);
      final timetableDao = ref.read(timetableDaoProvider);
      await notificationService.syncAllTaskNotifications(taskDao);
      await notificationService.syncAllTimetableSlotNotifications(timetableDao);
    });
  }

  @override
  void dispose() {
    WidgetDeepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final primaryColor = ref.watch(appPrimaryColorProvider);

    return MaterialApp.router(
      title: 'Epicordia',
      theme: EpicordiaTheme.lightTheme(primaryColor),
      darkTheme: EpicordiaTheme.darkTheme(primaryColor),
      themeMode: themeMode,
      routerConfig: goRouter,
      builder: (context, child) {
        return AppLockWrapper(child: child ?? const SizedBox.shrink());
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
