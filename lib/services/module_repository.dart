import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/starter_modules.dart';
import '../models/language_model.dart';
import '../models/lesson_model.dart';
import '../models/module_quiz.dart';

abstract class ModuleRepository {
  Stream<List<LanguageModel>> watchLanguages();
  Stream<List<Lesson>> watchLessons(String languageId);
  Stream<AssessmentResult?> watchLatest(String languageId);
  Future<void> saveLatest(String languageId, AssessmentResult result);
}

/// Lessons ship inside the app, so new languages and words reach learners
/// through app updates. Only each learner's latest assessment is stored in
/// Firestore.
class BundledModuleRepository implements ModuleRepository {
  BundledModuleRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _assessment(String languageId) => _db
      .collection('users')
      .doc(userId)
      .collection('assessments')
      .doc(languageId);

  @override
  Stream<List<LanguageModel>> watchLanguages() => Stream.value(
    StarterModules.all.map((m) => m.language).toList()
      ..sort((a, b) => a.name.compareTo(b.name)),
  );

  @override
  Stream<List<Lesson>> watchLessons(String languageId) =>
      Stream.value(StarterModules.forId(languageId)?.lessons() ?? const []);

  @override
  Stream<AssessmentResult?> watchLatest(String languageId) =>
      _assessment(languageId).snapshots().map((doc) {
        final data = doc.data();
        if (data == null) return null;
        return AssessmentResult(
          score: (data['score'] as num).toInt(),
          total: (data['total'] as num).toInt(),
          completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
        );
      });

  @override
  Future<void> saveLatest(String languageId, AssessmentResult result) async {
    if (result.total < 1 || result.score < 0 || result.score > result.total) {
      throw ArgumentError('Invalid assessment score');
    }
    // Stable document ID deliberately replaces the previous assessment.
    await _assessment(languageId).set({
      'score': result.score,
      'total': result.total,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}
