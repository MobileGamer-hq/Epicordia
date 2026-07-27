import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

class WidgetDeepLinkHandler {
  static StreamSubscription? _sub;

  static void init(BuildContext context, GoRouter router) {
    // Check initial launch payload from widget tap
    HomeWidget.initiallyLaunchedFromHomeWidget().then((Uri? uri) {
      if (uri != null) {
        _handleUri(uri, router);
      }
    });

    // Listen for background-to-foreground widget taps
    _sub?.cancel();
    _sub = HomeWidget.widgetClicked.listen((Uri? uri) {
      if (uri != null) {
        _handleUri(uri, router);
      }
    });
  }

  static void _handleUri(Uri uri, GoRouter router) {
    developer.log('Handling HomeWidget DeepLink: $uri');
    final scheme = uri.scheme;
    final host = uri.host;
    final path = uri.path;

    if (scheme == 'epicordia' || scheme == 'http' || scheme == 'https') {
      switch (host) {
        case 'today':
          router.go('/');
          break;
        case 'capture':
        case 'create':
          router.go('/create/task');
          break;
        case 'unsorted':
          router.go('/tasks'); // Or unsorted filter view
          break;
        case 'calendar':
          router.go('/calendar');
          break;
        case 'task':
          if (path.isNotEmpty) {
            final taskId = path.replaceAll('/', '');
            router.go('/task/$taskId');
          } else {
            router.go('/tasks');
          }
          break;
        default:
          router.go('/');
      }
    }
  }

  static void dispose() {
    _sub?.cancel();
  }
}
