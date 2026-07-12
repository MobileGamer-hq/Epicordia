// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

final class DatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$databaseHash() => r'ebec191e0f680c4874fc50e3aa05ca804798d892';

@ProviderFor(boardDao)
final boardDaoProvider = BoardDaoProvider._();

final class BoardDaoProvider
    extends $FunctionalProvider<BoardDao, BoardDao, BoardDao>
    with $Provider<BoardDao> {
  BoardDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'boardDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$boardDaoHash();

  @$internal
  @override
  $ProviderElement<BoardDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BoardDao create(Ref ref) {
    return boardDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BoardDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BoardDao>(value),
    );
  }
}

String _$boardDaoHash() => r'b684e72310df07c35353295b0fdf67b8b5d34541';

@ProviderFor(pinDao)
final pinDaoProvider = PinDaoProvider._();

final class PinDaoProvider extends $FunctionalProvider<PinDao, PinDao, PinDao>
    with $Provider<PinDao> {
  PinDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinDaoHash();

  @$internal
  @override
  $ProviderElement<PinDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PinDao create(Ref ref) {
    return pinDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PinDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PinDao>(value),
    );
  }
}

String _$pinDaoHash() => r'21fd294dd72d5ae31fba0e6ea7cacd1307768559';

@ProviderFor(taskDao)
final taskDaoProvider = TaskDaoProvider._();

final class TaskDaoProvider
    extends $FunctionalProvider<TaskDao, TaskDao, TaskDao>
    with $Provider<TaskDao> {
  TaskDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskDaoHash();

  @$internal
  @override
  $ProviderElement<TaskDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TaskDao create(Ref ref) {
    return taskDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskDao>(value),
    );
  }
}

String _$taskDaoHash() => r'732862c43b8ec88199c8ca21c9e1e0a871dcbec2';
