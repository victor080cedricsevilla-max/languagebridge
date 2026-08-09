import 'package:flutter/material.dart';

import '../models/translation_record.dart';
import '../models/user_profile.dart';
import 'mock_data.dart';

/// In-memory app state for the UI prototype.
///
/// Everything here lives only for the life of the process — no Firestore, no
/// disk. Each mutating method is where a repository call would eventually go.
class AppState extends ChangeNotifier {
  AppState() : _history = seedHistory();

  List<TranslationRecord> _history;
  UserProfile? _user;
  ThemeMode _themeMode = ThemeMode.system;
  String _sourceLang = 'en';
  String _targetLang = 'fil';
  bool _notificationsEnabled = true;
  bool _offlineModeEnabled = false;
  bool _autoDetectEnabled = true;

  // ---------------------------------------------------------------- getters

  List<TranslationRecord> get history => List.unmodifiable(_history);

  List<TranslationRecord> get favorites =>
      List.unmodifiable(_history.where((r) => r.isFavorite));

  UserProfile? get user => _user;
  bool get isSignedIn => _user != null;
  ThemeMode get themeMode => _themeMode;
  String get sourceLang => _sourceLang;
  String get targetLang => _targetLang;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get offlineModeEnabled => _offlineModeEnabled;
  bool get autoDetectEnabled => _autoDetectEnabled;

  /// Distinct target languages the user has translated into.
  int get languagesUsed =>
      _history.map((r) => r.targetLangCode).toSet().length;

  // ------------------------------------------------------------------ auth

  /// Prototype sign-in: accepts anything the form already validated.
  /// Firebase Auth would replace this body.
  void signIn({required String email, String? name}) {
    _user = UserProfile(
      name: name ?? _nameFromEmail(email),
      email: email,
      memberSince: DateTime.now(),
    );
    notifyListeners();
  }

  /// Signs in as the seeded demo account.
  void signInAsDemo() {
    _user = kDemoUser;
    notifyListeners();
  }

  void signOut() {
    _user = null;
    notifyListeners();
  }

  void updateProfile({String? name, String? email}) {
    final current = _user;
    if (current == null) return;
    _user = current.copyWith(name: name, email: email);
    notifyListeners();
  }

  static String _nameFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[._\-+]'), ' ');
    return local
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  // ------------------------------------------------------------- languages

  void setSourceLang(String code) {
    if (code == _sourceLang) return;
    // Picking the current target as the new source swaps the pair instead of
    // leaving the user with the same language on both sides.
    if (code == _targetLang) {
      _targetLang = _sourceLang;
    }
    _sourceLang = code;
    notifyListeners();
  }

  void setTargetLang(String code) {
    if (code == _targetLang) return;
    if (code == _sourceLang) {
      _sourceLang = _targetLang;
    }
    _targetLang = code;
    notifyListeners();
  }

  void swapLanguages() {
    final tmp = _sourceLang;
    _sourceLang = _targetLang;
    _targetLang = tmp;
    notifyListeners();
  }

  // --------------------------------------------------------------- history

  void addRecord(TranslationRecord record) {
    _history = [record, ..._history];
    notifyListeners();
  }

  void toggleFavorite(String id) {
    _history = [
      for (final r in _history)
        if (r.id == id) r.copyWith(isFavorite: !r.isFavorite) else r,
    ];
    notifyListeners();
  }

  /// Removes [id] and returns the deleted record so the caller can offer undo.
  TranslationRecord? deleteRecord(String id) {
    final index = _history.indexWhere((r) => r.id == id);
    if (index == -1) return null;
    final removed = _history[index];
    _history = [..._history]..removeAt(index);
    notifyListeners();
    return removed;
  }

  /// Puts a deleted record back at [index] (used by the undo action).
  void restoreRecord(TranslationRecord record, int index) {
    final next = [..._history];
    next.insert(index.clamp(0, next.length), record);
    _history = next;
    notifyListeners();
  }

  int indexOfRecord(String id) => _history.indexWhere((r) => r.id == id);

  void clearHistory() {
    _history = [];
    notifyListeners();
  }

  // -------------------------------------------------------------- settings

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void setOfflineModeEnabled(bool value) {
    _offlineModeEnabled = value;
    notifyListeners();
  }

  void setAutoDetectEnabled(bool value) {
    _autoDetectEnabled = value;
    notifyListeners();
  }
}

/// Makes [AppState] available to the widget tree.
///
/// `AppScope.of(context)` rebuilds the caller on change; `AppScope.read(context)`
/// reads once without subscribing (use inside callbacks).
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!.notifier!;
  }
}
