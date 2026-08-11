import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/translation_record.dart';

/// Firestore CRUD for a user's translation history.
///
/// History is stored per user at `users/{uid}/history/{recordId}`, so each
/// account only ever reads and writes its own translations.
class HistoryService {
  HistoryService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _history(String uid) =>
      _db.collection('users').doc(uid).collection('history');

  /// READ — a live stream of the user's history, newest first.
  ///
  /// `createdAt` is stored as a concrete client timestamp (not a pending
  /// server value), so ordering is stable and a new record appears at the top
  /// immediately.
  Stream<List<TranslationRecord>> getHistory(String uid) {
    return _history(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(TranslationRecord.fromDoc).toList());
  }

  /// CREATE — writes a record under its own id so undo can re-add the same one.
  Future<void> addRecord(String uid, TranslationRecord record) async {
    await _history(uid).doc(record.id).set(record.toMap());
  }

  /// UPDATE — flips the favorite flag on one record.
  Future<void> setFavorite(String uid, String id, bool isFavorite) async {
    await _history(uid).doc(id).update({'isFavorite': isFavorite});
  }

  /// DELETE — removes one record.
  Future<void> deleteRecord(String uid, String id) async {
    await _history(uid).doc(id).delete();
  }

  /// DELETE ALL — clears the entire history in a single batch.
  Future<void> clearHistory(String uid) async {
    final snapshot = await _history(uid).get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
