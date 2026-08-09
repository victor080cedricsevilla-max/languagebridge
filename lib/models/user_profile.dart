import 'package:flutter/foundation.dart';

/// The signed-in user. Stands in for a Firebase Auth user plus their
/// Firestore profile document.
@immutable
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    this.avatarUrl,
    this.memberSince,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime? memberSince;

  /// First letters of the first two words — used when there is no photo.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  UserProfile copyWith({String? name, String? email, String? avatarUrl}) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      memberSince: memberSince,
    );
  }
}
