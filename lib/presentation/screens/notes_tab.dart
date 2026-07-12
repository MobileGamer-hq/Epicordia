import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/layout/responsive_scaffold.dart';

class NotesTab extends ConsumerWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ResponsiveScaffold(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('All Notes', style: theme.textTheme.displayLarge),
          const SizedBox(height: 32),
          // Flat list placeholder
          Center(
            child: Text('No notes yet.', style: theme.textTheme.bodyLarge),
          )
        ],
      ),
    );
  }
}
