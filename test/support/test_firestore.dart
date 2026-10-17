// Firestore's sealed interfaces are implemented only as test doubles here.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';

/// Minimal in-memory store for the assessment documents the module
/// repository reads and writes. This models document state, not network
/// behavior or security rules.
class FakeFirebaseFirestore implements FirebaseFirestore {
  final records = <String, Map<String, dynamic>>{};

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(this, path);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Collection implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.db, this.path);
  final FakeFirebaseFirestore db;
  @override
  final String path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) =>
      _Document(db, '$path/$id');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Document implements DocumentReference<Map<String, dynamic>> {
  _Document(this.db, this.path);
  final FakeFirebaseFirestore db;
  @override
  final String path;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      _Collection(db, '$path/$collectionPath');

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    db.records[path] = data.map(
      (key, value) => MapEntry(key, value is FieldValue ? Timestamp.now() : value),
    );
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _Snapshot(
    path.split('/').last,
    db.records[path] == null ? null : Map.of(db.records[path]!),
  );

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => Stream.fromFuture(get());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Snapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.id, this.record);
  @override
  final String id;
  final Map<String, dynamic>? record;
  @override
  bool get exists => record != null;
  @override
  Map<String, dynamic>? data() => record;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
