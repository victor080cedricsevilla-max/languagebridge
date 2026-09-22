// Firestore's sealed interfaces are implemented only as test doubles here.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';

/// Minimal in-memory store for the importer/repository tests. This models
/// document state, not network behavior, security rules or transaction retries.
class FakeFirebaseFirestore implements FirebaseFirestore {
  final records = <String, Map<String, dynamic>>{};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final args = invocation.positionalArguments;
    if (invocation.memberName == #collection) {
      return _Collection(this, args.first as String);
    }
    if (invocation.memberName == #runTransaction) {
      return _transact(args.first as Function);
    }
    return super.noSuchMethod(invocation);
  }

  // The importer currently requests int; keeping this explicit catches changes
  // to its persistence contract rather than pretending to emulate all Firestore.
  Future<int> _transact(Function callback) async {
    final transaction = _Transaction(this);
    final result = await callback(transaction) as int;
    for (final write in transaction.writes) {
      write();
    }
    return result;
  }
}

class _Collection implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.db, this.path, {this.field, this.value});
  final FakeFirebaseFirestore db;
  @override
  final String path;
  final Object? field;
  final Object? value;

  Future<QuerySnapshot<Map<String, dynamic>>> _get() async => _QuerySnapshot([
    for (final entry in db.records.entries)
      if (entry.key.startsWith('$path/') &&
          !entry.key.substring(path.length + 1).contains('/') &&
          (field == null || entry.value[field] == value))
        _Snapshot(entry.key.split('/').last, Map.of(entry.value)),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final args = invocation.positionalArguments;
    switch (invocation.memberName) {
      case #doc:
        return _Document(db, '$path/${args.first}');
      case #where:
        return _Collection(
          db,
          path,
          field: args.first,
          value: invocation.namedArguments[#isEqualTo],
        );
      case #orderBy:
        return this;
      case #get:
        return _get();
      case #snapshots:
        return Stream.fromFuture(_get());
    }
    return super.noSuchMethod(invocation);
  }
}

class _Document implements DocumentReference<Map<String, dynamic>> {
  _Document(this.db, this.path);
  final FakeFirebaseFirestore db;
  @override
  final String path;

  Map<String, dynamic> _resolve(Map data) => data.map(
    (key, value) =>
        MapEntry(key as String, value is FieldValue ? Timestamp.now() : value),
  );

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    db.records[path] = _resolve(data);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    final current = db.records[path];
    if (current == null) throw StateError('Document does not exist');
    current.addAll(_resolve(data));
  }

  @override
  Future<void> delete() async {
    db.records.remove(path);
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _Snapshot(
    path.split('/').last,
    db.records[path] == null ? null : Map.of(db.records[path]!),
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Snapshot implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.id, this.record);
  @override
  final String id;
  final Map<String, dynamic>? record;
  @override
  bool get exists => record != null;
  @override
  Map<String, dynamic> data() => record ?? {};
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _QuerySnapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transaction implements Transaction {
  _Transaction(this.db);
  final FakeFirebaseFirestore db;
  final writes = <void Function()>[];
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(DocumentReference<T> ref) {
    if (writes.isNotEmpty) throw StateError('Read after transaction write');
    return ref.get();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final args = invocation.positionalArguments;
    final ref = args.first as _Document;
    final data = ref._resolve(args[1] as Map);
    if (invocation.memberName == #set) {
      writes.add(() => db.records[ref.path] = data);
      return this;
    }
    if (invocation.memberName == #update) {
      writes.add(() => db.records[ref.path]!.addAll(data));
      return this;
    }
    return super.noSuchMethod(invocation);
  }
}
