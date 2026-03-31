import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Chats extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get providerId => text()();
  TextColumn get modelId => text()();
  TextColumn get systemPrompt => text().withDefault(const Constant(""))();
  RealColumn get temperature => real().withDefault(const Constant(0.7))();
  IntColumn get maxTokens => integer().withDefault(const Constant(1024))();
  RealColumn get topP => real().withDefault(const Constant(1.0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get chatId => text()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isError => boolean().withDefault(const Constant(false))();
}

class AppState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Chats, Messages, AppState])
class AppDatabase extends _$AppDatabase {
  AppDatabase()
    : super(
        LazyDatabase(() async {
          final dbFolder = await getApplicationDocumentsDirectory();
          final file = File("${dbFolder.path}/app.sqlite");
          return NativeDatabase(file);
        }),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(chats, chats.systemPrompt);
        await m.addColumn(chats, chats.temperature);
        await m.addColumn(chats, chats.maxTokens);
        await m.addColumn(chats, chats.topP);
      }
    },
  );
}
