import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/language_model.dart';

/// Firestore CRUD for the `languages` collection.
///
/// All Firestore access for languages lives here — the widgets never touch
/// `FirebaseFirestore` directly. Every method uses async/await and lets
/// failures propagate as exceptions so the UI can surface an error message.
class LanguageService {
  LanguageService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _languages =>
      _db.collection('languages');
  CollectionReference<Map<String, dynamic>> get _lessons =>
      _db.collection('lessons');

  /// READ — a live stream of all languages, ordered alphabetically by name.
  ///
  /// Ordering on `name` (always present) needs only Firestore's automatic
  /// single-field index, so there is no composite index to create by hand.
  /// The stream re-emits whenever any language document changes.
  Stream<List<LanguageModel>> getLanguages() {
    return _languages.orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs.map(LanguageModel.fromDoc).toList(),
        );
  }

  /// CREATE — adds a new language and returns its generated document id.
  Future<String> createLanguage(LanguageModel language) async {
    final ref = await _languages.add({
      ...language.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// UPDATE — overwrites the editable fields of an existing language document
  /// (same id → no duplicate is created).
  Future<void> updateLanguage(LanguageModel language) async {
    await _languages.doc(language.id).update(language.toMap());
  }

  /// DELETE — removes the language and every lesson that belongs to it, in a
  /// single atomic batch so no orphaned lessons are left behind.
  Future<void> deleteLanguage(String languageId) async {
    final relatedLessons =
        await _lessons.where('languageId', isEqualTo: languageId).get();

    final batch = _db.batch();
    for (final doc in relatedLessons.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_languages.doc(languageId));
    await batch.commit();
  }
}
