import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/starter_modules.dart';
import '../models/language_model.dart';

/// Optional import makes the bundled words editable in the existing CRUD UI.
/// Stable IDs and a transaction marker make repeated/concurrent imports safe.
class StarterContentService {
  StarterContentService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  Future<int> importAll() async {
    final snapshot = await _db.collection('languages').get();
    final existing = snapshot.docs.map(LanguageModel.fromDoc).toList();
    var added = 0;
    for (final module in StarterModules.all) {
      final matches = existing.where(module.matches).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      final languageId = matches.isEmpty ? module.id : matches.first.id;
      final languageRef = _db.collection('languages').doc(languageId);
      final oldLessons = await _db
          .collection('lessons')
          .where('languageId', isEqualTo: languageId)
          .get();
      final existingWords = oldLessons.docs
          .map(
            (doc) => StarterModules.normalize(
              (doc.data()['content'] as String?) ?? '',
            ),
          )
          .toSet();
      final lessons = module.lessons(languageId: languageId);
      added += await _db.runTransaction<int>((transaction) async {
        final current = await transaction.get(languageRef);
        if (((current.data()?['starterContentVersion'] as num?) ?? 0) >= 1) {
          return 0;
        }
        final refs = lessons
            .map((l) => _db.collection('lessons').doc(l.id))
            .toList();
        final saved = <DocumentSnapshot<Map<String, dynamic>>>[];
        for (final ref in refs) {
          saved.add(await transaction.get(ref));
        }
        // All transaction reads precede writes. Existing records are never replaced.
        if (!current.exists) {
          transaction.set(languageRef, {
            ...module.language.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
            'starterContentVersion': 1,
          });
        } else {
          transaction.update(languageRef, {'starterContentVersion': 1});
        }
        var count = 0;
        for (var i = 0; i < lessons.length; i++) {
          if (saved[i].exists ||
              existingWords.contains(
                StarterModules.normalize(lessons[i].content),
              )) {
            continue;
          }
          transaction.set(refs[i], {
            ...lessons[i].toMap(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          count++;
        }
        return count;
      });
    }
    return added;
  }
}
