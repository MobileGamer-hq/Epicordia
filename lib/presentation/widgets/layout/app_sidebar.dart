import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'navigation_item.dart';

class AppSidebar extends StatelessWidget {
  final bool isTablet;

  const AppSidebar({super.key, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: isTablet ? 72 : 240,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // App Mark
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'E',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: appNavItems.length,
              itemBuilder: (context, index) {
                final item = appNavItems[index];
                final isActive = location == item.route;
                
                if (isTablet) {
                  // Navigation Rail mode
                  return Tooltip(
                    message: item.label,
                    child: InkWell(
                      onTap: () => context.go(item.route),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.icon,
                          color: isActive ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  );
                }

                // Desktop full sidebar mode
                return InkWell(
                  onTap: () => context.go(item.route),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          color: isActive ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isActive ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
