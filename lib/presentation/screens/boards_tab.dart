import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/epicordia_brand.dart';
import '../widgets/core/epicordia_card.dart';
import '../../data/repository/board_repository.dart';
import '../../core/theme.dart';

class BoardsTab extends ConsumerStatefulWidget {
  const BoardsTab({super.key});

  @override
  ConsumerState<BoardsTab> createState() => _BoardsTabState();
}

class _BoardsTabState extends ConsumerState<BoardsTab> {
  bool _isGrid = true;

  @override
  Widget build(BuildContext context) {
    final boardsAsync = ref.watch(boardRepositoryProvider).watchAllBoards();

    return ResponsiveScaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: EpicordiaColors.surfaceAppLight,
          elevation: 0,
          titleSpacing: 20,
          title: const EpicordiaLogo(),
          actions: [
            IconButton(
              icon: Icon(_isGrid ? Icons.grid_view : Icons.list, color: EpicordiaColors.textPrimaryLight),
              onPressed: () => setState(() => _isGrid = !_isGrid),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      child: StreamBuilder(
        stream: boardsAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final boards = snapshot.data ?? [];

          if (boards.isEmpty) {
            return _EmptyBoardsState();
          }

          return _isGrid ? _GridView(boards: boards) : _ListView(boards: boards);
        },
      ),
    );
  }
}

// ── Placeholder empty state ─────────────────────────────────────
class _EmptyBoardsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: EpicordiaColors.surfaceSunkenLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.space_dashboard_outlined, size: 32, color: EpicordiaColors.textTertiaryLight),
          ),
          const SizedBox(height: 16),
          const Text('No boards yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight)),
          const SizedBox(height: 8),
          const Text('Create a board to start organizing visually', style: TextStyle(fontSize: 14, color: EpicordiaColors.textSecondaryLight)),
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
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.0,
      ),
      itemCount: boards.length,
      itemBuilder: (context, index) {
        final board = boards[index];
        final colors = [const Color(0xFF8B9DC3), const Color(0xFFA8B4C8), const Color(0xFF6B7FA0), const Color(0xFF9EAAC4)];
        final color = colors[index % colors.length];

        return EpicordiaCard(
          padding: EdgeInsets.zero,
          onTap: () => context.go('/board/${board.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Center(
                    child: Icon(Icons.dashboard_outlined, size: 28, color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(board.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Text('0 items', style: TextStyle(fontSize: 11, color: EpicordiaColors.textTertiaryLight)),
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
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: boards.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final board = boards[index];
        return EpicordiaCard(
          onTap: () => context.go('/board/${board.id}'),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: EpicordiaColors.blue100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.space_dashboard_outlined, size: 20, color: EpicordiaColors.blue700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(board.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: EpicordiaColors.textPrimaryLight)),
                    const Text('0 items', style: TextStyle(fontSize: 12, color: EpicordiaColors.textTertiaryLight)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: EpicordiaColors.textTertiaryLight),
            ],
          ),
        );
      },
    );
  }
}
