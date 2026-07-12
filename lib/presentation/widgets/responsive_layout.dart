import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget compact; // Phone < 600px
  final Widget medium; // Tablet 600-1024px
  final Widget expanded; // Desktop > 1024px

  const ResponsiveLayout({
    super.key,
    required this.compact,
    required this.medium,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return compact;
        } else if (constraints.maxWidth < 1024) {
          return medium;
        } else {
          return expanded;
        }
      },
    );
  }
}
