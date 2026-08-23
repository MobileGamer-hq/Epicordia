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

/// The 4 main nav destinations (Home, Boards, Notes, Tasks)
/// The 5th center slot is the "Create" button, handled separately
const List<NavigationItem> appNavItems = [
  NavigationItem(label: 'Home',   icon: Icons.home_outlined,            route: '/'),
  NavigationItem(label: 'Boards', icon: Icons.space_dashboard_outlined, route: '/boards'),
  NavigationItem(label: 'Notes',  icon: Icons.description_outlined,     route: '/notes'),
  NavigationItem(label: 'Tasks',  icon: Icons.check_circle_outline,     route: '/tasks'),
];

const List<NavigationItem> sidebarNavItems = [
  NavigationItem(label: 'Home',    icon: Icons.home_outlined,            route: '/'),
  NavigationItem(label: 'Reports', icon: Icons.bar_chart_rounded,         route: '/report'),
  NavigationItem(label: 'Boards',  icon: Icons.space_dashboard_outlined, route: '/boards'),
  NavigationItem(label: 'Notes',   icon: Icons.description_outlined,     route: '/notes'),
  NavigationItem(label: 'Tasks',   icon: Icons.check_circle_outline,     route: '/tasks'),
];

/// Popup Menu / Quick Access items for sidebar (Progress, Alarms, Activity, Calendar)
const List<NavigationItem> quickAccessNavItems = [
  NavigationItem(label: 'Progress & Reports',   icon: Icons.bar_chart_rounded,      route: '/report'),
  NavigationItem(label: 'Sessions',             icon: Icons.timer_outlined,         route: '/sessions'),
  NavigationItem(label: 'Activity & Inbox',     icon: Icons.notifications_outlined, route: '/inbox'),
  NavigationItem(label: 'Calendar',             icon: Icons.calendar_today_outlined,route: '/calendar'),
  NavigationItem(label: 'Home Widgets',         icon: Icons.widgets_outlined,       route: '/widgets'),
];


