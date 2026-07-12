import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../../data/repository/task_repository.dart';
import '../widgets/core/epicordia_card.dart';

class TasksTab extends ConsumerWidget {
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(taskRepositoryProvider).watchInboxTasks();

    return ResponsiveScaffold(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('All Tasks', style: theme.textTheme.displayLarge),
          const SizedBox(height: 32),
          StreamBuilder(
            stream: tasksAsync,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('No tasks.', style: theme.textTheme.bodyLarge),
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
                            onChanged: (val) {},
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
