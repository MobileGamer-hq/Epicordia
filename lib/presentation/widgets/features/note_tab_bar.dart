import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../domain/state/note_workspace_provider.dart';

class NoteTabBar extends StatelessWidget {
  final List<NoteTabItem> tabs;
  final int activeIndex;
  final ValueChanged<int> onTabSelected;
  final ValueChanged<int> onTabClosed;
  final VoidCallback onAddTab;
  final VoidCallback? onToggleSplit;
  final bool isSplit;
  final bool canSplit;
  final void Function(int tabIndex)? onMoveToOtherPane;

  const NoteTabBar({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onAddTab,
    this.onToggleSplit,
    this.isSplit = false,
    this.canSplit = true,
    this.onMoveToOtherPane,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgBar = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;
    final activeTabBg = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceCardLight;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;
    final activeBlue = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: bgBar,
        border: Border(
          bottom: BorderSide(color: borderClr),
        ),
      ),
      child: Row(
        children: [
          // Scrollable Tabs
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isActive = index == activeIndex;

                return GestureDetector(
                  onTap: () => onTabSelected(index),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isActive ? activeTabBg : Colors.transparent,
                      border: Border(
                        right: BorderSide(color: borderClr),
                        top: isActive
                            ? BorderSide(color: activeBlue, width: 2)
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 14,
                          color: isActive ? activeBlue : textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tab.title.isEmpty ? 'Untitled Note' : tab.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isActive ? textPrimary : textTertiary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Tab Context / Close Menu
                        if (isSplit && onMoveToOtherPane != null)
                          PopupMenuButton<String>(
                            tooltip: 'Tab Options',
                            padding: EdgeInsets.zero,
                            iconSize: 14,
                            icon: Icon(Icons.more_vert, size: 14, color: textTertiary),
                            onSelected: (val) {
                              if (val == 'move') {
                                onMoveToOtherPane!(index);
                              } else if (val == 'close') {
                                onTabClosed(index);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'move',
                                child: Text('Move to other pane', style: TextStyle(fontSize: 12)),
                              ),
                              const PopupMenuItem(
                                value: 'close',
                                child: Text('Close tab', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          )
                        else
                          InkWell(
                            onTap: () => onTabClosed(index),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: isActive ? textTertiary : textTertiary.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Add Tab Button
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.add, size: 18, color: textTertiary),
            tooltip: 'New Tab',
            onPressed: onAddTab,
          ),

          // Split Button (if wide screen allows splitting)
          if (canSplit && onToggleSplit != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                isSplit ? Icons.vertical_split : Icons.vertical_split_outlined,
                size: 18,
                color: isSplit ? activeBlue : textTertiary,
              ),
              tooltip: isSplit ? 'Close Split' : 'Split Right',
              onPressed: onToggleSplit,
            ),
        ],
      ),
    );
  }
}
