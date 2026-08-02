import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/epicordia_card.dart';
import '../../data/repository/board_repository.dart';
import '../../data/repository/pin_repository.dart';
import '../../data/database/database.dart';
import '../../core/theme.dart';

import 'search_screen.dart';

class BoardsTab extends ConsumerStatefulWidget {
  const BoardsTab({super.key});

  @override
  ConsumerState<BoardsTab> createState() => _BoardsTabState();
}

class _BoardsTabState extends ConsumerState<BoardsTab> {
  bool _isGrid = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSearchScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const EpicordiaSearchScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: const Offset(0.0, -1.0), end: Offset.zero)
              .chain(CurveTween(curve: Curves.fastOutSlowIn));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boardsAsync = ref.watch(boardRepositoryProvider).watchAllBoards();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final cardBg = isDark ? EpicordiaColors.surfaceCardDark : EpicordiaColors.surfaceCardLight;
    final borderClr = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    return ResponsiveScaffold(
      // appBar: EpicordiaAppBar(
      //   onSearch: () => _showSearchScreen(context),
      // ),
      child: Column(
        children: [
          // Header with Title & View Mode Toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Boards',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Visual workspaces for your ideas & tasks',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // IconButton(
                //   icon: Icon(
                //     Icons.search,
                //     color: textPrimary,
                //   ),
                //   onPressed: () => _showSearchScreen(context),
                //   tooltip: 'Global Search',
                // ),
                IconButton(
                  icon: Icon(
                    _isGrid ? Icons.grid_view : Icons.list,
                    color: textPrimary,
                  ),
                  onPressed: () => setState(() => _isGrid = !_isGrid),
                  tooltip: _isGrid ? 'Switch to List View' : 'Switch to Grid View',
                ),
              ],
            ),
          ),
          // Inline Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 14, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Search boards...',
                prefixIcon: Icon(Icons.search, size: 20, color: textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 18, color: textSecondary),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: cardBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderClr),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderClr),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue600),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: boardsAsync,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allBoards = snapshot.data ?? [];
                final boards = _searchQuery.isEmpty
                    ? allBoards
                    : allBoards.where((b) => b.title.toLowerCase().contains(_searchQuery)).toList();

                if (boards.isEmpty) {
                  return _EmptyBoardsState();
                }

                return _isGrid
                    ? _GridView(boards: boards)
                    : _ListView(boards: boards);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Placeholder empty state ─────────────────────────────────────
class _EmptyBoardsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final sunkenBg = isDark ? EpicordiaColors.surfaceSunkenDark : EpicordiaColors.surfaceSunkenLight;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: sunkenBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.space_dashboard_outlined,
              size: 32,
              color: textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No boards yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a board to start organizing visually',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid layout ─────────────────────────────────────────────────
class _GridView extends StatelessWidget {
  final List<dynamic> boards;
  const _GridView({required this.boards});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final width = MediaQuery.of(context).size.width;

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: width > 500 ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: boards.length,
      itemBuilder: (context, index) {
        final board = boards[index];
        final colors = [
          const Color(0xFF8B9DC3),
          const Color(0xFFA8B4C8),
          const Color(0xFF6B7FA0),
          const Color(0xFF9EAAC4),
        ];
        final color = colors[index % colors.length];

        return EpicordiaCard(
          padding: EdgeInsets.zero,
          onTap: () => context.push('/board/${board.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.dashboard_outlined,
                      size: 28,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      board.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '0 items',
                      style: TextStyle(
                        fontSize: 11,
                        color: textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── List layout ─────────────────────────────────────────────────
// ── List layout with Collapsible Board Cards ────────────────────
class _ListView extends StatelessWidget {
  final List<dynamic> boards;
  const _ListView({required this.boards});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: boards.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final board = boards[index];
        return _CollapsibleBoardListCard(board: board);
      },
    );
  }
}

class _CollapsibleBoardListCard extends ConsumerStatefulWidget {
  final dynamic board;
  const _CollapsibleBoardListCard({required this.board});

  @override
  ConsumerState<_CollapsibleBoardListCard> createState() => _CollapsibleBoardListCardState();
}

class _CollapsibleBoardListCardState extends ConsumerState<_CollapsibleBoardListCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textSecondary = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final iconBg = isDark ? EpicordiaColors.blue900 : EpicordiaColors.blue100;
    final iconClr = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue700;
    final borderSubtle = isDark ? EpicordiaColors.borderSubtleDark : EpicordiaColors.borderSubtleLight;

    final pinsStream = ref.watch(pinRepositoryProvider).watchPinsForBoard(board.id);

    return StreamBuilder<List<PinEntity>>(
      stream: pinsStream,
      builder: (context, snapshot) {
        final pins = snapshot.data ?? const <PinEntity>[];
        final noteCount = pins.where((p) => p.type == 'note').length;
        final taskCount = pins.where((p) => p.type == 'task' || p.type == 'tasklist' || p.type == 'checklist').length;
        final frameCount = pins.where((p) => p.type == 'frame').length;
        final itemCount = pins.length;

        return EpicordiaCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row — Tapping toggles collapse/expand or opens board
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/board/${board.id}'),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.space_dashboard_outlined,
                        size: 22,
                        color: iconClr,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            board.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$itemCount items • $noteCount notes • $taskCount tasks',
                            style: TextStyle(
                              fontSize: 12,
                              color: textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    tooltip: _isExpanded ? 'Collapse Board Details' : 'Expand Board Details',
                  ),
                ],
              ),

              // Expanded Detailed Section
              if (_isExpanded) ...[
                const SizedBox(height: 14),
                Divider(height: 1, color: borderSubtle),
                const SizedBox(height: 14),

                // Metrics Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(
                      icon: Icons.sticky_note_2_outlined,
                      label: '$noteCount Notes',
                      isDark: isDark,
                    ),
                    _StatChip(
                      icon: Icons.check_circle_outline,
                      label: '$taskCount Tasks',
                      isDark: isDark,
                    ),
                    _StatChip(
                      icon: Icons.view_column_outlined,
                      label: '$frameCount Frames',
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Preview of items inside board
                Text(
                  'Board Items Preview:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                if (pins.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'No items pinned to this board yet.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textTertiary),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: pins.take(4).map((pin) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              _iconForPinType(pin.type),
                              size: 14,
                              color: iconClr,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _titleForPin(pin),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: textPrimary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 14),

                // Open Board Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconClr,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.launch, size: 18),
                    label: const Text('Open Board Canvas', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () => context.push('/board/${board.id}'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  IconData _iconForPinType(String type) {
    switch (type) {
      case 'note': return Icons.sticky_note_2_outlined;
      case 'task': return Icons.check_circle_outline;
      case 'tasklist': return Icons.checklist;
      case 'checklist': return Icons.shopping_cart_outlined;
      case 'frame': return Icons.view_column_outlined;
      case 'image': return Icons.image_outlined;
      default: return Icons.push_pin_outlined;
    }
  }

  String _titleForPin(PinEntity pin) {
    if (pin.content == null || pin.content!.isEmpty) return 'Untitled item';
    if (pin.content!.startsWith('{') && pin.content!.endsWith('}')) {
      try {
        final map = jsonDecode(pin.content!) as Map<String, dynamic>;
        return map['title'] as String? ?? map['label'] as String? ?? map['text'] as String? ?? 'Untitled item';
      } catch (_) {}
    }
    return pin.content!.split('\n').first;
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF2B2E34) : const Color(0xFFF3F4F6);
    final text = isDark ? EpicordiaColors.textSecondaryDark : EpicordiaColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text),
          ),
        ],
      ),
    );
  }
}
