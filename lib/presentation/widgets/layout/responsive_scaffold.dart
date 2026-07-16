import 'package:flutter/material.dart';
import 'app_sidebar.dart';
import 'app_bottom_nav.dart';
import '../features/quick_capture_modal.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const ResponsiveScaffold({super.key, required this.child, this.appBar});

  @override
  Widget build(BuildContext context) {
    final content = SelectionArea(child: child);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth <= 1024;

        if (isMobile) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F7F4),
            appBar: appBar,
            body: content,
            bottomNavigationBar: AppBottomNav(
              onCreateTap: () => showQuickCapture(context),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F7F4),
          appBar: appBar,
          body: Row(
            children: [
              AppSidebar(isTablet: isTablet),
              Expanded(child: content),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showQuickCapture(context),
            backgroundColor: const Color(0xFF0077B6),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Create'),
          ),
        );
      },
    );
  }
}
