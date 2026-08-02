// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BoardsTable extends Boards with TableInfo<$BoardsTable, BoardEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentBoardIdMeta = const VerificationMeta(
    'parentBoardId',
  );
  @override
  late final GeneratedColumn<String> parentBoardId = GeneratedColumn<String>(
    'parent_board_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boards (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _defaultViewModeMeta = const VerificationMeta(
    'defaultViewMode',
  );
  @override
  late final GeneratedColumn<String> defaultViewMode = GeneratedColumn<String>(
    'default_view_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('canvas'),
  );
  static const VerificationMeta _kanbanEnabledMeta = const VerificationMeta(
    'kanbanEnabled',
  );
  @override
  late final GeneratedColumn<bool> kanbanEnabled = GeneratedColumn<bool>(
    'kanban_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("kanban_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _milestoneDateMeta = const VerificationMeta(
    'milestoneDate',
  );
  @override
  late final GeneratedColumn<DateTime> milestoneDate =
      GeneratedColumn<DateTime>(
        'milestone_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    parentBoardId,
    defaultViewMode,
    kanbanEnabled,
    milestoneDate,
    createdAt,
    modifiedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'boards';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoardEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('parent_board_id')) {
      context.handle(
        _parentBoardIdMeta,
        parentBoardId.isAcceptableOrUnknown(
          data['parent_board_id']!,
          _parentBoardIdMeta,
        ),
      );
    }
    if (data.containsKey('default_view_mode')) {
      context.handle(
        _defaultViewModeMeta,
        defaultViewMode.isAcceptableOrUnknown(
          data['default_view_mode']!,
          _defaultViewModeMeta,
        ),
      );
    }
    if (data.containsKey('kanban_enabled')) {
      context.handle(
        _kanbanEnabledMeta,
        kanbanEnabled.isAcceptableOrUnknown(
          data['kanban_enabled']!,
          _kanbanEnabledMeta,
        ),
      );
    }
    if (data.containsKey('milestone_date')) {
      context.handle(
        _milestoneDateMeta,
        milestoneDate.isAcceptableOrUnknown(
          data['milestone_date']!,
          _milestoneDateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoardEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoardEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      parentBoardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_board_id'],
      ),
      defaultViewMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_view_mode'],
      )!,
      kanbanEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}kanban_enabled'],
      )!,
      milestoneDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}milestone_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
    );
  }

  @override
  $BoardsTable createAlias(String alias) {
    return $BoardsTable(attachedDatabase, alias);
  }
}

