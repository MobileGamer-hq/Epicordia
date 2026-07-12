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
  NavigationItem(label: 'Today', icon: Icons.wb_sunny_outlined, route: '/'),
  NavigationItem(label: 'Boards', icon: Icons.space_dashboard_outlined, route: '/boards'),
  NavigationItem(label: 'Notes', icon: Icons.description_outlined, route: '/notes'),
  NavigationItem(label: 'Tasks', icon: Icons.check_circle_outline, route: '/tasks'),
];
