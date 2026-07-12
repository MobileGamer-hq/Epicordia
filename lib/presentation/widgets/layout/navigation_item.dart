import 'package:flutter/material.dart';

class NavigationItem {
  final String label;
  final IconData icon;
  final String route;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

const List<NavigationItem> appNavItems = [
  NavigationItem(label: 'Home', icon: Icons.home_outlined, route: '/'),
  NavigationItem(label: 'Inbox', icon: Icons.inbox_outlined, route: '/inbox'),
  // Add other roots like Calendar, etc. later when built
];
