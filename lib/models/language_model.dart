import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// A language-learning module stored in the Firestore `languages` collection.
///
/// This is the CRUD/admin entity managed by administrators. It is deliberately
/// separate from [Language] in `models/language.dart`, which is the ISO
/// translation language used by the translator UI.
@immutable
class LanguageModel {
  const LanguageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isActive,
    this.createdAt,
  });

  /// Firestore document id. Empty string for an unsaved draft.
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final bool isActive;

  /// Set by the server on create. Null while a create is still pending.
  final DateTime? createdAt;

  /// A blank draft used by the "Add Language" form.
  factory LanguageModel.empty() => const LanguageModel(
        id: '',
        name: '',
        description: '',
        imageUrl: '',
        isActive: true,
      );

  /// Builds a model from a Firestore document snapshot.
  factory LanguageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return LanguageModel(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? '',
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// The editable fields written to Firestore.
  ///
  /// `createdAt` is intentionally excluded — the service sets it with a server
  /// timestamp on create and never overwrites it on update.
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'isActive': isActive,
      };

  LanguageModel copyWith({
    String? name,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) {
    return LanguageModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
