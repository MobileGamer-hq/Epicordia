import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../../data/repository/board_repository.dart';

class BoardScreen extends ConsumerWidget {
  final String boardId;

  const BoardScreen({super.key, required this.boardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final boardsStream = ref.watch(boardRepositoryProvider).watchAllBoards(); // Replace with watchBoardById when available
    
    return ResponsiveScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/boards'),
                ),
                const SizedBox(width: 8),
                Text('Board $boardId', style: theme.textTheme.displayMedium),
              ],
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('List View', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Text('Board content goes here (pins & tasks).', style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
