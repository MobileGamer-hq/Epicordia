import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository/task_repository.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/epicordia_card.dart';

class TodayDashboard extends ConsumerWidget {
  const TodayDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // In a real app, this would use a specific query for 'due today'
    // For now, we reuse watchInboxTasks as a stub or just watch all tasks if we build it.
    final tasksAsync = ref.watch(taskRepositoryProvider).watchInboxTasks();

    return ResponsiveScaffold(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Good morning', style: theme.textTheme.displayLarge),
          const SizedBox(height: 8),
          Text('Here is what needs your attention today.', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 32),

          Text('Inbox (Unassigned)', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: tasksAsync,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 48, color: theme.dividerColor),
                        const SizedBox(height: 16),
                        Text('All caught up!', style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
                      ],
                    ),
                  ),
                );
              }

              final tasks = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: EpicordiaCard(
                      child: Row(
                        children: [
                          Checkbox(
                            value: false,
                            onChanged: (val) {
                              // Stub complete logic
                            },
                          ),
                          Expanded(
                            child: Text(
                              task.title,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
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
