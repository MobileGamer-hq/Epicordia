import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import 'navigation_item.dart';

class AppSidebar extends StatelessWidget {
  final bool isTablet;
  const AppSidebar({super.key, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: isTablet ? 72 : 240,
      decoration: const BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        border: Border(right: BorderSide(color: EpicordiaColors.borderSubtleLight)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // App mark
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 20),
            child: isTablet
                ? Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: EpicordiaColors.blue700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.space_dashboard, color: Colors.white, size: 20),
                  )
                : const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Epicordia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: EpicordiaColors.blue700)),
                  ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 12),
              children: [
                if (!isTablet)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('WORKSPACE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EpicordiaColors.textTertiaryLight, letterSpacing: 0.8)),
                  ),
                ...appNavItems.map((item) {
                  final isActive = location == item.route;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () => context.go(item.route),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: isTablet ? 0 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? EpicordiaColors.blue600.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isTablet
                            ? Center(
                                child: Tooltip(
                                  message: item.label,
                                  child: Icon(item.icon, color: isActive ? EpicordiaColors.blue600 : EpicordiaColors.textTertiaryLight, size: 20),
                                ),
                              )
                            : Row(
                                children: [
                                  Icon(item.icon, color: isActive ? EpicordiaColors.blue600 : EpicordiaColors.textSecondaryLight, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                      color: isActive ? EpicordiaColors.blue600 : EpicordiaColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                if (!isTablet)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('QUICK ACCESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: EpicordiaColors.textTertiaryLight, letterSpacing: 0.8)),
                  )
                else
                  const Divider(indent: 8, endIndent: 8, height: 1),
                const SizedBox(height: 4),
                ...quickAccessNavItems.map((item) {
                  final isActive = location == item.route;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () => context.go(item.route),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: isTablet ? 0 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? EpicordiaColors.blue50 : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isTablet
                            ? Center(
                                child: Tooltip(
                                  message: item.label,
                                  child: Icon(item.icon, color: isActive ? EpicordiaColors.blue600 : EpicordiaColors.textTertiaryLight, size: 18),
                                ),
                              )
                            : Row(
                                children: [
                                  Icon(item.icon, color: isActive ? EpicordiaColors.blue600 : EpicordiaColors.textSecondaryLight, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                      color: isActive ? EpicordiaColors.blue600 : EpicordiaColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
