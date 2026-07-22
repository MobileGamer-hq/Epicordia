import 'package:epicorida/data/database/database.dart';

bool createsCycle(String taskId, String dependsOnTaskId, List<TaskDependencyEntity> allDependencies) {
  // If a task depends on itself directly
  if (taskId == dependsOnTaskId) return true;

  // Build an adjacency list mapping from task -> list of tasks it depends on
  Map<String, List<String>> graph = {};
  for (var dep in allDependencies) {
    if (!graph.containsKey(dep.taskId)) {
      graph[dep.taskId] = [];
    }
    graph[dep.taskId]!.add(dep.dependsOnTaskId);
  }

  // To check if adding (taskId -> dependsOnTaskId) creates a cycle,
  // we check if there is an existing path from dependsOnTaskId to taskId.
  // Because if dependsOnTaskId already (transitively) depends on taskId,
  // then making taskId depend on dependsOnTaskId completes a circle.
  
  Set<String> visited = {};
  bool dfs(String current) {
    if (current == taskId) return true;
    if (visited.contains(current)) return false;
    visited.add(current);
    
    if (graph.containsKey(current)) {
      for (var next in graph[current]!) {
        if (dfs(next)) return true;
      }
    }
    return false;
  }

  return dfs(dependsOnTaskId);
}
