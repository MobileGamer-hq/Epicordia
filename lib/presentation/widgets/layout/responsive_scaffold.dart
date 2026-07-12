import 'package:flutter/material.dart';
import 'app_sidebar.dart';
import 'app_bottom_nav.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget child;

  const ResponsiveScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Make screen content selectable as requested by the user
    final content = SelectionArea(child: child);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth <= 1024;
        
        if (isMobile) {
          return Scaffold(
            body: content,
            bottomNavigationBar: const AppBottomNav(),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          );
        }

        // Tablet & Desktop layout
        return Scaffold(
          body: Row(
            children: [
              AppSidebar(isTablet: isTablet),
              Expanded(child: content),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