class BoardEntity extends DataClass implements Insertable<BoardEntity> {
  final String id;
  final String title;
  final String? parentBoardId;
  final String defaultViewMode;
  final bool kanbanEnabled;
  final DateTime? milestoneDate;
  final DateTime createdAt;
  final DateTime modifiedAt;
  const BoardEntity({
    required this.id,
    required this.title,
    this.parentBoardId,
    required this.defaultViewMode,
    required this.kanbanEnabled,
    this.milestoneDate,
    required this.createdAt,
    required this.modifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || parentBoardId != null) {
      map['parent_board_id'] = Variable<String>(parentBoardId);
    }
    map['default_view_mode'] = Variable<String>(defaultViewMode);
    map['kanban_enabled'] = Variable<bool>(kanbanEnabled);
    if (!nullToAbsent || milestoneDate != null) {
      map['milestone_date'] = Variable<DateTime>(milestoneDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    return map;
  }

  BoardsCompanion toCompanion(bool nullToAbsent) {
    return BoardsCompanion(
      id: Value(id),
      title: Value(title),
      parentBoardId: parentBoardId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentBoardId),
      defaultViewMode: Value(defaultViewMode),
      kanbanEnabled: Value(kanbanEnabled),
      milestoneDate: milestoneDate == null && nullToAbsent
          ? const Value.absent()
          : Value(milestoneDate),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
    );
  }

  factory BoardEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoardEntity(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      parentBoardId: serializer.fromJson<String?>(json['parentBoardId']),
      defaultViewMode: serializer.fromJson<String>(json['defaultViewMode']),
      kanbanEnabled: serializer.fromJson<bool>(json['kanbanEnabled']),
      milestoneDate: serializer.fromJson<DateTime?>(json['milestoneDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'parentBoardId': serializer.toJson<String?>(parentBoardId),
      'defaultViewMode': serializer.toJson<String>(defaultViewMode),
      'kanbanEnabled': serializer.toJson<bool>(kanbanEnabled),
      'milestoneDate': serializer.toJson<DateTime?>(milestoneDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
    };
  }

  BoardEntity copyWith({
    String? id,
    String? title,
    Value<String?> parentBoardId = const Value.absent(),
    String? defaultViewMode,
    bool? kanbanEnabled,
    Value<DateTime?> milestoneDate = const Value.absent(),
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) => BoardEntity(
    id: id ?? this.id,
    title: title ?? this.title,
    parentBoardId: parentBoardId.present
        ? parentBoardId.value
        : this.parentBoardId,
    defaultViewMode: defaultViewMode ?? this.defaultViewMode,
    kanbanEnabled: kanbanEnabled ?? this.kanbanEnabled,
    milestoneDate: milestoneDate.present
        ? milestoneDate.value
        : this.milestoneDate,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
  );
  BoardEntity copyWithCompanion(BoardsCompanion data) {
    return BoardEntity(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      parentBoardId: data.parentBoardId.present
          ? data.parentBoardId.value
          : this.parentBoardId,
      defaultViewMode: data.defaultViewMode.present
          ? data.defaultViewMode.value
          : this.defaultViewMode,
      kanbanEnabled: data.kanbanEnabled.present
          ? data.kanbanEnabled.value
          : this.kanbanEnabled,
      milestoneDate: data.milestoneDate.present
          ? data.milestoneDate.value
          : this.milestoneDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoardEntity(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('parentBoardId: $parentBoardId, ')
          ..write('defaultViewMode: $defaultViewMode, ')
          ..write('kanbanEnabled: $kanbanEnabled, ')
          ..write('milestoneDate: $milestoneDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    parentBoardId,
    defaultViewMode,
    kanbanEnabled,
    milestoneDate,
    createdAt,
    modifiedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardEntity &&
          other.id == this.id &&
          other.title == this.title &&
          other.parentBoardId == this.parentBoardId &&
          other.defaultViewMode == this.defaultViewMode &&
          other.kanbanEnabled == this.kanbanEnabled &&
          other.milestoneDate == this.milestoneDate &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt);
}

class BoardsCompanion extends UpdateCompanion<BoardEntity> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> parentBoardId;
  final Value<String> defaultViewMode;
  final Value<bool> kanbanEnabled;
  final Value<DateTime?> milestoneDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<int> rowid;
  const BoardsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.parentBoardId = const Value.absent(),
    this.defaultViewMode = const Value.absent(),
    this.kanbanEnabled = const Value.absent(),
    this.milestoneDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardsCompanion.insert({
    required String id,
    required String title,
    this.parentBoardId = const Value.absent(),
    this.defaultViewMode = const Value.absent(),
    this.kanbanEnabled = const Value.absent(),
    this.milestoneDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<BoardEntity> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? parentBoardId,
    Expression<String>? defaultViewMode,
    Expression<bool>? kanbanEnabled,
    Expression<DateTime>? milestoneDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (parentBoardId != null) 'parent_board_id': parentBoardId,
      if (defaultViewMode != null) 'default_view_mode': defaultViewMode,
      if (kanbanEnabled != null) 'kanban_enabled': kanbanEnabled,
      if (milestoneDate != null) 'milestone_date': milestoneDate,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? parentBoardId,
    Value<String>? defaultViewMode,
    Value<bool>? kanbanEnabled,
    Value<DateTime?>? milestoneDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<int>? rowid,
  }) {
    return BoardsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      parentBoardId: parentBoardId ?? this.parentBoardId,
      defaultViewMode: defaultViewMode ?? this.defaultViewMode,
      kanbanEnabled: kanbanEnabled ?? this.kanbanEnabled,
      milestoneDate: milestoneDate ?? this.milestoneDate,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (parentBoardId.present) {
      map['parent_board_id'] = Variable<String>(parentBoardId.value);
    }
    if (defaultViewMode.present) {
      map['default_view_mode'] = Variable<String>(defaultViewMode.value);
    }
    if (kanbanEnabled.present) {
      map['kanban_enabled'] = Variable<bool>(kanbanEnabled.value);
    }
    if (milestoneDate.present) {
      map['milestone_date'] = Variable<DateTime>(milestoneDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('parentBoardId: $parentBoardId, ')
          ..write('defaultViewMode: $defaultViewMode, ')
          ..write('kanbanEnabled: $kanbanEnabled, ')
          ..write('milestoneDate: $milestoneDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PinsTable extends Pins with TableInfo<$PinsTable, PinEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PinsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<String> boardId = GeneratedColumn<String>(
    'board_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boards (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(200.0),
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(100.0),
  );
  static const VerificationMeta _zIndexMeta = const VerificationMeta('zIndex');
  @override
  late final GeneratedColumn<int> zIndex = GeneratedColumn<int>(
    'z_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _rotationMeta = const VerificationMeta(
    'rotation',
  );
  @override
  late final GeneratedColumn<double> rotation = GeneratedColumn<double>(
    'rotation',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _colorTagMeta = const VerificationMeta(
    'colorTag',
  );
  @override
  late final GeneratedColumn<String> colorTag = GeneratedColumn<String>(
    'color_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentFrameIdMeta = const VerificationMeta(
    'parentFrameId',
  );
  @override
  late final GeneratedColumn<String> parentFrameId = GeneratedColumn<String>(
    'parent_frame_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pins (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _linkedBoardIdMeta = const VerificationMeta(
    'linkedBoardId',
  );
  @override
  late final GeneratedColumn<String> linkedBoardId = GeneratedColumn<String>(
    'linked_board_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boards (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isLockedMeta = const VerificationMeta(
    'isLocked',
  );
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
    'is_locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _entryDateMeta = const VerificationMeta(
    'entryDate',
  );
  @override
  late final GeneratedColumn<DateTime> entryDate = GeneratedColumn<DateTime>(
    'entry_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    boardId,
    type,
    x,
    y,
    width,
    height,
    zIndex,
    rotation,
    colorTag,
    content,
    parentFrameId,
    linkedBoardId,
    tags,
    isLocked,
    entryDate,
    createdAt,
    modifiedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pins';
  @override
  VerificationContext validateIntegrity(
    Insertable<PinEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('z_index')) {
      context.handle(
        _zIndexMeta,
        zIndex.isAcceptableOrUnknown(data['z_index']!, _zIndexMeta),
      );
    }
    if (data.containsKey('rotation')) {
      context.handle(
        _rotationMeta,
        rotation.isAcceptableOrUnknown(data['rotation']!, _rotationMeta),
      );
    }
    if (data.containsKey('color_tag')) {
      context.handle(
        _colorTagMeta,
        colorTag.isAcceptableOrUnknown(data['color_tag']!, _colorTagMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('parent_frame_id')) {
      context.handle(
        _parentFrameIdMeta,
        parentFrameId.isAcceptableOrUnknown(
          data['parent_frame_id']!,
          _parentFrameIdMeta,
        ),
      );
    }
    if (data.containsKey('linked_board_id')) {
      context.handle(
        _linkedBoardIdMeta,
        linkedBoardId.isAcceptableOrUnknown(
          data['linked_board_id']!,
          _linkedBoardIdMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('is_locked')) {
      context.handle(
        _isLockedMeta,
        isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta),
      );
    }
    if (data.containsKey('entry_date')) {
      context.handle(
        _entryDateMeta,
        entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PinEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PinEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height'],
      )!,
      zIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}z_index'],
      )!,
      rotation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rotation'],
      )!,
      colorTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_tag'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      parentFrameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_frame_id'],
      ),
      linkedBoardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_board_id'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      isLocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_locked'],
      )!,
      entryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}entry_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
    );
  }

  @override
  $PinsTable createAlias(String alias) {
    return $PinsTable(attachedDatabase, alias);
  }
}

class PinEntity extends DataClass implements Insertable<PinEntity> {
  final String id;
  final String? boardId;
  final String type;
  final double x;
  final double y;
  final double width;
  final double height;
  final int zIndex;
  final double rotation;
  final String? colorTag;
  final String? content;
  final String? parentFrameId;
  final String? linkedBoardId;
  final String? tags;
  final bool isLocked;
  final DateTime? entryDate;
  final DateTime createdAt;
  final DateTime modifiedAt;
  const PinEntity({
    required this.id,
    this.boardId,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.zIndex,
    required this.rotation,
    this.colorTag,
    this.content,
    this.parentFrameId,
    this.linkedBoardId,
    this.tags,
    required this.isLocked,
    this.entryDate,
    required this.createdAt,
    required this.modifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || boardId != null) {
      map['board_id'] = Variable<String>(boardId);
    }
    map['type'] = Variable<String>(type);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['width'] = Variable<double>(width);
    map['height'] = Variable<double>(height);
    map['z_index'] = Variable<int>(zIndex);
    map['rotation'] = Variable<double>(rotation);
    if (!nullToAbsent || colorTag != null) {
      map['color_tag'] = Variable<String>(colorTag);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || parentFrameId != null) {
      map['parent_frame_id'] = Variable<String>(parentFrameId);
    }
    if (!nullToAbsent || linkedBoardId != null) {
      map['linked_board_id'] = Variable<String>(linkedBoardId);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['is_locked'] = Variable<bool>(isLocked);
    if (!nullToAbsent || entryDate != null) {
      map['entry_date'] = Variable<DateTime>(entryDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    return map;
  }

  PinsCompanion toCompanion(bool nullToAbsent) {
    return PinsCompanion(
      id: Value(id),
      boardId: boardId == null && nullToAbsent
          ? const Value.absent()
          : Value(boardId),
      type: Value(type),
      x: Value(x),
      y: Value(y),
      width: Value(width),
      height: Value(height),
      zIndex: Value(zIndex),
      rotation: Value(rotation),
      colorTag: colorTag == null && nullToAbsent
          ? const Value.absent()
          : Value(colorTag),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      parentFrameId: parentFrameId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentFrameId),
      linkedBoardId: linkedBoardId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedBoardId),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      isLocked: Value(isLocked),
      entryDate: entryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(entryDate),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
    );
  }

  factory PinEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PinEntity(
      id: serializer.fromJson<String>(json['id']),
      boardId: serializer.fromJson<String?>(json['boardId']),
      type: serializer.fromJson<String>(json['type']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      width: serializer.fromJson<double>(json['width']),
      height: serializer.fromJson<double>(json['height']),
      zIndex: serializer.fromJson<int>(json['zIndex']),
      rotation: serializer.fromJson<double>(json['rotation']),
      colorTag: serializer.fromJson<String?>(json['colorTag']),
      content: serializer.fromJson<String?>(json['content']),
      parentFrameId: serializer.fromJson<String?>(json['parentFrameId']),
      linkedBoardId: serializer.fromJson<String?>(json['linkedBoardId']),
      tags: serializer.fromJson<String?>(json['tags']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      entryDate: serializer.fromJson<DateTime?>(json['entryDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'boardId': serializer.toJson<String?>(boardId),
      'type': serializer.toJson<String>(type),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'width': serializer.toJson<double>(width),
      'height': serializer.toJson<double>(height),
      'zIndex': serializer.toJson<int>(zIndex),
      'rotation': serializer.toJson<double>(rotation),
      'colorTag': serializer.toJson<String?>(colorTag),
      'content': serializer.toJson<String?>(content),
      'parentFrameId': serializer.toJson<String?>(parentFrameId),
      'linkedBoardId': serializer.toJson<String?>(linkedBoardId),
      'tags': serializer.toJson<String?>(tags),
      'isLocked': serializer.toJson<bool>(isLocked),
      'entryDate': serializer.toJson<DateTime?>(entryDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
    };
  }

  PinEntity copyWith({
    String? id,
    Value<String?> boardId = const Value.absent(),
    String? type,
    double? x,
    double? y,
    double? width,
    double? height,
    int? zIndex,
    double? rotation,
    Value<String?> colorTag = const Value.absent(),
    Value<String?> content = const Value.absent(),
    Value<String?> parentFrameId = const Value.absent(),
    Value<String?> linkedBoardId = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    bool? isLocked,
    Value<DateTime?> entryDate = const Value.absent(),
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) => PinEntity(
    id: id ?? this.id,
    boardId: boardId.present ? boardId.value : this.boardId,
    type: type ?? this.type,
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    height: height ?? this.height,
    zIndex: zIndex ?? this.zIndex,
    rotation: rotation ?? this.rotation,
    colorTag: colorTag.present ? colorTag.value : this.colorTag,
    content: content.present ? content.value : this.content,
    parentFrameId: parentFrameId.present
        ? parentFrameId.value
        : this.parentFrameId,
    linkedBoardId: linkedBoardId.present
        ? linkedBoardId.value
        : this.linkedBoardId,
    tags: tags.present ? tags.value : this.tags,
    isLocked: isLocked ?? this.isLocked,
    entryDate: entryDate.present ? entryDate.value : this.entryDate,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
  );
  PinEntity copyWithCompanion(PinsCompanion data) {
    return PinEntity(
      id: data.id.present ? data.id.value : this.id,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      type: data.type.present ? data.type.value : this.type,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      zIndex: data.zIndex.present ? data.zIndex.value : this.zIndex,
      rotation: data.rotation.present ? data.rotation.value : this.rotation,
      colorTag: data.colorTag.present ? data.colorTag.value : this.colorTag,
      content: data.content.present ? data.content.value : this.content,
      parentFrameId: data.parentFrameId.present
          ? data.parentFrameId.value
          : this.parentFrameId,
      linkedBoardId: data.linkedBoardId.present
          ? data.linkedBoardId.value
          : this.linkedBoardId,
      tags: data.tags.present ? data.tags.value : this.tags,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      entryDate: data.entryDate.present ? data.entryDate.value : this.entryDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PinEntity(')
          ..write('id: $id, ')
          ..write('boardId: $boardId, ')
          ..write('type: $type, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('zIndex: $zIndex, ')
          ..write('rotation: $rotation, ')
          ..write('colorTag: $colorTag, ')
          ..write('content: $content, ')
          ..write('parentFrameId: $parentFrameId, ')
          ..write('linkedBoardId: $linkedBoardId, ')
          ..write('tags: $tags, ')
          ..write('isLocked: $isLocked, ')
          ..write('entryDate: $entryDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    boardId,
    type,
    x,
    y,
    width,
    height,
    zIndex,
    rotation,
    colorTag,
    content,
    parentFrameId,
    linkedBoardId,
    tags,
    isLocked,
    entryDate,
    createdAt,
    modifiedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PinEntity &&
          other.id == this.id &&
          other.boardId == this.boardId &&
          other.type == this.type &&
          other.x == this.x &&
          other.y == this.y &&
          other.width == this.width &&
          other.height == this.height &&
          other.zIndex == this.zIndex &&
          other.rotation == this.rotation &&
          other.colorTag == this.colorTag &&
          other.content == this.content &&
          other.parentFrameId == this.parentFrameId &&
          other.linkedBoardId == this.linkedBoardId &&
          other.tags == this.tags &&
          other.isLocked == this.isLocked &&
          other.entryDate == this.entryDate &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt);
}

class PinsCompanion extends UpdateCompanion<PinEntity> {
  final Value<String> id;
  final Value<String?> boardId;
  final Value<String> type;
  final Value<double> x;
  final Value<double> y;
  final Value<double> width;
  final Value<double> height;
  final Value<int> zIndex;
  final Value<double> rotation;
  final Value<String?> colorTag;
  final Value<String?> content;
  final Value<String?> parentFrameId;
  final Value<String?> linkedBoardId;
  final Value<String?> tags;
  final Value<bool> isLocked;
  final Value<DateTime?> entryDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<int> rowid;
  const PinsCompanion({
    this.id = const Value.absent(),
    this.boardId = const Value.absent(),
    this.type = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.zIndex = const Value.absent(),
    this.rotation = const Value.absent(),
    this.colorTag = const Value.absent(),
    this.content = const Value.absent(),
    this.parentFrameId = const Value.absent(),
    this.linkedBoardId = const Value.absent(),
    this.tags = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PinsCompanion.insert({
    required String id,
    this.boardId = const Value.absent(),
    required String type,
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.zIndex = const Value.absent(),
    this.rotation = const Value.absent(),
    this.colorTag = const Value.absent(),
    this.content = const Value.absent(),
    this.parentFrameId = const Value.absent(),
    this.linkedBoardId = const Value.absent(),
    this.tags = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type);
  static Insertable<PinEntity> custom({
    Expression<String>? id,
    Expression<String>? boardId,
    Expression<String>? type,
    Expression<double>? x,
    Expression<double>? y,
    Expression<double>? width,
    Expression<double>? height,
    Expression<int>? zIndex,
    Expression<double>? rotation,
    Expression<String>? colorTag,
    Expression<String>? content,
    Expression<String>? parentFrameId,
    Expression<String>? linkedBoardId,
    Expression<String>? tags,
    Expression<bool>? isLocked,
    Expression<DateTime>? entryDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (boardId != null) 'board_id': boardId,
      if (type != null) 'type': type,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (zIndex != null) 'z_index': zIndex,
      if (rotation != null) 'rotation': rotation,
      if (colorTag != null) 'color_tag': colorTag,
      if (content != null) 'content': content,
      if (parentFrameId != null) 'parent_frame_id': parentFrameId,
      if (linkedBoardId != null) 'linked_board_id': linkedBoardId,
      if (tags != null) 'tags': tags,
      if (isLocked != null) 'is_locked': isLocked,
      if (entryDate != null) 'entry_date': entryDate,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PinsCompanion copyWith({
    Value<String>? id,
    Value<String?>? boardId,
    Value<String>? type,
    Value<double>? x,
    Value<double>? y,
    Value<double>? width,
    Value<double>? height,
    Value<int>? zIndex,
    Value<double>? rotation,
    Value<String?>? colorTag,
    Value<String?>? content,
    Value<String?>? parentFrameId,
    Value<String?>? linkedBoardId,
    Value<String?>? tags,
    Value<bool>? isLocked,
    Value<DateTime?>? entryDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<int>? rowid,
  }) {
    return PinsCompanion(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      zIndex: zIndex ?? this.zIndex,
      rotation: rotation ?? this.rotation,
      colorTag: colorTag ?? this.colorTag,
      content: content ?? this.content,
      parentFrameId: parentFrameId ?? this.parentFrameId,
      linkedBoardId: linkedBoardId ?? this.linkedBoardId,
      tags: tags ?? this.tags,
      isLocked: isLocked ?? this.isLocked,
      entryDate: entryDate ?? this.entryDate,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<String>(boardId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (zIndex.present) {
      map['z_index'] = Variable<int>(zIndex.value);
    }
    if (rotation.present) {
      map['rotation'] = Variable<double>(rotation.value);
    }
    if (colorTag.present) {
      map['color_tag'] = Variable<String>(colorTag.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (parentFrameId.present) {
      map['parent_frame_id'] = Variable<String>(parentFrameId.value);
    }
    if (linkedBoardId.present) {
      map['linked_board_id'] = Variable<String>(linkedBoardId.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (entryDate.present) {
      map['entry_date'] = Variable<DateTime>(entryDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PinsCompanion(')
          ..write('id: $id, ')
          ..write('boardId: $boardId, ')
          ..write('type: $type, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('zIndex: $zIndex, ')
          ..write('rotation: $rotation, ')
          ..write('colorTag: $colorTag, ')
          ..write('content: $content, ')
          ..write('parentFrameId: $parentFrameId, ')
          ..write('linkedBoardId: $linkedBoardId, ')
          ..write('tags: $tags, ')
          ..write('isLocked: $isLocked, ')
          ..write('entryDate: $entryDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinIdMeta = const VerificationMeta('pinId');
  @override
  late final GeneratedColumn<String> pinId = GeneratedColumn<String>(
    'pin_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pins (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<String> boardId = GeneratedColumn<String>(
    'board_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boards (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _groupPinIdMeta = const VerificationMeta(
    'groupPinId',
  );
  @override
  late final GeneratedColumn<String> groupPinId = GeneratedColumn<String>(
    'group_pin_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pins (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledDate =
      GeneratedColumn<DateTime>(
        'scheduled_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('todo'),
  );
  static const VerificationMeta _recurrenceParentIdMeta =
      const VerificationMeta('recurrenceParentId');
  @override
  late final GeneratedColumn<String> recurrenceParentId =
      GeneratedColumn<String>(
        'recurrence_parent_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tasks (id) ON DELETE CASCADE',
        ),
      );
  static const VerificationMeta _recurrenceRuleMeta = const VerificationMeta(
    'recurrenceRule',
  );
  @override
  late final GeneratedColumn<String> recurrenceRule = GeneratedColumn<String>(
    'recurrence_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calendarEventIdMeta = const VerificationMeta(
    'calendarEventId',
  );
  @override
  late final GeneratedColumn<String> calendarEventId = GeneratedColumn<String>(
    'calendar_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _osReminderIdMeta = const VerificationMeta(
    'osReminderId',
  );
  @override
  late final GeneratedColumn<String> osReminderId = GeneratedColumn<String>(
    'os_reminder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pinId,
    boardId,
    groupPinId,
    title,
    notes,
    dueDate,
    scheduledDate,
    priority,
    status,
    recurrenceParentId,
    recurrenceRule,
    calendarEventId,
    osReminderId,
    createdAt,
    modifiedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pin_id')) {
      context.handle(
        _pinIdMeta,
        pinId.isAcceptableOrUnknown(data['pin_id']!, _pinIdMeta),
      );
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    }
    if (data.containsKey('group_pin_id')) {
      context.handle(
        _groupPinIdMeta,
        groupPinId.isAcceptableOrUnknown(
          data['group_pin_id']!,
          _groupPinIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('recurrence_parent_id')) {
      context.handle(
        _recurrenceParentIdMeta,
        recurrenceParentId.isAcceptableOrUnknown(
          data['recurrence_parent_id']!,
          _recurrenceParentIdMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_rule')) {
      context.handle(
        _recurrenceRuleMeta,
        recurrenceRule.isAcceptableOrUnknown(
          data['recurrence_rule']!,
          _recurrenceRuleMeta,
        ),
      );
    }
    if (data.containsKey('calendar_event_id')) {
      context.handle(
        _calendarEventIdMeta,
        calendarEventId.isAcceptableOrUnknown(
          data['calendar_event_id']!,
          _calendarEventIdMeta,
        ),
      );
    }
    if (data.containsKey('os_reminder_id')) {
      context.handle(
        _osReminderIdMeta,
        osReminderId.isAcceptableOrUnknown(
          data['os_reminder_id']!,
          _osReminderIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pinId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_id'],
      ),
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_id'],
      ),
      groupPinId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_pin_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_date'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      recurrenceParentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_parent_id'],
      ),
      recurrenceRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_rule'],
      ),
      calendarEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_event_id'],
      ),
      osReminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}os_reminder_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class TaskEntity extends DataClass implements Insertable<TaskEntity> {
  final String id;
  final String? pinId;
  final String? boardId;
  final String? groupPinId;
  final String title;
  final String? notes;
  final DateTime? dueDate;
  final DateTime? scheduledDate;
  final int priority;
  final String status;
  final String? recurrenceParentId;
  final String? recurrenceRule;
  final String? calendarEventId;
  final String? osReminderId;
  final DateTime createdAt;
  final DateTime modifiedAt;
  const TaskEntity({
    required this.id,
    this.pinId,
    this.boardId,
    this.groupPinId,
    required this.title,
    this.notes,
    this.dueDate,
    this.scheduledDate,
    required this.priority,
    required this.status,
    this.recurrenceParentId,
    this.recurrenceRule,
    this.calendarEventId,
    this.osReminderId,
    required this.createdAt,
    required this.modifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || pinId != null) {
      map['pin_id'] = Variable<String>(pinId);
    }
    if (!nullToAbsent || boardId != null) {
      map['board_id'] = Variable<String>(boardId);
    }
    if (!nullToAbsent || groupPinId != null) {
      map['group_pin_id'] = Variable<String>(groupPinId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || scheduledDate != null) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate);
    }
    map['priority'] = Variable<int>(priority);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || recurrenceParentId != null) {
      map['recurrence_parent_id'] = Variable<String>(recurrenceParentId);
    }
    if (!nullToAbsent || recurrenceRule != null) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule);
    }
    if (!nullToAbsent || calendarEventId != null) {
      map['calendar_event_id'] = Variable<String>(calendarEventId);
    }
    if (!nullToAbsent || osReminderId != null) {
      map['os_reminder_id'] = Variable<String>(osReminderId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      pinId: pinId == null && nullToAbsent
          ? const Value.absent()
          : Value(pinId),
      boardId: boardId == null && nullToAbsent
          ? const Value.absent()
          : Value(boardId),
      groupPinId: groupPinId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupPinId),
      title: Value(title),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      scheduledDate: scheduledDate == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledDate),
      priority: Value(priority),
      status: Value(status),
      recurrenceParentId: recurrenceParentId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceParentId),
      recurrenceRule: recurrenceRule == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceRule),
      calendarEventId: calendarEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(calendarEventId),
      osReminderId: osReminderId == null && nullToAbsent
          ? const Value.absent()
          : Value(osReminderId),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
    );
  }

  factory TaskEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskEntity(
      id: serializer.fromJson<String>(json['id']),
      pinId: serializer.fromJson<String?>(json['pinId']),
      boardId: serializer.fromJson<String?>(json['boardId']),
      groupPinId: serializer.fromJson<String?>(json['groupPinId']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      scheduledDate: serializer.fromJson<DateTime?>(json['scheduledDate']),
      priority: serializer.fromJson<int>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      recurrenceParentId: serializer.fromJson<String?>(
        json['recurrenceParentId'],
      ),
      recurrenceRule: serializer.fromJson<String?>(json['recurrenceRule']),
      calendarEventId: serializer.fromJson<String?>(json['calendarEventId']),
      osReminderId: serializer.fromJson<String?>(json['osReminderId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pinId': serializer.toJson<String?>(pinId),
      'boardId': serializer.toJson<String?>(boardId),
      'groupPinId': serializer.toJson<String?>(groupPinId),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'scheduledDate': serializer.toJson<DateTime?>(scheduledDate),
      'priority': serializer.toJson<int>(priority),
      'status': serializer.toJson<String>(status),
      'recurrenceParentId': serializer.toJson<String?>(recurrenceParentId),
      'recurrenceRule': serializer.toJson<String?>(recurrenceRule),
      'calendarEventId': serializer.toJson<String?>(calendarEventId),
      'osReminderId': serializer.toJson<String?>(osReminderId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
    };
  }

  TaskEntity copyWith({
    String? id,
    Value<String?> pinId = const Value.absent(),
    Value<String?> boardId = const Value.absent(),
    Value<String?> groupPinId = const Value.absent(),
    String? title,
    Value<String?> notes = const Value.absent(),
    Value<DateTime?> dueDate = const Value.absent(),
    Value<DateTime?> scheduledDate = const Value.absent(),
    int? priority,
    String? status,
    Value<String?> recurrenceParentId = const Value.absent(),
    Value<String?> recurrenceRule = const Value.absent(),
    Value<String?> calendarEventId = const Value.absent(),
    Value<String?> osReminderId = const Value.absent(),
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) => TaskEntity(
    id: id ?? this.id,
    pinId: pinId.present ? pinId.value : this.pinId,
    boardId: boardId.present ? boardId.value : this.boardId,
    groupPinId: groupPinId.present ? groupPinId.value : this.groupPinId,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    scheduledDate: scheduledDate.present
        ? scheduledDate.value
        : this.scheduledDate,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    recurrenceParentId: recurrenceParentId.present
        ? recurrenceParentId.value
        : this.recurrenceParentId,
    recurrenceRule: recurrenceRule.present
        ? recurrenceRule.value
        : this.recurrenceRule,
    calendarEventId: calendarEventId.present
        ? calendarEventId.value
        : this.calendarEventId,
    osReminderId: osReminderId.present ? osReminderId.value : this.osReminderId,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
  );
  TaskEntity copyWithCompanion(TasksCompanion data) {
    return TaskEntity(
      id: data.id.present ? data.id.value : this.id,
      pinId: data.pinId.present ? data.pinId.value : this.pinId,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      groupPinId: data.groupPinId.present
          ? data.groupPinId.value
          : this.groupPinId,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      recurrenceParentId: data.recurrenceParentId.present
          ? data.recurrenceParentId.value
          : this.recurrenceParentId,
      recurrenceRule: data.recurrenceRule.present
          ? data.recurrenceRule.value
          : this.recurrenceRule,
      calendarEventId: data.calendarEventId.present
          ? data.calendarEventId.value
          : this.calendarEventId,
      osReminderId: data.osReminderId.present
          ? data.osReminderId.value
          : this.osReminderId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskEntity(')
          ..write('id: $id, ')
          ..write('pinId: $pinId, ')
          ..write('boardId: $boardId, ')
          ..write('groupPinId: $groupPinId, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('dueDate: $dueDate, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('recurrenceParentId: $recurrenceParentId, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('calendarEventId: $calendarEventId, ')
          ..write('osReminderId: $osReminderId, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pinId,
    boardId,
    groupPinId,
    title,
    notes,
    dueDate,
    scheduledDate,
    priority,
    status,
    recurrenceParentId,
    recurrenceRule,
    calendarEventId,
    osReminderId,
    createdAt,
    modifiedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskEntity &&
          other.id == this.id &&
          other.pinId == this.pinId &&
          other.boardId == this.boardId &&
          other.groupPinId == this.groupPinId &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.dueDate == this.dueDate &&
          other.scheduledDate == this.scheduledDate &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.recurrenceParentId == this.recurrenceParentId &&
          other.recurrenceRule == this.recurrenceRule &&
          other.calendarEventId == this.calendarEventId &&
          other.osReminderId == this.osReminderId &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt);
}

class TasksCompanion extends UpdateCompanion<TaskEntity> {
  final Value<String> id;
  final Value<String?> pinId;
  final Value<String?> boardId;
  final Value<String?> groupPinId;
  final Value<String> title;
  final Value<String?> notes;
  final Value<DateTime?> dueDate;
  final Value<DateTime?> scheduledDate;
  final Value<int> priority;
  final Value<String> status;
  final Value<String?> recurrenceParentId;
  final Value<String?> recurrenceRule;
  final Value<String?> calendarEventId;
  final Value<String?> osReminderId;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.pinId = const Value.absent(),
    this.boardId = const Value.absent(),
    this.groupPinId = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.recurrenceParentId = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.calendarEventId = const Value.absent(),
    this.osReminderId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    this.pinId = const Value.absent(),
    this.boardId = const Value.absent(),
    this.groupPinId = const Value.absent(),
    required String title,
    this.notes = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.recurrenceParentId = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.calendarEventId = const Value.absent(),
    this.osReminderId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<TaskEntity> custom({
    Expression<String>? id,
    Expression<String>? pinId,
    Expression<String>? boardId,
    Expression<String>? groupPinId,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? scheduledDate,
    Expression<int>? priority,
    Expression<String>? status,
    Expression<String>? recurrenceParentId,
    Expression<String>? recurrenceRule,
    Expression<String>? calendarEventId,
    Expression<String>? osReminderId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pinId != null) 'pin_id': pinId,
      if (boardId != null) 'board_id': boardId,
      if (groupPinId != null) 'group_pin_id': groupPinId,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (dueDate != null) 'due_date': dueDate,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (recurrenceParentId != null)
        'recurrence_parent_id': recurrenceParentId,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (calendarEventId != null) 'calendar_event_id': calendarEventId,
      if (osReminderId != null) 'os_reminder_id': osReminderId,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String?>? pinId,
    Value<String?>? boardId,
    Value<String?>? groupPinId,
    Value<String>? title,
    Value<String?>? notes,
    Value<DateTime?>? dueDate,
    Value<DateTime?>? scheduledDate,
    Value<int>? priority,
    Value<String>? status,
    Value<String?>? recurrenceParentId,
    Value<String?>? recurrenceRule,
    Value<String?>? calendarEventId,
    Value<String?>? osReminderId,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      pinId: pinId ?? this.pinId,
      boardId: boardId ?? this.boardId,
      groupPinId: groupPinId ?? this.groupPinId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      recurrenceParentId: recurrenceParentId ?? this.recurrenceParentId,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      osReminderId: osReminderId ?? this.osReminderId,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pinId.present) {
      map['pin_id'] = Variable<String>(pinId.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<String>(boardId.value);
    }
    if (groupPinId.present) {
      map['group_pin_id'] = Variable<String>(groupPinId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<DateTime>(scheduledDate.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (recurrenceParentId.present) {
      map['recurrence_parent_id'] = Variable<String>(recurrenceParentId.value);
    }
    if (recurrenceRule.present) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule.value);
    }
    if (calendarEventId.present) {
      map['calendar_event_id'] = Variable<String>(calendarEventId.value);
    }
    if (osReminderId.present) {
      map['os_reminder_id'] = Variable<String>(osReminderId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('pinId: $pinId, ')
          ..write('boardId: $boardId, ')
          ..write('groupPinId: $groupPinId, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('dueDate: $dueDate, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('recurrenceParentId: $recurrenceParentId, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('calendarEventId: $calendarEventId, ')
          ..write('osReminderId: $osReminderId, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskDependenciesTable extends TaskDependencies
    with TableInfo<$TaskDependenciesTable, TaskDependencyEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskDependenciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dependsOnTaskIdMeta = const VerificationMeta(
    'dependsOnTaskId',
  );
  @override
  late final GeneratedColumn<String> dependsOnTaskId = GeneratedColumn<String>(
    'depends_on_task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [taskId, dependsOnTaskId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_dependencies';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskDependencyEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('depends_on_task_id')) {
      context.handle(
        _dependsOnTaskIdMeta,
        dependsOnTaskId.isAcceptableOrUnknown(
          data['depends_on_task_id']!,
          _dependsOnTaskIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dependsOnTaskIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId, dependsOnTaskId};
  @override
  TaskDependencyEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskDependencyEntity(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      dependsOnTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}depends_on_task_id'],
      )!,
    );
  }

  @override
  $TaskDependenciesTable createAlias(String alias) {
    return $TaskDependenciesTable(attachedDatabase, alias);
  }
}

class TaskDependencyEntity extends DataClass
    implements Insertable<TaskDependencyEntity> {
  final String taskId;
  final String dependsOnTaskId;
  const TaskDependencyEntity({
    required this.taskId,
    required this.dependsOnTaskId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['depends_on_task_id'] = Variable<String>(dependsOnTaskId);
    return map;
  }

  TaskDependenciesCompanion toCompanion(bool nullToAbsent) {
    return TaskDependenciesCompanion(
      taskId: Value(taskId),
      dependsOnTaskId: Value(dependsOnTaskId),
    );
  }

  factory TaskDependencyEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskDependencyEntity(
      taskId: serializer.fromJson<String>(json['taskId']),
      dependsOnTaskId: serializer.fromJson<String>(json['dependsOnTaskId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'dependsOnTaskId': serializer.toJson<String>(dependsOnTaskId),
    };
  }

  TaskDependencyEntity copyWith({String? taskId, String? dependsOnTaskId}) =>
      TaskDependencyEntity(
        taskId: taskId ?? this.taskId,
        dependsOnTaskId: dependsOnTaskId ?? this.dependsOnTaskId,
      );
  TaskDependencyEntity copyWithCompanion(TaskDependenciesCompanion data) {
    return TaskDependencyEntity(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      dependsOnTaskId: data.dependsOnTaskId.present
          ? data.dependsOnTaskId.value
          : this.dependsOnTaskId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskDependencyEntity(')
          ..write('taskId: $taskId, ')
          ..write('dependsOnTaskId: $dependsOnTaskId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskId, dependsOnTaskId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskDependencyEntity &&
          other.taskId == this.taskId &&
          other.dependsOnTaskId == this.dependsOnTaskId);
}

class TaskDependenciesCompanion extends UpdateCompanion<TaskDependencyEntity> {
  final Value<String> taskId;
  final Value<String> dependsOnTaskId;
  final Value<int> rowid;
  const TaskDependenciesCompanion({
    this.taskId = const Value.absent(),
    this.dependsOnTaskId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskDependenciesCompanion.insert({
    required String taskId,
    required String dependsOnTaskId,
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       dependsOnTaskId = Value(dependsOnTaskId);
  static Insertable<TaskDependencyEntity> custom({
    Expression<String>? taskId,
    Expression<String>? dependsOnTaskId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (dependsOnTaskId != null) 'depends_on_task_id': dependsOnTaskId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskDependenciesCompanion copyWith({
    Value<String>? taskId,
    Value<String>? dependsOnTaskId,
    Value<int>? rowid,
  }) {
    return TaskDependenciesCompanion(
      taskId: taskId ?? this.taskId,
      dependsOnTaskId: dependsOnTaskId ?? this.dependsOnTaskId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (dependsOnTaskId.present) {
      map['depends_on_task_id'] = Variable<String>(dependsOnTaskId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskDependenciesCompanion(')
          ..write('taskId: $taskId, ')
          ..write('dependsOnTaskId: $dependsOnTaskId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConnectorsTable extends Connectors
    with TableInfo<$ConnectorsTable, ConnectorEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<String> boardId = GeneratedColumn<String>(
    'board_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boards (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fromPinIdMeta = const VerificationMeta(
    'fromPinId',
  );
  @override
  late final GeneratedColumn<String> fromPinId = GeneratedColumn<String>(
    'from_pin_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pins (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _toPinIdMeta = const VerificationMeta(
    'toPinId',
  );
  @override
  late final GeneratedColumn<String> toPinId = GeneratedColumn<String>(
    'to_pin_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pins (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
    'style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('straight'),
  );
  static const VerificationMeta _bendOffsetXMeta = const VerificationMeta(
    'bendOffsetX',
  );
  @override
  late final GeneratedColumn<double> bendOffsetX = GeneratedColumn<double>(
    'bend_offset_x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bendOffsetYMeta = const VerificationMeta(
    'bendOffsetY',
  );
  @override
  late final GeneratedColumn<double> bendOffsetY = GeneratedColumn<double>(
    'bend_offset_y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    boardId,
    fromPinId,
    toPinId,
    label,
    style,
    bendOffsetX,
    bendOffsetY,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connectors';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConnectorEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boardIdMeta);
    }
    if (data.containsKey('from_pin_id')) {
      context.handle(
        _fromPinIdMeta,
        fromPinId.isAcceptableOrUnknown(data['from_pin_id']!, _fromPinIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fromPinIdMeta);
    }
    if (data.containsKey('to_pin_id')) {
      context.handle(
        _toPinIdMeta,
        toPinId.isAcceptableOrUnknown(data['to_pin_id']!, _toPinIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toPinIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('style')) {
      context.handle(
        _styleMeta,
        style.isAcceptableOrUnknown(data['style']!, _styleMeta),
      );
    }
    if (data.containsKey('bend_offset_x')) {
      context.handle(
        _bendOffsetXMeta,
        bendOffsetX.isAcceptableOrUnknown(
          data['bend_offset_x']!,
          _bendOffsetXMeta,
        ),
      );
    }
    if (data.containsKey('bend_offset_y')) {
      context.handle(
        _bendOffsetYMeta,
        bendOffsetY.isAcceptableOrUnknown(
          data['bend_offset_y']!,
          _bendOffsetYMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConnectorEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConnectorEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_id'],
      )!,
      fromPinId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_pin_id'],
      )!,
      toPinId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_pin_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      style: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style'],
      )!,
      bendOffsetX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bend_offset_x'],
      ),
      bendOffsetY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bend_offset_y'],
      ),
    );
  }

  @override
  $ConnectorsTable createAlias(String alias) {
    return $ConnectorsTable(attachedDatabase, alias);
  }
}

class ConnectorEntity extends DataClass implements Insertable<ConnectorEntity> {
  final String id;
  final String boardId;
  final String fromPinId;
  final String toPinId;
  final String? label;
  final String style;
  final double? bendOffsetX;
  final double? bendOffsetY;
  const ConnectorEntity({
    required this.id,
    required this.boardId,
    required this.fromPinId,
    required this.toPinId,
    this.label,
    required this.style,
    this.bendOffsetX,
    this.bendOffsetY,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['board_id'] = Variable<String>(boardId);
    map['from_pin_id'] = Variable<String>(fromPinId);
    map['to_pin_id'] = Variable<String>(toPinId);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['style'] = Variable<String>(style);
    if (!nullToAbsent || bendOffsetX != null) {
      map['bend_offset_x'] = Variable<double>(bendOffsetX);
    }
    if (!nullToAbsent || bendOffsetY != null) {
      map['bend_offset_y'] = Variable<double>(bendOffsetY);
    }
    return map;
  }

  ConnectorsCompanion toCompanion(bool nullToAbsent) {
    return ConnectorsCompanion(
      id: Value(id),
      boardId: Value(boardId),
      fromPinId: Value(fromPinId),
      toPinId: Value(toPinId),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      style: Value(style),
      bendOffsetX: bendOffsetX == null && nullToAbsent
          ? const Value.absent()
          : Value(bendOffsetX),
      bendOffsetY: bendOffsetY == null && nullToAbsent
          ? const Value.absent()
          : Value(bendOffsetY),
    );
  }

  factory ConnectorEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConnectorEntity(
      id: serializer.fromJson<String>(json['id']),
      boardId: serializer.fromJson<String>(json['boardId']),
      fromPinId: serializer.fromJson<String>(json['fromPinId']),
      toPinId: serializer.fromJson<String>(json['toPinId']),
      label: serializer.fromJson<String?>(json['label']),
      style: serializer.fromJson<String>(json['style']),
      bendOffsetX: serializer.fromJson<double?>(json['bendOffsetX']),
      bendOffsetY: serializer.fromJson<double?>(json['bendOffsetY']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'boardId': serializer.toJson<String>(boardId),
      'fromPinId': serializer.toJson<String>(fromPinId),
      'toPinId': serializer.toJson<String>(toPinId),
      'label': serializer.toJson<String?>(label),
      'style': serializer.toJson<String>(style),
      'bendOffsetX': serializer.toJson<double?>(bendOffsetX),
      'bendOffsetY': serializer.toJson<double?>(bendOffsetY),
    };
  }

  ConnectorEntity copyWith({
    String? id,
    String? boardId,
    String? fromPinId,
    String? toPinId,
    Value<String?> label = const Value.absent(),
    String? style,
    Value<double?> bendOffsetX = const Value.absent(),
    Value<double?> bendOffsetY = const Value.absent(),
  }) => ConnectorEntity(
    id: id ?? this.id,
    boardId: boardId ?? this.boardId,
    fromPinId: fromPinId ?? this.fromPinId,
    toPinId: toPinId ?? this.toPinId,
    label: label.present ? label.value : this.label,
    style: style ?? this.style,
    bendOffsetX: bendOffsetX.present ? bendOffsetX.value : this.bendOffsetX,
    bendOffsetY: bendOffsetY.present ? bendOffsetY.value : this.bendOffsetY,
  );
  ConnectorEntity copyWithCompanion(ConnectorsCompanion data) {
    return ConnectorEntity(
      id: data.id.present ? data.id.value : this.id,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      fromPinId: data.fromPinId.present ? data.fromPinId.value : this.fromPinId,
      toPinId: data.toPinId.present ? data.toPinId.value : this.toPinId,
      label: data.label.present ? data.label.value : this.label,
      style: data.style.present ? data.style.value : this.style,
      bendOffsetX: data.bendOffsetX.present
          ? data.bendOffsetX.value
          : this.bendOffsetX,
      bendOffsetY: data.bendOffsetY.present
          ? data.bendOffsetY.value
          : this.bendOffsetY,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConnectorEntity(')
          ..write('id: $id, ')
          ..write('boardId: $boardId, ')
          ..write('fromPinId: $fromPinId, ')
          ..write('toPinId: $toPinId, ')
          ..write('label: $label, ')
          ..write('style: $style, ')
          ..write('bendOffsetX: $bendOffsetX, ')
          ..write('bendOffsetY: $bendOffsetY')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    boardId,
    fromPinId,
    toPinId,
    label,
    style,
    bendOffsetX,
    bendOffsetY,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConnectorEntity &&
          other.id == this.id &&
          other.boardId == this.boardId &&
          other.fromPinId == this.fromPinId &&
          other.toPinId == this.toPinId &&
          other.label == this.label &&
          other.style == this.style &&
          other.bendOffsetX == this.bendOffsetX &&
          other.bendOffsetY == this.bendOffsetY);
}

class ConnectorsCompanion extends UpdateCompanion<ConnectorEntity> {
  final Value<String> id;
  final Value<String> boardId;
  final Value<String> fromPinId;
  final Value<String> toPinId;
  final Value<String?> label;
  final Value<String> style;
  final Value<double?> bendOffsetX;
  final Value<double?> bendOffsetY;
  final Value<int> rowid;
  const ConnectorsCompanion({
    this.id = const Value.absent(),
    this.boardId = const Value.absent(),
    this.fromPinId = const Value.absent(),
    this.toPinId = const Value.absent(),
    this.label = const Value.absent(),
    this.style = const Value.absent(),
    this.bendOffsetX = const Value.absent(),
    this.bendOffsetY = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConnectorsCompanion.insert({
    required String id,
    required String boardId,
    required String fromPinId,
    required String toPinId,
    this.label = const Value.absent(),
    this.style = const Value.absent(),
    this.bendOffsetX = const Value.absent(),
    this.bendOffsetY = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       boardId = Value(boardId),
       fromPinId = Value(fromPinId),
       toPinId = Value(toPinId);
  static Insertable<ConnectorEntity> custom({
    Expression<String>? id,
    Expression<String>? boardId,
    Expression<String>? fromPinId,
    Expression<String>? toPinId,
    Expression<String>? label,
    Expression<String>? style,
    Expression<double>? bendOffsetX,
    Expression<double>? bendOffsetY,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (boardId != null) 'board_id': boardId,
      if (fromPinId != null) 'from_pin_id': fromPinId,
      if (toPinId != null) 'to_pin_id': toPinId,
      if (label != null) 'label': label,
      if (style != null) 'style': style,
      if (bendOffsetX != null) 'bend_offset_x': bendOffsetX,
      if (bendOffsetY != null) 'bend_offset_y': bendOffsetY,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConnectorsCompanion copyWith({
    Value<String>? id,
    Value<String>? boardId,
    Value<String>? fromPinId,
    Value<String>? toPinId,
    Value<String?>? label,
    Value<String>? style,
    Value<double?>? bendOffsetX,
    Value<double?>? bendOffsetY,
    Value<int>? rowid,
  }) {
    return ConnectorsCompanion(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      fromPinId: fromPinId ?? this.fromPinId,
      toPinId: toPinId ?? this.toPinId,
      label: label ?? this.label,
      style: style ?? this.style,
      bendOffsetX: bendOffsetX ?? this.bendOffsetX,
      bendOffsetY: bendOffsetY ?? this.bendOffsetY,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<String>(boardId.value);
    }
    if (fromPinId.present) {
      map['from_pin_id'] = Variable<String>(fromPinId.value);
    }
    if (toPinId.present) {
      map['to_pin_id'] = Variable<String>(toPinId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (bendOffsetX.present) {
      map['bend_offset_x'] = Variable<double>(bendOffsetX.value);
    }
    if (bendOffsetY.present) {
      map['bend_offset_y'] = Variable<double>(bendOffsetY.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectorsCompanion(')
          ..write('id: $id, ')
          ..write('boardId: $boardId, ')
          ..write('fromPinId: $fromPinId, ')
          ..write('toPinId: $toPinId, ')
          ..write('label: $label, ')
          ..write('style: $style, ')
          ..write('bendOffsetX: $bendOffsetX, ')
          ..write('bendOffsetY: $bendOffsetY, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, AttachmentEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinIdMeta = const VerificationMeta('pinId');
  @override
  late final GeneratedColumn<String> pinId = GeneratedColumn<String>(
    'pin_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pins (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileTypeMeta = const VerificationMeta(
    'fileType',
  );
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
    'file_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pinId,
    filePath,
    fileType,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttachmentEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pin_id')) {
      context.handle(
        _pinIdMeta,
        pinId.isAcceptableOrUnknown(data['pin_id']!, _pinIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pinIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_type')) {
      context.handle(
        _fileTypeMeta,
        fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttachmentEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pinId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class AttachmentEntity extends DataClass
    implements Insertable<AttachmentEntity> {
  final String id;
  final String pinId;
  final String filePath;
  final String fileType;
  final DateTime createdAt;
  const AttachmentEntity({
    required this.id,
    required this.pinId,
    required this.filePath,
    required this.fileType,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pin_id'] = Variable<String>(pinId);
    map['file_path'] = Variable<String>(filePath);
    map['file_type'] = Variable<String>(fileType);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      pinId: Value(pinId),
      filePath: Value(filePath),
      fileType: Value(fileType),
      createdAt: Value(createdAt),
    );
  }

  factory AttachmentEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentEntity(
      id: serializer.fromJson<String>(json['id']),
      pinId: serializer.fromJson<String>(json['pinId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileType: serializer.fromJson<String>(json['fileType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pinId': serializer.toJson<String>(pinId),
      'filePath': serializer.toJson<String>(filePath),
      'fileType': serializer.toJson<String>(fileType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AttachmentEntity copyWith({
    String? id,
    String? pinId,
    String? filePath,
    String? fileType,
    DateTime? createdAt,
  }) => AttachmentEntity(
    id: id ?? this.id,
    pinId: pinId ?? this.pinId,
    filePath: filePath ?? this.filePath,
    fileType: fileType ?? this.fileType,
    createdAt: createdAt ?? this.createdAt,
  );
  AttachmentEntity copyWithCompanion(AttachmentsCompanion data) {
    return AttachmentEntity(
      id: data.id.present ? data.id.value : this.id,
      pinId: data.pinId.present ? data.pinId.value : this.pinId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentEntity(')
          ..write('id: $id, ')
          ..write('pinId: $pinId, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pinId, filePath, fileType, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentEntity &&
          other.id == this.id &&
          other.pinId == this.pinId &&
          other.filePath == this.filePath &&
          other.fileType == this.fileType &&
          other.createdAt == this.createdAt);
}

class AttachmentsCompanion extends UpdateCompanion<AttachmentEntity> {
  final Value<String> id;
  final Value<String> pinId;
  final Value<String> filePath;
  final Value<String> fileType;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.pinId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String pinId,
    required String filePath,
    required String fileType,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pinId = Value(pinId),
       filePath = Value(filePath),
       fileType = Value(fileType);
  static Insertable<AttachmentEntity> custom({
    Expression<String>? id,
    Expression<String>? pinId,
    Expression<String>? filePath,
    Expression<String>? fileType,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pinId != null) 'pin_id': pinId,
      if (filePath != null) 'file_path': filePath,
      if (fileType != null) 'file_type': fileType,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? pinId,
    Value<String>? filePath,
    Value<String>? fileType,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      pinId: pinId ?? this.pinId,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pinId.present) {
      map['pin_id'] = Variable<String>(pinId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('pinId: $pinId, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimetableSlotsTable extends TimetableSlots
    with TableInfo<$TimetableSlotsTable, TimetableSlotEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimetableSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorTagMeta = const VerificationMeta(
    'colorTag',
  );
  @override
  late final GeneratedColumn<String> colorTag = GeneratedColumn<String>(
    'color_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _boardIdMeta = const VerificationMeta(
    'boardId',
  );
  @override
  late final GeneratedColumn<String> boardId = GeneratedColumn<String>(
    'board_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES boards (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderMinutesBeforeMeta =
      const VerificationMeta('reminderMinutesBefore');
  @override
  late final GeneratedColumn<int> reminderMinutesBefore = GeneratedColumn<int>(
    'reminder_minutes_before',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    location,
    dayOfWeek,
    startTime,
    endTime,
    colorTag,
    boardId,
    notes,
    reminderMinutesBefore,
    createdAt,
    modifiedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timetable_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimetableSlotEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    } else if (isInserting) {
      context.missing(_dayOfWeekMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('color_tag')) {
      context.handle(
        _colorTagMeta,
        colorTag.isAcceptableOrUnknown(data['color_tag']!, _colorTagMeta),
      );
    }
    if (data.containsKey('board_id')) {
      context.handle(
        _boardIdMeta,
        boardId.isAcceptableOrUnknown(data['board_id']!, _boardIdMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('reminder_minutes_before')) {
      context.handle(
        _reminderMinutesBeforeMeta,
        reminderMinutesBefore.isAcceptableOrUnknown(
          data['reminder_minutes_before']!,
          _reminderMinutesBeforeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimetableSlotEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimetableSlotEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_week'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      )!,
      colorTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_tag'],
      ),
      boardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}board_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      reminderMinutesBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes_before'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
    );
  }

  @override
  $TimetableSlotsTable createAlias(String alias) {
    return $TimetableSlotsTable(attachedDatabase, alias);
  }
}

class TimetableSlotEntity extends DataClass
    implements Insertable<TimetableSlotEntity> {
  final String id;
  final String title;
  final String? location;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? colorTag;
  final String? boardId;
  final String? notes;
  final int? reminderMinutesBefore;
  final DateTime createdAt;
  final DateTime modifiedAt;
  const TimetableSlotEntity({
    required this.id,
    required this.title,
    this.location,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.colorTag,
    this.boardId,
    this.notes,
    this.reminderMinutesBefore,
    required this.createdAt,
    required this.modifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['day_of_week'] = Variable<int>(dayOfWeek);
    map['start_time'] = Variable<String>(startTime);
    map['end_time'] = Variable<String>(endTime);
    if (!nullToAbsent || colorTag != null) {
      map['color_tag'] = Variable<String>(colorTag);
    }
    if (!nullToAbsent || boardId != null) {
      map['board_id'] = Variable<String>(boardId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || reminderMinutesBefore != null) {
      map['reminder_minutes_before'] = Variable<int>(reminderMinutesBefore);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    return map;
  }

  TimetableSlotsCompanion toCompanion(bool nullToAbsent) {
    return TimetableSlotsCompanion(
      id: Value(id),
      title: Value(title),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      dayOfWeek: Value(dayOfWeek),
      startTime: Value(startTime),
      endTime: Value(endTime),
      colorTag: colorTag == null && nullToAbsent
          ? const Value.absent()
          : Value(colorTag),
      boardId: boardId == null && nullToAbsent
          ? const Value.absent()
          : Value(boardId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      reminderMinutesBefore: reminderMinutesBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinutesBefore),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
    );
  }

  factory TimetableSlotEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimetableSlotEntity(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      location: serializer.fromJson<String?>(json['location']),
      dayOfWeek: serializer.fromJson<int>(json['dayOfWeek']),
      startTime: serializer.fromJson<String>(json['startTime']),
      endTime: serializer.fromJson<String>(json['endTime']),
      colorTag: serializer.fromJson<String?>(json['colorTag']),
      boardId: serializer.fromJson<String?>(json['boardId']),
      notes: serializer.fromJson<String?>(json['notes']),
      reminderMinutesBefore: serializer.fromJson<int?>(
        json['reminderMinutesBefore'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'location': serializer.toJson<String?>(location),
      'dayOfWeek': serializer.toJson<int>(dayOfWeek),
      'startTime': serializer.toJson<String>(startTime),
      'endTime': serializer.toJson<String>(endTime),
      'colorTag': serializer.toJson<String?>(colorTag),
      'boardId': serializer.toJson<String?>(boardId),
      'notes': serializer.toJson<String?>(notes),
      'reminderMinutesBefore': serializer.toJson<int?>(reminderMinutesBefore),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
    };
  }

  TimetableSlotEntity copyWith({
    String? id,
    String? title,
    Value<String?> location = const Value.absent(),
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    Value<String?> colorTag = const Value.absent(),
    Value<String?> boardId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<int?> reminderMinutesBefore = const Value.absent(),
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) => TimetableSlotEntity(
    id: id ?? this.id,
    title: title ?? this.title,
    location: location.present ? location.value : this.location,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    colorTag: colorTag.present ? colorTag.value : this.colorTag,
    boardId: boardId.present ? boardId.value : this.boardId,
    notes: notes.present ? notes.value : this.notes,
    reminderMinutesBefore: reminderMinutesBefore.present
        ? reminderMinutesBefore.value
        : this.reminderMinutesBefore,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
  );
  TimetableSlotEntity copyWithCompanion(TimetableSlotsCompanion data) {
    return TimetableSlotEntity(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      location: data.location.present ? data.location.value : this.location,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      colorTag: data.colorTag.present ? data.colorTag.value : this.colorTag,
      boardId: data.boardId.present ? data.boardId.value : this.boardId,
      notes: data.notes.present ? data.notes.value : this.notes,
      reminderMinutesBefore: data.reminderMinutesBefore.present
          ? data.reminderMinutesBefore.value
          : this.reminderMinutesBefore,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimetableSlotEntity(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('location: $location, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('colorTag: $colorTag, ')
          ..write('boardId: $boardId, ')
          ..write('notes: $notes, ')
          ..write('reminderMinutesBefore: $reminderMinutesBefore, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    location,
    dayOfWeek,
    startTime,
    endTime,
    colorTag,
    boardId,
    notes,
    reminderMinutesBefore,
    createdAt,
    modifiedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimetableSlotEntity &&
          other.id == this.id &&
          other.title == this.title &&
          other.location == this.location &&
          other.dayOfWeek == this.dayOfWeek &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.colorTag == this.colorTag &&
          other.boardId == this.boardId &&
          other.notes == this.notes &&
          other.reminderMinutesBefore == this.reminderMinutesBefore &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt);
}

class TimetableSlotsCompanion extends UpdateCompanion<TimetableSlotEntity> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> location;
  final Value<int> dayOfWeek;
  final Value<String> startTime;
  final Value<String> endTime;
  final Value<String?> colorTag;
  final Value<String?> boardId;
  final Value<String?> notes;
  final Value<int?> reminderMinutesBefore;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<int> rowid;
  const TimetableSlotsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.location = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.colorTag = const Value.absent(),
    this.boardId = const Value.absent(),
    this.notes = const Value.absent(),
    this.reminderMinutesBefore = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimetableSlotsCompanion.insert({
    required String id,
    required String title,
    this.location = const Value.absent(),
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    this.colorTag = const Value.absent(),
    this.boardId = const Value.absent(),
    this.notes = const Value.absent(),
    this.reminderMinutesBefore = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       dayOfWeek = Value(dayOfWeek),
       startTime = Value(startTime),
       endTime = Value(endTime);
  static Insertable<TimetableSlotEntity> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? location,
    Expression<int>? dayOfWeek,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? colorTag,
    Expression<String>? boardId,
    Expression<String>? notes,
    Expression<int>? reminderMinutesBefore,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (location != null) 'location': location,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (colorTag != null) 'color_tag': colorTag,
      if (boardId != null) 'board_id': boardId,
      if (notes != null) 'notes': notes,
      if (reminderMinutesBefore != null)
        'reminder_minutes_before': reminderMinutesBefore,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimetableSlotsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? location,
    Value<int>? dayOfWeek,
    Value<String>? startTime,
    Value<String>? endTime,
    Value<String?>? colorTag,
    Value<String?>? boardId,
    Value<String?>? notes,
    Value<int?>? reminderMinutesBefore,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<int>? rowid,
  }) {
    return TimetableSlotsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorTag: colorTag ?? this.colorTag,
      boardId: boardId ?? this.boardId,
      notes: notes ?? this.notes,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (colorTag.present) {
      map['color_tag'] = Variable<String>(colorTag.value);
    }
    if (boardId.present) {
      map['board_id'] = Variable<String>(boardId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (reminderMinutesBefore.present) {
      map['reminder_minutes_before'] = Variable<int>(
        reminderMinutesBefore.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimetableSlotsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('location: $location, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('colorTag: $colorTag, ')
          ..write('boardId: $boardId, ')
          ..write('notes: $notes, ')
          ..write('reminderMinutesBefore: $reminderMinutesBefore, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BoardsTable boards = $BoardsTable(this);
  late final $PinsTable pins = $PinsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $TaskDependenciesTable taskDependencies = $TaskDependenciesTable(
    this,
  );
  late final $ConnectorsTable connectors = $ConnectorsTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $TimetableSlotsTable timetableSlots = $TimetableSlotsTable(this);
  late final BoardDao boardDao = BoardDao(this as AppDatabase);
  late final PinDao pinDao = PinDao(this as AppDatabase);
  late final TaskDao taskDao = TaskDao(this as AppDatabase);
  late final ConnectorDao connectorDao = ConnectorDao(this as AppDatabase);
  late final TimetableDao timetableDao = TimetableDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    boards,
    pins,
    tasks,
    taskDependencies,
    connectors,
    attachments,
    timetableSlots,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'boards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('boards', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'boards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pins', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pins',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pins', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'boards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pins', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pins',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'boards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pins',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_dependencies', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_dependencies', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'boards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('connectors', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pins',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('connectors', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pins',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('connectors', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pins',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('attachments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'boards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('timetable_slots', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$BoardsTableCreateCompanionBuilder =
    BoardsCompanion Function({
      required String id,
      required String title,
      Value<String?> parentBoardId,
      Value<String> defaultViewMode,
      Value<bool> kanbanEnabled,
      Value<DateTime?> milestoneDate,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<int> rowid,
    });
typedef $$BoardsTableUpdateCompanionBuilder =
    BoardsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> parentBoardId,
      Value<String> defaultViewMode,
      Value<bool> kanbanEnabled,
      Value<DateTime?> milestoneDate,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<int> rowid,
    });

final class $$BoardsTableReferences
    extends BaseReferences<_$AppDatabase, $BoardsTable, BoardEntity> {
  $$BoardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoardsTable _parentBoardIdTable(_$AppDatabase db) =>
      db.boards.createAlias('boards__parent_board_id__boards__id');

  $$BoardsTableProcessedTableManager? get parentBoardId {
    final $_column = $_itemColumn<String>('parent_board_id');
    if ($_column == null) return null;
    final manager = $$BoardsTableTableManager(
      $_db,
      $_db.boards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentBoardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TasksTable, List<TaskEntity>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'boards__id__tasks__board_id',
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.boardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ConnectorsTable, List<ConnectorEntity>>
  _connectorsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.connectors,
    aliasName: 'boards__id__connectors__board_id',
  );

  $$ConnectorsTableProcessedTableManager get connectorsRefs {
    final manager = $$ConnectorsTableTableManager(
      $_db,
      $_db.connectors,
    ).filter((f) => f.boardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_connectorsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TimetableSlotsTable, List<TimetableSlotEntity>>
  _timetableSlotsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.timetableSlots,
    aliasName: 'boards__id__timetable_slots__board_id',
  );

  $$TimetableSlotsTableProcessedTableManager get timetableSlotsRefs {
    final manager = $$TimetableSlotsTableTableManager(
      $_db,
      $_db.timetableSlots,
    ).filter((f) => f.boardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_timetableSlotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BoardsTableFilterComposer
    extends Composer<_$AppDatabase, $BoardsTable> {
  $$BoardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultViewMode => $composableBuilder(
    column: $table.defaultViewMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get kanbanEnabled => $composableBuilder(
    column: $table.kanbanEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get milestoneDate => $composableBuilder(
    column: $table.milestoneDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BoardsTableFilterComposer get parentBoardId {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentBoardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableFilterComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> connectorsRefs(
    Expression<bool> Function($$ConnectorsTableFilterComposer f) f,
  ) {
    final $$ConnectorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.connectors,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectorsTableFilterComposer(
            $db: $db,
            $table: $db.connectors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> timetableSlotsRefs(
    Expression<bool> Function($$TimetableSlotsTableFilterComposer f) f,
  ) {
    final $$TimetableSlotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timetableSlots,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimetableSlotsTableFilterComposer(
            $db: $db,
            $table: $db.timetableSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoardsTableOrderingComposer
    extends Composer<_$AppDatabase, $BoardsTable> {
  $$BoardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultViewMode => $composableBuilder(
    column: $table.defaultViewMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get kanbanEnabled => $composableBuilder(
    column: $table.kanbanEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get milestoneDate => $composableBuilder(
    column: $table.milestoneDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoardsTableOrderingComposer get parentBoardId {
    final $$BoardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentBoardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableOrderingComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BoardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoardsTable> {
  $$BoardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get defaultViewMode => $composableBuilder(
    column: $table.defaultViewMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get kanbanEnabled => $composableBuilder(
    column: $table.kanbanEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get milestoneDate => $composableBuilder(
    column: $table.milestoneDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  $$BoardsTableAnnotationComposer get parentBoardId {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentBoardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> connectorsRefs<T extends Object>(
    Expression<T> Function($$ConnectorsTableAnnotationComposer a) f,
  ) {
    final $$ConnectorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.connectors,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConnectorsTableAnnotationComposer(
            $db: $db,
            $table: $db.connectors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> timetableSlotsRefs<T extends Object>(
    Expression<T> Function($$TimetableSlotsTableAnnotationComposer a) f,
  ) {
    final $$TimetableSlotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.timetableSlots,
      getReferencedColumn: (t) => t.boardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TimetableSlotsTableAnnotationComposer(
            $db: $db,
            $table: $db.timetableSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BoardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoardsTable,
          BoardEntity,
          $$BoardsTableFilterComposer,
          $$BoardsTableOrderingComposer,
          $$BoardsTableAnnotationComposer,
          $$BoardsTableCreateCompanionBuilder,
          $$BoardsTableUpdateCompanionBuilder,
          (BoardEntity, $$BoardsTableReferences),
          BoardEntity,
          PrefetchHooks Function({
            bool parentBoardId,
            bool tasksRefs,
            bool connectorsRefs,
            bool timetableSlotsRefs,
          })
        > {
  $$BoardsTableTableManager(_$AppDatabase db, $BoardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> parentBoardId = const Value.absent(),
                Value<String> defaultViewMode = const Value.absent(),
                Value<bool> kanbanEnabled = const Value.absent(),
                Value<DateTime?> milestoneDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardsCompanion(
                id: id,
                title: title,
                parentBoardId: parentBoardId,
                defaultViewMode: defaultViewMode,
                kanbanEnabled: kanbanEnabled,
                milestoneDate: milestoneDate,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> parentBoardId = const Value.absent(),
                Value<String> defaultViewMode = const Value.absent(),
                Value<bool> kanbanEnabled = const Value.absent(),
                Value<DateTime?> milestoneDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardsCompanion.insert(
                id: id,
                title: title,
                parentBoardId: parentBoardId,
                defaultViewMode: defaultViewMode,
                kanbanEnabled: kanbanEnabled,
                milestoneDate: milestoneDate,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$BoardsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                parentBoardId = false,
                tasksRefs = false,
                connectorsRefs = false,
                timetableSlotsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tasksRefs) db.tasks,
                    if (connectorsRefs) db.connectors,
                    if (timetableSlotsRefs) db.timetableSlots,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentBoardId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentBoardId,
                                    referencedTable: $$BoardsTableReferences
                                        ._parentBoardIdTable(db),
                                    referencedColumn: $$BoardsTableReferences
                                        ._parentBoardIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tasksRefs)
                        await $_getPrefetchedData<
                          BoardEntity,
                          $BoardsTable,
                          TaskEntity
                        >(
                          currentTable: table,
                          referencedTable: $$BoardsTableReferences
                              ._tasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoardsTableReferences(db, table, p0).tasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boardId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (connectorsRefs)
                        await $_getPrefetchedData<
                          BoardEntity,
                          $BoardsTable,
                          ConnectorEntity
                        >(
                          currentTable: table,
                          referencedTable: $$BoardsTableReferences
                              ._connectorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoardsTableReferences(
                                db,
                                table,
                                p0,
                              ).connectorsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boardId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (timetableSlotsRefs)
                        await $_getPrefetchedData<
                          BoardEntity,
                          $BoardsTable,
                          TimetableSlotEntity
                        >(
                          currentTable: table,
                          referencedTable: $$BoardsTableReferences
                              ._timetableSlotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BoardsTableReferences(
                                db,
                                table,
                                p0,
                              ).timetableSlotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boardId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BoardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoardsTable,
      BoardEntity,
      $$BoardsTableFilterComposer,
      $$BoardsTableOrderingComposer,
      $$BoardsTableAnnotationComposer,
      $$BoardsTableCreateCompanionBuilder,
      $$BoardsTableUpdateCompanionBuilder,
      (BoardEntity, $$BoardsTableReferences),
      BoardEntity,
      PrefetchHooks Function({
        bool parentBoardId,
        bool tasksRefs,
        bool connectorsRefs,
        bool timetableSlotsRefs,
      })
    >;
typedef $$PinsTableCreateCompanionBuilder =
    PinsCompanion Function({
      required String id,
      Value<String?> boardId,
      required String type,
      Value<double> x,
      Value<double> y,
      Value<double> width,
      Value<double> height,
      Value<int> zIndex,
      Value<double> rotation,
      Value<String?> colorTag,
      Value<String?> content,
      Value<String?> parentFrameId,
      Value<String?> linkedBoardId,
      Value<String?> tags,
      Value<bool> isLocked,
      Value<DateTime?> entryDate,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<int> rowid,
    });
typedef $$PinsTableUpdateCompanionBuilder =
    PinsCompanion Function({
      Value<String> id,
      Value<String?> boardId,
      Value<String> type,
      Value<double> x,
      Value<double> y,
      Value<double> width,
      Value<double> height,
      Value<int> zIndex,
      Value<double> rotation,
      Value<String?> colorTag,
      Value<String?> content,
      Value<String?> parentFrameId,
      Value<String?> linkedBoardId,
      Value<String?> tags,
      Value<bool> isLocked,
      Value<DateTime?> entryDate,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<int> rowid,
    });

final class $$PinsTableReferences
    extends BaseReferences<_$AppDatabase, $PinsTable, PinEntity> {
  $$PinsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoardsTable _boardIdTable(_$AppDatabase db) =>
      db.boards.createAlias('pins__board_id__boards__id');

  $$BoardsTableProcessedTableManager? get boardId {
    final $_column = $_itemColumn<String>('board_id');
    if ($_column == null) return null;
    final manager = $$BoardsTableTableManager(
      $_db,
      $_db.boards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PinsTable _parentFrameIdTable(_$AppDatabase db) =>
      db.pins.createAlias('pins__parent_frame_id__pins__id');

  $$PinsTableProcessedTableManager? get parentFrameId {
    final $_column = $_itemColumn<String>('parent_frame_id');
    if ($_column == null) return null;
    final manager = $$PinsTableTableManager(
      $_db,
      $_db.pins,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentFrameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BoardsTable _linkedBoardIdTable(_$AppDatabase db) =>
      db.boards.createAlias('pins__linked_board_id__boards__id');

  $$BoardsTableProcessedTableManager? get linkedBoardId {
    final $_column = $_itemColumn<String>('linked_board_id');
    if ($_column == null) return null;
    final manager = $$BoardsTableTableManager(
      $_db,
      $_db.boards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_linkedBoardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<AttachmentEntity>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: 'pins__id__attachments__pin_id',
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.pinId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PinsTableFilterComposer extends Composer<_$AppDatabase, $PinsTable> {
  $$PinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get zIndex => $composableBuilder(
    column: $table.zIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorTag => $composableBuilder(
    column: $table.colorTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BoardsTableFilterComposer get boardId {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableFilterComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PinsTableFilterComposer get parentFrameId {
    final $$PinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentFrameId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableFilterComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoardsTableFilterComposer get linkedBoardId {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedBoardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableFilterComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.pinId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PinsTableOrderingComposer extends Composer<_$AppDatabase, $PinsTable> {
  $$PinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get zIndex => $composableBuilder(
    column: $table.zIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorTag => $composableBuilder(
    column: $table.colorTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocked => $composableBuilder(
    column: $table.isLocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoardsTableOrderingComposer get boardId {
    final $$BoardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableOrderingComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PinsTableOrderingComposer get parentFrameId {
    final $$PinsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentFrameId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableOrderingComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoardsTableOrderingComposer get linkedBoardId {
    final $$BoardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedBoardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableOrderingComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PinsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PinsTable> {
  $$PinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get zIndex =>
      $composableBuilder(column: $table.zIndex, builder: (column) => column);

  GeneratedColumn<double> get rotation =>
      $composableBuilder(column: $table.rotation, builder: (column) => column);

  GeneratedColumn<String> get colorTag =>
      $composableBuilder(column: $table.colorTag, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<bool> get isLocked =>
      $composableBuilder(column: $table.isLocked, builder: (column) => column);

  GeneratedColumn<DateTime> get entryDate =>
      $composableBuilder(column: $table.entryDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  $$BoardsTableAnnotationComposer get boardId {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PinsTableAnnotationComposer get parentFrameId {
    final $$PinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentFrameId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableAnnotationComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoardsTableAnnotationComposer get linkedBoardId {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.linkedBoardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.pinId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PinsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PinsTable,
          PinEntity,
          $$PinsTableFilterComposer,
          $$PinsTableOrderingComposer,
          $$PinsTableAnnotationComposer,
          $$PinsTableCreateCompanionBuilder,
          $$PinsTableUpdateCompanionBuilder,
          (PinEntity, $$PinsTableReferences),
          PinEntity,
          PrefetchHooks Function({
            bool boardId,
            bool parentFrameId,
            bool linkedBoardId,
            bool attachmentsRefs,
          })
        > {
  $$PinsTableTableManager(_$AppDatabase db, $PinsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> boardId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<int> zIndex = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<String?> colorTag = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> parentFrameId = const Value.absent(),
                Value<String?> linkedBoardId = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<DateTime?> entryDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PinsCompanion(
                id: id,
                boardId: boardId,
                type: type,
                x: x,
                y: y,
                width: width,
                height: height,
                zIndex: zIndex,
                rotation: rotation,
                colorTag: colorTag,
                content: content,
                parentFrameId: parentFrameId,
                linkedBoardId: linkedBoardId,
                tags: tags,
                isLocked: isLocked,
                entryDate: entryDate,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> boardId = const Value.absent(),
                required String type,
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<int> zIndex = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<String?> colorTag = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> parentFrameId = const Value.absent(),
                Value<String?> linkedBoardId = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<bool> isLocked = const Value.absent(),
                Value<DateTime?> entryDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PinsCompanion.insert(
                id: id,
                boardId: boardId,
                type: type,
                x: x,
                y: y,
                width: width,
                height: height,
                zIndex: zIndex,
                rotation: rotation,
                colorTag: colorTag,
                content: content,
                parentFrameId: parentFrameId,
                linkedBoardId: linkedBoardId,
                tags: tags,
                isLocked: isLocked,
                entryDate: entryDate,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PinsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                boardId = false,
                parentFrameId = false,
                linkedBoardId = false,
                attachmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (attachmentsRefs) db.attachments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (boardId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.boardId,
                                    referencedTable: $$PinsTableReferences
                                        ._boardIdTable(db),
                                    referencedColumn: $$PinsTableReferences
                                        ._boardIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (parentFrameId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentFrameId,
                                    referencedTable: $$PinsTableReferences
                                        ._parentFrameIdTable(db),
                                    referencedColumn: $$PinsTableReferences
                                        ._parentFrameIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (linkedBoardId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.linkedBoardId,
                                    referencedTable: $$PinsTableReferences
                                        ._linkedBoardIdTable(db),
                                    referencedColumn: $$PinsTableReferences
                                        ._linkedBoardIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (attachmentsRefs)
                        await $_getPrefetchedData<
                          PinEntity,
                          $PinsTable,
                          AttachmentEntity
                        >(
                          currentTable: table,
                          referencedTable: $$PinsTableReferences
                              ._attachmentsRefsTable(db),
                          managerFromTypedResult: (p0) => $$PinsTableReferences(
                            db,
                            table,
                            p0,
                          ).attachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pinId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PinsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PinsTable,
      PinEntity,
      $$PinsTableFilterComposer,
      $$PinsTableOrderingComposer,
      $$PinsTableAnnotationComposer,
      $$PinsTableCreateCompanionBuilder,
      $$PinsTableUpdateCompanionBuilder,
      (PinEntity, $$PinsTableReferences),
      PinEntity,
      PrefetchHooks Function({
        bool boardId,
        bool parentFrameId,
        bool linkedBoardId,
        bool attachmentsRefs,
      })
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      Value<String?> pinId,
      Value<String?> boardId,
      Value<String?> groupPinId,
      required String title,
      Value<String?> notes,
      Value<DateTime?> dueDate,
      Value<DateTime?> scheduledDate,
      Value<int> priority,
      Value<String> status,
      Value<String?> recurrenceParentId,
      Value<String?> recurrenceRule,
      Value<String?> calendarEventId,
      Value<String?> osReminderId,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String?> pinId,
      Value<String?> boardId,
      Value<String?> groupPinId,
      Value<String> title,
      Value<String?> notes,
      Value<DateTime?> dueDate,
      Value<DateTime?> scheduledDate,
      Value<int> priority,
      Value<String> status,
      Value<String?> recurrenceParentId,
      Value<String?> recurrenceRule,
      Value<String?> calendarEventId,
      Value<String?> osReminderId,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<int> rowid,
    });

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, TaskEntity> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PinsTable _pinIdTable(_$AppDatabase db) =>
      db.pins.createAlias('tasks__pin_id__pins__id');

  $$PinsTableProcessedTableManager? get pinId {
    final $_column = $_itemColumn<String>('pin_id');
    if ($_column == null) return null;
    final manager = $$PinsTableTableManager(
      $_db,
      $_db.pins,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pinIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BoardsTable _boardIdTable(_$AppDatabase db) =>
      db.boards.createAlias('tasks__board_id__boards__id');

  $$BoardsTableProcessedTableManager? get boardId {
    final $_column = $_itemColumn<String>('board_id');
    if ($_column == null) return null;
    final manager = $$BoardsTableTableManager(
      $_db,
      $_db.boards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PinsTable _groupPinIdTable(_$AppDatabase db) =>
      db.pins.createAlias('tasks__group_pin_id__pins__id');

  $$PinsTableProcessedTableManager? get groupPinId {
    final $_column = $_itemColumn<String>('group_pin_id');
    if ($_column == null) return null;
    final manager = $$PinsTableTableManager(
      $_db,
      $_db.pins,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupPinIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TasksTable _recurrenceParentIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('tasks__recurrence_parent_id__tasks__id');

  $$TasksTableProcessedTableManager? get recurrenceParentId {
    final $_column = $_itemColumn<String>('recurrence_parent_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recurrenceParentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calendarEventId => $composableBuilder(
    column: $table.calendarEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get osReminderId => $composableBuilder(
    column: $table.osReminderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PinsTableFilterComposer get pinId {
    final $$PinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pinId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableFilterComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoardsTableFilterComposer get boardId {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableFilterComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PinsTableFilterComposer get groupPinId {
    final $$PinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupPinId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableFilterComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableFilterComposer get recurrenceParentId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurrenceParentId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calendarEventId => $composableBuilder(
    column: $table.calendarEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get osReminderId => $composableBuilder(
    column: $table.osReminderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PinsTableOrderingComposer get pinId {
    final $$PinsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pinId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableOrderingComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoardsTableOrderingComposer get boardId {
    final $$BoardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableOrderingComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PinsTableOrderingComposer get groupPinId {
    final $$PinsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupPinId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableOrderingComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableOrderingComposer get recurrenceParentId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurrenceParentId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => column,
  );

  GeneratedColumn<String> get calendarEventId => $composableBuilder(
    column: $table.calendarEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get osReminderId => $composableBuilder(
    column: $table.osReminderId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  $$PinsTableAnnotationComposer get pinId {
    final $$PinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pinId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableAnnotationComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BoardsTableAnnotationComposer get boardId {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PinsTableAnnotationComposer get groupPinId {
    final $$PinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupPinId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableAnnotationComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableAnnotationComposer get recurrenceParentId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurrenceParentId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          TaskEntity,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskEntity, $$TasksTableReferences),
          TaskEntity,
          PrefetchHooks Function({
            bool pinId,
            bool boardId,
            bool groupPinId,
            bool recurrenceParentId,
          })
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> pinId = const Value.absent(),
                Value<String?> boardId = const Value.absent(),
                Value<String?> groupPinId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<DateTime?> scheduledDate = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> recurrenceParentId = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<String?> calendarEventId = const Value.absent(),
                Value<String?> osReminderId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                pinId: pinId,
                boardId: boardId,
                groupPinId: groupPinId,
                title: title,
                notes: notes,
                dueDate: dueDate,
                scheduledDate: scheduledDate,
                priority: priority,
                status: status,
                recurrenceParentId: recurrenceParentId,
                recurrenceRule: recurrenceRule,
                calendarEventId: calendarEventId,
                osReminderId: osReminderId,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> pinId = const Value.absent(),
                Value<String?> boardId = const Value.absent(),
                Value<String?> groupPinId = const Value.absent(),
                required String title,
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<DateTime?> scheduledDate = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> recurrenceParentId = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<String?> calendarEventId = const Value.absent(),
                Value<String?> osReminderId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                pinId: pinId,
                boardId: boardId,
                groupPinId: groupPinId,
                title: title,
                notes: notes,
                dueDate: dueDate,
                scheduledDate: scheduledDate,
                priority: priority,
                status: status,
                recurrenceParentId: recurrenceParentId,
                recurrenceRule: recurrenceRule,
                calendarEventId: calendarEventId,
                osReminderId: osReminderId,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TasksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                pinId = false,
                boardId = false,
                groupPinId = false,
                recurrenceParentId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (pinId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.pinId,
                                    referencedTable: $$TasksTableReferences
                                        ._pinIdTable(db),
                                    referencedColumn: $$TasksTableReferences
                                        ._pinIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (boardId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.boardId,
                                    referencedTable: $$TasksTableReferences
                                        ._boardIdTable(db),
                                    referencedColumn: $$TasksTableReferences
                                        ._boardIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (groupPinId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupPinId,
                                    referencedTable: $$TasksTableReferences
                                        ._groupPinIdTable(db),
                                    referencedColumn: $$TasksTableReferences
                                        ._groupPinIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (recurrenceParentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.recurrenceParentId,
                                    referencedTable: $$TasksTableReferences
                                        ._recurrenceParentIdTable(db),
                                    referencedColumn: $$TasksTableReferences
                                        ._recurrenceParentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      TaskEntity,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskEntity, $$TasksTableReferences),
      TaskEntity,
      PrefetchHooks Function({
        bool pinId,
        bool boardId,
        bool groupPinId,
        bool recurrenceParentId,
      })
    >;
typedef $$TaskDependenciesTableCreateCompanionBuilder =
    TaskDependenciesCompanion Function({
      required String taskId,
      required String dependsOnTaskId,
      Value<int> rowid,
    });
typedef $$TaskDependenciesTableUpdateCompanionBuilder =
    TaskDependenciesCompanion Function({
      Value<String> taskId,
      Value<String> dependsOnTaskId,
      Value<int> rowid,
    });

final class $$TaskDependenciesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TaskDependenciesTable,
          TaskDependencyEntity
        > {
  $$TaskDependenciesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('task_dependencies__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TasksTable _dependsOnTaskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('task_dependencies__depends_on_task_id__tasks__id');

  $$TasksTableProcessedTableManager get dependsOnTaskId {
    final $_column = $_itemColumn<String>('depends_on_task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dependsOnTaskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskDependenciesTableFilterComposer
    extends Composer<_$AppDatabase, $TaskDependenciesTable> {
  $$TaskDependenciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableFilterComposer get dependsOnTaskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dependsOnTaskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskDependenciesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskDependenciesTable> {
  $$TaskDependenciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableOrderingComposer get dependsOnTaskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dependsOnTaskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskDependenciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskDependenciesTable> {
  $$TaskDependenciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableAnnotationComposer get dependsOnTaskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dependsOnTaskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskDependenciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskDependenciesTable,
          TaskDependencyEntity,
          $$TaskDependenciesTableFilterComposer,
          $$TaskDependenciesTableOrderingComposer,
          $$TaskDependenciesTableAnnotationComposer,
          $$TaskDependenciesTableCreateCompanionBuilder,
          $$TaskDependenciesTableUpdateCompanionBuilder,
          (TaskDependencyEntity, $$TaskDependenciesTableReferences),
          TaskDependencyEntity,
          PrefetchHooks Function({bool taskId, bool dependsOnTaskId})
        > {
  $$TaskDependenciesTableTableManager(
    _$AppDatabase db,
    $TaskDependenciesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskDependenciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskDependenciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskDependenciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<String> dependsOnTaskId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskDependenciesCompanion(
                taskId: taskId,
                dependsOnTaskId: dependsOnTaskId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required String dependsOnTaskId,
                Value<int> rowid = const Value.absent(),
              }) => TaskDependenciesCompanion.insert(
                taskId: taskId,
                dependsOnTaskId: dependsOnTaskId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskDependenciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false, dependsOnTaskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable:
                                    $$TaskDependenciesTableReferences
                                        ._taskIdTable(db),
                                referencedColumn:
                                    $$TaskDependenciesTableReferences
                                        ._taskIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (dependsOnTaskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dependsOnTaskId,
                                referencedTable:
                                    $$TaskDependenciesTableReferences
                                        ._dependsOnTaskIdTable(db),
                                referencedColumn:
                                    $$TaskDependenciesTableReferences
                                        ._dependsOnTaskIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TaskDependenciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskDependenciesTable,
      TaskDependencyEntity,
      $$TaskDependenciesTableFilterComposer,
      $$TaskDependenciesTableOrderingComposer,
      $$TaskDependenciesTableAnnotationComposer,
      $$TaskDependenciesTableCreateCompanionBuilder,
      $$TaskDependenciesTableUpdateCompanionBuilder,
      (TaskDependencyEntity, $$TaskDependenciesTableReferences),
      TaskDependencyEntity,
      PrefetchHooks Function({bool taskId, bool dependsOnTaskId})
    >;
typedef $$ConnectorsTableCreateCompanionBuilder =
    ConnectorsCompanion Function({
      required String id,
      required String boardId,
      required String fromPinId,
      required String toPinId,
      Value<String?> label,
      Value<String> style,
      Value<double?> bendOffsetX,
      Value<double?> bendOffsetY,
      Value<int> rowid,
    });
typedef $$ConnectorsTableUpdateCompanionBuilder =
    ConnectorsCompanion Function({
      Value<String> id,
      Value<String> boardId,
      Value<String> fromPinId,
      Value<String> toPinId,
      Value<String?> label,
      Value<String> style,
      Value<double?> bendOffsetX,
      Value<double?> bendOffsetY,
      Value<int> rowid,
    });

final class $$ConnectorsTableReferences
    extends BaseReferences<_$AppDatabase, $ConnectorsTable, ConnectorEntity> {
  $$ConnectorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BoardsTable _boardIdTable(_$AppDatabase db) =>
      db.boards.createAlias('connectors__board_id__boards__id');

  $$BoardsTableProcessedTableManager get boardId {
    final $_column = $_itemColumn<String>('board_id')!;

    final manager = $$BoardsTableTableManager(
      $_db,
      $_db.boards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PinsTable _fromPinIdTable(_$AppDatabase db) =>
      db.pins.createAlias('connectors__from_pin_id__pins__id');

  $$PinsTableProcessedTableManager get fromPinId {
    final $_column = $_itemColumn<String>('from_pin_id')!;

    final manager = $$PinsTableTableManager(
      $_db,
      $_db.pins,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromPinIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PinsTable _toPinIdTable(_$AppDatabase db) =>
      db.pins.createAlias('connectors__to_pin_id__pins__id');

  $$PinsTableProcessedTableManager get toPinId {
    final $_column = $_itemColumn<String>('to_pin_id')!;

    final manager = $$PinsTableTableManager(
      $_db,
      $_db.pins,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toPinIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ConnectorsTableFilterComposer
    extends Composer<_$AppDatabase, $ConnectorsTable> {
  $$ConnectorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bendOffsetX => $composableBuilder(
    column: $table.bendOffsetX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bendOffsetY => $composableBuilder(
    column: $table.bendOffsetY,
    builder: (column) => ColumnFilters(column),
  );

  $$BoardsTableFilterComposer get boardId {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableFilterComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PinsTableFilterComposer get fromPinId {
    final $$PinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromPinId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableFilterComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PinsTableFilterComposer get toPinId {
    final $$PinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toPinId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableFilterComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConnectorsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConnectorsTable> {
  $$ConnectorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bendOffsetX => $composableBuilder(
    column: $table.bendOffsetX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bendOffsetY => $composableBuilder(
    column: $table.bendOffsetY,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoardsTableOrderingComposer get boardId {
    final $$BoardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableOrderingComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PinsTableOrderingComposer get fromPinId {
    final $$PinsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromPinId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableOrderingComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PinsTableOrderingComposer get toPinId {
    final $$PinsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toPinId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableOrderingComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConnectorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConnectorsTable> {
  $$ConnectorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<double> get bendOffsetX => $composableBuilder(
    column: $table.bendOffsetX,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bendOffsetY => $composableBuilder(
    column: $table.bendOffsetY,
    builder: (column) => column,
  );

  $$BoardsTableAnnotationComposer get boardId {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PinsTableAnnotationComposer get fromPinId {
    final $$PinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromPinId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableAnnotationComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PinsTableAnnotationComposer get toPinId {
    final $$PinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toPinId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableAnnotationComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConnectorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConnectorsTable,
          ConnectorEntity,
          $$ConnectorsTableFilterComposer,
          $$ConnectorsTableOrderingComposer,
          $$ConnectorsTableAnnotationComposer,
          $$ConnectorsTableCreateCompanionBuilder,
          $$ConnectorsTableUpdateCompanionBuilder,
          (ConnectorEntity, $$ConnectorsTableReferences),
          ConnectorEntity,
          PrefetchHooks Function({bool boardId, bool fromPinId, bool toPinId})
        > {
  $$ConnectorsTableTableManager(_$AppDatabase db, $ConnectorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConnectorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConnectorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConnectorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> boardId = const Value.absent(),
                Value<String> fromPinId = const Value.absent(),
                Value<String> toPinId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<double?> bendOffsetX = const Value.absent(),
                Value<double?> bendOffsetY = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConnectorsCompanion(
                id: id,
                boardId: boardId,
                fromPinId: fromPinId,
                toPinId: toPinId,
                label: label,
                style: style,
                bendOffsetX: bendOffsetX,
                bendOffsetY: bendOffsetY,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String boardId,
                required String fromPinId,
                required String toPinId,
                Value<String?> label = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<double?> bendOffsetX = const Value.absent(),
                Value<double?> bendOffsetY = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConnectorsCompanion.insert(
                id: id,
                boardId: boardId,
                fromPinId: fromPinId,
                toPinId: toPinId,
                label: label,
                style: style,
                bendOffsetX: bendOffsetX,
                bendOffsetY: bendOffsetY,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConnectorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({boardId = false, fromPinId = false, toPinId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (boardId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.boardId,
                                    referencedTable: $$ConnectorsTableReferences
                                        ._boardIdTable(db),
                                    referencedColumn:
                                        $$ConnectorsTableReferences
                                            ._boardIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (fromPinId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.fromPinId,
                                    referencedTable: $$ConnectorsTableReferences
                                        ._fromPinIdTable(db),
                                    referencedColumn:
                                        $$ConnectorsTableReferences
                                            ._fromPinIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (toPinId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.toPinId,
                                    referencedTable: $$ConnectorsTableReferences
                                        ._toPinIdTable(db),
                                    referencedColumn:
                                        $$ConnectorsTableReferences
                                            ._toPinIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ConnectorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConnectorsTable,
      ConnectorEntity,
      $$ConnectorsTableFilterComposer,
      $$ConnectorsTableOrderingComposer,
      $$ConnectorsTableAnnotationComposer,
      $$ConnectorsTableCreateCompanionBuilder,
      $$ConnectorsTableUpdateCompanionBuilder,
      (ConnectorEntity, $$ConnectorsTableReferences),
      ConnectorEntity,
      PrefetchHooks Function({bool boardId, bool fromPinId, bool toPinId})
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String id,
      required String pinId,
      required String filePath,
      required String fileType,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> id,
      Value<String> pinId,
      Value<String> filePath,
      Value<String> fileType,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AttachmentsTableReferences
    extends BaseReferences<_$AppDatabase, $AttachmentsTable, AttachmentEntity> {
  $$AttachmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PinsTable _pinIdTable(_$AppDatabase db) =>
      db.pins.createAlias('attachments__pin_id__pins__id');

  $$PinsTableProcessedTableManager get pinId {
    final $_column = $_itemColumn<String>('pin_id')!;

    final manager = $$PinsTableTableManager(
      $_db,
      $_db.pins,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pinIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PinsTableFilterComposer get pinId {
    final $$PinsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pinId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableFilterComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PinsTableOrderingComposer get pinId {
    final $$PinsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pinId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableOrderingComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PinsTableAnnotationComposer get pinId {
    final $$PinsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pinId,
      referencedTable: $db.pins,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PinsTableAnnotationComposer(
            $db: $db,
            $table: $db.pins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          AttachmentEntity,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (AttachmentEntity, $$AttachmentsTableReferences),
          AttachmentEntity,
          PrefetchHooks Function({bool pinId})
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pinId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> fileType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                pinId: pinId,
                filePath: filePath,
                fileType: fileType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pinId,
                required String filePath,
                required String fileType,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                pinId: pinId,
                filePath: filePath,
                fileType: fileType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pinId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (pinId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pinId,
                                referencedTable: $$AttachmentsTableReferences
                                    ._pinIdTable(db),
                                referencedColumn: $$AttachmentsTableReferences
                                    ._pinIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      AttachmentEntity,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (AttachmentEntity, $$AttachmentsTableReferences),
      AttachmentEntity,
      PrefetchHooks Function({bool pinId})
    >;
typedef $$TimetableSlotsTableCreateCompanionBuilder =
    TimetableSlotsCompanion Function({
      required String id,
      required String title,
      Value<String?> location,
      required int dayOfWeek,
      required String startTime,
      required String endTime,
      Value<String?> colorTag,
      Value<String?> boardId,
      Value<String?> notes,
      Value<int?> reminderMinutesBefore,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<int> rowid,
    });
typedef $$TimetableSlotsTableUpdateCompanionBuilder =
    TimetableSlotsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> location,
      Value<int> dayOfWeek,
      Value<String> startTime,
      Value<String> endTime,
      Value<String?> colorTag,
      Value<String?> boardId,
      Value<String?> notes,
      Value<int?> reminderMinutesBefore,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<int> rowid,
    });

final class $$TimetableSlotsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TimetableSlotsTable,
          TimetableSlotEntity
        > {
  $$TimetableSlotsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BoardsTable _boardIdTable(_$AppDatabase db) =>
      db.boards.createAlias('timetable_slots__board_id__boards__id');

  $$BoardsTableProcessedTableManager? get boardId {
    final $_column = $_itemColumn<String>('board_id');
    if ($_column == null) return null;
    final manager = $$BoardsTableTableManager(
      $_db,
      $_db.boards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TimetableSlotsTableFilterComposer
    extends Composer<_$AppDatabase, $TimetableSlotsTable> {
  $$TimetableSlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorTag => $composableBuilder(
    column: $table.colorTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BoardsTableFilterComposer get boardId {
    final $$BoardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableFilterComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimetableSlotsTableOrderingComposer
    extends Composer<_$AppDatabase, $TimetableSlotsTable> {
  $$TimetableSlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorTag => $composableBuilder(
    column: $table.colorTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BoardsTableOrderingComposer get boardId {
    final $$BoardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableOrderingComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimetableSlotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimetableSlotsTable> {
  $$TimetableSlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get colorTag =>
      $composableBuilder(column: $table.colorTag, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  $$BoardsTableAnnotationComposer get boardId {
    final $$BoardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boardId,
      referencedTable: $db.boards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BoardsTableAnnotationComposer(
            $db: $db,
            $table: $db.boards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TimetableSlotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimetableSlotsTable,
          TimetableSlotEntity,
          $$TimetableSlotsTableFilterComposer,
          $$TimetableSlotsTableOrderingComposer,
          $$TimetableSlotsTableAnnotationComposer,
          $$TimetableSlotsTableCreateCompanionBuilder,
          $$TimetableSlotsTableUpdateCompanionBuilder,
          (TimetableSlotEntity, $$TimetableSlotsTableReferences),
          TimetableSlotEntity,
          PrefetchHooks Function({bool boardId})
        > {
  $$TimetableSlotsTableTableManager(
    _$AppDatabase db,
    $TimetableSlotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimetableSlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimetableSlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimetableSlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<int> dayOfWeek = const Value.absent(),
                Value<String> startTime = const Value.absent(),
                Value<String> endTime = const Value.absent(),
                Value<String?> colorTag = const Value.absent(),
                Value<String?> boardId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> reminderMinutesBefore = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimetableSlotsCompanion(
                id: id,
                title: title,
                location: location,
                dayOfWeek: dayOfWeek,
                startTime: startTime,
                endTime: endTime,
                colorTag: colorTag,
                boardId: boardId,
                notes: notes,
                reminderMinutesBefore: reminderMinutesBefore,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> location = const Value.absent(),
                required int dayOfWeek,
                required String startTime,
                required String endTime,
                Value<String?> colorTag = const Value.absent(),
                Value<String?> boardId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> reminderMinutesBefore = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimetableSlotsCompanion.insert(
                id: id,
                title: title,
                location: location,
                dayOfWeek: dayOfWeek,
                startTime: startTime,
                endTime: endTime,
                colorTag: colorTag,
                boardId: boardId,
                notes: notes,
                reminderMinutesBefore: reminderMinutesBefore,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TimetableSlotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({boardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (boardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.boardId,
                                referencedTable: $$TimetableSlotsTableReferences
                                    ._boardIdTable(db),
                                referencedColumn:
                                    $$TimetableSlotsTableReferences
                                        ._boardIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TimetableSlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimetableSlotsTable,
      TimetableSlotEntity,
      $$TimetableSlotsTableFilterComposer,
      $$TimetableSlotsTableOrderingComposer,
      $$TimetableSlotsTableAnnotationComposer,
      $$TimetableSlotsTableCreateCompanionBuilder,
      $$TimetableSlotsTableUpdateCompanionBuilder,
      (TimetableSlotEntity, $$TimetableSlotsTableReferences),
      TimetableSlotEntity,
      PrefetchHooks Function({bool boardId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BoardsTableTableManager get boards =>
      $$BoardsTableTableManager(_db, _db.boards);
  $$PinsTableTableManager get pins => $$PinsTableTableManager(_db, _db.pins);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$TaskDependenciesTableTableManager get taskDependencies =>
      $$TaskDependenciesTableTableManager(_db, _db.taskDependencies);
  $$ConnectorsTableTableManager get connectors =>
      $$ConnectorsTableTableManager(_db, _db.connectors);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$TimetableSlotsTableTableManager get timetableSlots =>
      $$TimetableSlotsTableTableManager(_db, _db.timetableSlots);
}
