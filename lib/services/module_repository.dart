import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/starter_modules.dart';
import '../models/language_model.dart';
import '../models/lesson_model.dart';
import '../models/module_quiz.dart';
import 'language_service.dart';
import 'lesson_service.dart';

abstract class ModuleRepository {
  Stream<List<LanguageModel>> watchLanguages();
  Stream<List<Lesson>> watchLessons(String languageId);
  Stream<AssessmentResult?> watchLatest(String languageId);
  Future<void> saveLatest(String languageId, AssessmentResult result);
}

class FirestoreModuleRepository implements ModuleRepository {
  FirestoreModuleRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _db;
  final _starterByLanguageId = <String, StarterModule>{};
  final _importedLanguageIds = <String>{};

  DocumentReference<Map<String, dynamic>> _assessment(String languageId) => _db
      .collection('users')
      .doc(userId)
      .collection('assessments')
      .doc(languageId);

  @override
  Stream<List<LanguageModel>> watchLanguages() async* {
    var receivedCatalog = false;
    try {
      await for (final remote in LanguageService(
        firestore: _db,
      ).getLanguages()) {
        receivedCatalog = true;
        _starterByLanguageId.clear();
        _importedLanguageIds.clear();
        for (final language in remote) {
          final starter = StarterModules.forLanguage(language);
          if (starter != null) _starterByLanguageId[language.id] = starter;
          if (language.starterContentVersion > 0) {
            _importedLanguageIds.add(language.id);
          }
        }
        yield StarterModules.mergeLanguages(
          remote,
        ).where((l) => l.isActive).toList();
      }
    } catch (error) {
      // Bundled learning content remains usable if the catalog is unavailable.
      debugPrint('Cloud module catalog unavailable: $error');
      if (!receivedCatalog) {
        yield StarterModules.mergeLanguages([]);
      }
    }
  }

  @override
  Stream<List<Lesson>> watchLessons(String languageId) async* {
    final starter =
        _starterByLanguageId[languageId] ?? StarterModules.forId(languageId);
    if (starter != null && !_importedLanguageIds.contains(languageId)) {
      yield starter.lessons(languageId: languageId);
    }
    try {
      await for (final lessons in LessonService(
        firestore: _db,
      ).getLessonsByLanguage(languageId)) {
        yield starter == null || _importedLanguageIds.contains(languageId)
            ? lessons
            : StarterModules.mergeLessons(starter, languageId, lessons);
      }
    } catch (error) {
      if (starter == null || _importedLanguageIds.contains(languageId)) rethrow;
      debugPrint('Cloud lessons unavailable; using bundled words: $error');
    }
  }

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
