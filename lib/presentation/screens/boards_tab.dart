import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/epicordia_card.dart';
import '../../data/repository/board_repository.dart';
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
class _ListView extends StatelessWidget {
  final List<dynamic> boards;
  const _ListView({required this.boards});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark ? EpicordiaColors.textTertiaryDark : EpicordiaColors.textTertiaryLight;
    final iconBg = isDark ? EpicordiaColors.blue900 : EpicordiaColors.blue100;
    final iconClr = isDark ? EpicordiaColors.blue300 : EpicordiaColors.blue700;

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: boards.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final board = boards[index];
        return EpicordiaCard(
          onTap: () => context.push('/board/${board.id}'),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.space_dashboard_outlined,
                  size: 20,
                  color: iconClr,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      board.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '0 items',
                      style: TextStyle(
                        fontSize: 12,
                        color: textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: textTertiary,
              ),
            ],
          ),
        );
      },
    );
  }
}
