import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'core/router.dart';

void main() {
  runApp(const ProviderScope(child: EpicordiaApp()));
}

class EpicordiaApp extends ConsumerWidget {
  const EpicordiaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
