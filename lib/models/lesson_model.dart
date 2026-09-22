import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// A lesson under a language, stored in the Firestore `lessons` collection.
///
/// [languageId] links the lesson back to its parent document in `languages`.
@immutable
class Lesson {
  const Lesson({
    required this.id,
    required this.languageId,
    required this.title,
    required this.description,
    required this.category,
    required this.content,
    required this.translation,
    required this.pronunciation,
    this.meaning = '',
    this.sourceUrl = '',
    this.createdAt,
    this.updatedAt,
  });

  /// Firestore document id. Empty string for an unsaved draft.
  final String id;
  final String languageId;
  final String title;
  final String description;
  final String category;
  final String content;
  final String translation;
  final String pronunciation;
  final String meaning;
  final String sourceUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// A blank draft for the "Add Lesson" form, pre-linked to [languageId].
  factory Lesson.empty(String languageId) => Lesson(
    id: '',
    languageId: languageId,
    title: '',
    description: '',
    category: '',
    content: '',
    translation: '',
    pronunciation: '',
  );

  factory Lesson.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Lesson(
      id: doc.id,
      languageId: (data['languageId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      category: (data['category'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      translation: (data['translation'] as String?) ?? '',
      pronunciation: (data['pronunciation'] as String?) ?? '',
      meaning: (data['meaning'] as String?) ?? '',
      sourceUrl: (data['sourceUrl'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// The editable fields written to Firestore. `createdAt`/`updatedAt` are set
  /// by the service with server timestamps, so they are excluded here.
  Map<String, dynamic> toMap() => {
    'languageId': languageId,
    'title': title,
    'description': description,
    'category': category,
    'content': content,
    'translation': translation,
    'pronunciation': pronunciation,
    'meaning': meaning,
    'sourceUrl': sourceUrl,
  };

  Lesson copyWith({
    String? languageId,
    String? title,
    String? description,
    String? category,
    String? content,
    String? translation,
    String? pronunciation,
    String? meaning,
    String? sourceUrl,
  }) {
    return Lesson(
      id: id,
      languageId: languageId ?? this.languageId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      content: content ?? this.content,
      translation: translation ?? this.translation,
      pronunciation: pronunciation ?? this.pronunciation,
      meaning: meaning ?? this.meaning,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
