import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lesson_model.dart';

/// Firestore CRUD for the `lessons` collection.
///
/// Keeps all lesson Firestore access out of the widgets. Methods use
/// async/await and let failures propagate so the UI can show an error message.
class LessonService {
  LessonService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _lessons =>
      _db.collection('lessons');

  /// READ — a live stream of the lessons for one language, newest first.
  ///
  /// The query filters by `languageId` only; the newest-first sort is done in
  /// Dart. Doing the sort here (instead of `.orderBy('createdAt')`) avoids a
  /// `where` + `orderBy` composite index, which Firestore would otherwise make
  /// you create by hand before the query would run.
  Stream<List<Lesson>> getLessonsByLanguage(String languageId) {
    return _lessons
        .where('languageId', isEqualTo: languageId)
        .snapshots()
        .map((snapshot) {
      final lessons = snapshot.docs.map(Lesson.fromDoc).toList();
      lessons.sort((a, b) {
        final aTime = a.createdAt;
        final bTime = b.createdAt;
        // A just-created lesson has a null (pending) timestamp — float it to
        // the top so it shows immediately after saving.
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return -1;
        if (bTime == null) return 1;
        return bTime.compareTo(aTime);
      });
      return lessons;
    });
  }

  /// CREATE — adds a new lesson and returns its generated document id.
  Future<String> createLesson(Lesson lesson) async {
    final ref = await _lessons.add({
      ...lesson.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// UPDATE — overwrites the editable fields of an existing lesson and bumps
  /// `updatedAt` (same id → no duplicate is created).
  Future<void> updateLesson(Lesson lesson) async {
    await _lessons.doc(lesson.id).update({
      ...lesson.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// DELETE — removes a single lesson document.
  Future<void> deleteLesson(String lessonId) async {
    await _lessons.doc(lessonId).delete();
  }
}
