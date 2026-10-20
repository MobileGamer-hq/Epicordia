import 'dart:async';
import 'dart:io' show Platform, File, FileMode;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alarm/alarm.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'core/router.dart';
import 'core/widgets/widget_service.dart';
import 'core/widgets/widget_deep_link_handler.dart';
import 'presentation/widgets/app_lock_wrapper.dart';
import 'presentation/widgets/alarm_ringing_wrapper.dart';
import 'presentation/widgets/layout/floating_epi_chat.dart';
import 'domain/services/notification_service.dart';
import 'data/providers.dart';
import 'data/repository/task_repository.dart';
import 'core/feedback_service.dart';

void _logError(String msg) {
  try {
    debugPrint(msg);
    final file = File('epicordia_crash.log');
    file.writeAsStringSync('${DateTime.now()}: $msg\n\n', mode: FileMode.append);
  } catch (_) {}
}

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _logError('FlutterError: ${details.exceptionAsString()}\n${details.stack}');
    };

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await Alarm.init();
    }

    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
    } catch (e, st) {
      _logError('NotificationService initialization failed: $e\n$st');
    }

    runApp(const ProviderScope(child: EpicordiaApp()));
  }, (error, stack) {
    _logError('Uncaught error in zone: $error\n$stack');
  });
}

class EpicordiaApp extends ConsumerStatefulWidget {
  const EpicordiaApp({super.key});

  @override
  ConsumerState<EpicordiaApp> createState() => _EpicordiaAppState();
}

class _EpicordiaAppState extends ConsumerState<EpicordiaApp> with WidgetsBindingObserver {
  Timer? _recurrenceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        ref.read(widgetServiceProvider);
        final router = ref.read(routerProvider);
        WidgetDeepLinkHandler.init(context, router);
      }

      // Perform initial background sync of task and timetable notifications
      final notificationService = NotificationService();
      final taskDao = ref.read(taskDaoProvider);
      final timetableDao = ref.read(timetableDaoProvider);
      await notificationService.syncAllTaskNotifications(taskDao);
      await notificationService.syncAllTimetableSlotNotifications(timetableDao);

      // Reset completed recurring tasks whose frequency period has arrived
      await ref.read(taskRepositoryProvider).resetCompletedRecurringTasks();

      // Clean up completed tasks exceeding auto-delete retention period
      await ref.read(taskRepositoryProvider).cleanUpCompletedTasks();
    });

    // Check periodically for recurring tasks crossing period boundaries
    _recurrenceTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      ref.read(taskRepositoryProvider).resetCompletedRecurringTasks();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(taskRepositoryProvider).resetCompletedRecurringTasks();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recurrenceTimer?.cancel();
    WidgetDeepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final primaryColor = ref.watch(appPrimaryColorProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: FeedbackService.messengerKey,
      title: 'Epicordia',
      theme: EpicordiaTheme.lightTheme(primaryColor),
      darkTheme: EpicordiaTheme.darkTheme(primaryColor),
      themeMode: themeMode,
      routerConfig: goRouter,
      builder: (context, child) {
        return AppLockWrapper(
          child: AlarmRingingWrapper(
            child: FloatingEpiChatOverlay(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
