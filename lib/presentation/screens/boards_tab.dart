import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../../data/repository/board_repository.dart';
import '../widgets/core/epicordia_card.dart';

class BoardsTab extends ConsumerWidget {
  const BoardsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final boardsAsync = ref.watch(boardRepositoryProvider).watchAllBoards();

    return ResponsiveScaffold(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Boards', style: theme.textTheme.displayLarge),
          const SizedBox(height: 32),
          StreamBuilder(
            stream: boardsAsync,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('No boards created yet.', style: theme.textTheme.bodyLarge),
                );
              }
              final boards = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: boards.length,
                itemBuilder: (context, index) {
                  final board = boards[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: EpicordiaCard(
                      onTap: () {
                        context.go('/board/${board.id}');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(Icons.dashboard, color: theme.colorScheme.primary),
                            const SizedBox(width: 16),
                            Text(board.title, style: theme.textTheme.titleLarge),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          ),
        ],
      ),
    );
  }
}
