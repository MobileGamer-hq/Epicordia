import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/database/database.dart';
import 'package:app/domain/cycle_detector.dart';

void main() {
  group('Cycle Detection', () {
    test('No dependency should not create cycle', () {
      final deps = <TaskDependencyEntity>[];
      expect(createsCycle('A', 'B', deps), false);
    });

    test('Valid chain should not create cycle (A -> B -> C)', () {
      final deps = [
        const TaskDependencyEntity(taskId: 'A', dependsOnTaskId: 'B'),
        const TaskDependencyEntity(taskId: 'B', dependsOnTaskId: 'C'),
      ];
      // Making C depend on D should be fine
      expect(createsCycle('C', 'D', deps), false);
    });

    test('Direct cycle should be detected (A -> A)', () {
      final deps = <TaskDependencyEntity>[];
      expect(createsCycle('A', 'A', deps), true);
    });

    test('Indirect/transitive cycle should be detected (A -> B -> C -> A)', () {
      final deps = [
        const TaskDependencyEntity(taskId: 'A', dependsOnTaskId: 'B'),
        const TaskDependencyEntity(taskId: 'B', dependsOnTaskId: 'C'),
      ];
      // Trying to make C depend on A creates A -> B -> C -> A
      expect(createsCycle('C', 'A', deps), true);
    });
    
    test('Branching without cycles should not be detected as cycle', () {
      final deps = [
        const TaskDependencyEntity(taskId: 'A', dependsOnTaskId: 'B'),
        const TaskDependencyEntity(taskId: 'A', dependsOnTaskId: 'C'),
      ];
      // B -> D is fine
      expect(createsCycle('B', 'D', deps), false);
    });
  });
}
