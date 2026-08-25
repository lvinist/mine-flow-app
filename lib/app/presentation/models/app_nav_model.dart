import 'package:flutter/widgets.dart';

/// Represents an individual navigation item in the application shell.
class AppNavItem {
  final String id;
  final String label;
  final Widget icon;
  final Widget? selectedIcon;
  final String route;
  final int branchIndex;

  const AppNavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.selectedIcon,
    required this.route,
    required this.branchIndex,
  });
}

/// Represents a grouped section of navigation items for sectioned sidebars.
class AppNavGroup {
  final String title;
  final List<AppNavItem> items;

  const AppNavGroup({required this.title, required this.items});
}
