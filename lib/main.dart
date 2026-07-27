import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'core/router.dart';

import 'core/widgets/widget_service.dart';
import 'core/widgets/widget_deep_link_handler.dart';

void main() {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(widgetServiceProvider);
      final router = ref.read(routerProvider);
      WidgetDeepLinkHandler.init(context, router);
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

    return MaterialApp.router(
      title: 'Epicordia',
      theme: EpicordiaTheme.lightTheme,
      darkTheme: EpicordiaTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
