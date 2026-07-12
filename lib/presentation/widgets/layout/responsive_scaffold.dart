import 'package:flutter/material.dart';
import 'app_sidebar.dart';
import 'app_bottom_nav.dart';
import '../features/quick_capture_modal.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget child;

  const ResponsiveScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // A premium, soft gradient background to make glassmorphism pop
    final backgroundDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                const Color(0xFF101216), // Dark background color
                const Color(0xFF161B22), // Soft dark navy/charcoal shift
              ]
            : [
                const Color(0xFFFAFAF8), // Warm light background color
                const Color(0xFFEFF1F5), // Soft greyish blue shift
              ],
      ),
    );

    // Make screen content selectable as requested by the user
    final content = Container(
      decoration: backgroundDecoration,
      child: SelectionArea(child: child),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth <= 1024;
        
        if (isMobile) {
          return Scaffold(
            body: content,
            bottomNavigationBar: const AppBottomNav(),
            floatingActionButton: FloatingActionButton(
              onPressed: () => showQuickCapture(context),
              backgroundColor: theme.colorScheme.primary,
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
            onPressed: () => showQuickCapture(context),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
