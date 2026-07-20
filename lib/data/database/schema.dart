import 'package:drift/drift.dart';

@DataClassName('BoardEntity')
class Boards extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get parentBoardId => text().nullable().references(Boards, #id, onDelete: KeyAction.cascade)();
  TextColumn get defaultViewMode => text().withDefault(const Constant('canvas'))();
  BoolColumn get kanbanEnabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get milestoneDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get modifiedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PinEntity')
class Pins extends Table {
  TextColumn get id => text()();
  TextColumn get boardId => text().nullable().references(Boards, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  RealColumn get x => real().withDefault(const Constant(0.0))();
  RealColumn get y => real().withDefault(const Constant(0.0))();
  RealColumn get width => real().withDefault(const Constant(200.0))();
  RealColumn get height => real().withDefault(const Constant(100.0))();
  IntColumn get zIndex => integer().withDefault(const Constant(0))();
  RealColumn get rotation => real().withDefault(const Constant(0.0))();
  TextColumn get colorTag => text().nullable()();
  TextColumn get content => text().nullable()(); // JSON or raw string depending on type
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get modifiedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskEntity')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get pinId => text().nullable().references(Pins, #id, onDelete: KeyAction.setNull)();
  TextColumn get boardId => text().nullable().references(Boards, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get scheduledDate => dateTime().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('todo'))();
  TextColumn get recurrenceParentId => text().nullable().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get recurrenceRule => text().nullable()();
  TextColumn get calendarEventId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskDependencyEntity')
class TaskDependencies extends Table {
  TextColumn get taskId => text().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get dependsOnTaskId => text().references(Tasks, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {taskId, dependsOnTaskId};
}

@DataClassName('ConnectorEntity')
class Connectors extends Table {
  TextColumn get id => text()();
  TextColumn get boardId => text().references(Boards, #id, onDelete: KeyAction.cascade)();
  TextColumn get fromPinId => text().references(Pins, #id, onDelete: KeyAction.cascade)();
  TextColumn get toPinId => text().references(Pins, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AttachmentEntity')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get pinId => text().references(Pins, #id, onDelete: KeyAction.cascade)();
  TextColumn get filePath => text()();
  TextColumn get fileType => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
