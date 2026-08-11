import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/translation_record.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/history_service.dart';

/// App-wide state: authentication, per-user translation history, and UI prefs.
///
/// Auth and history are backed by Firebase ([AuthService] + [HistoryService]);
/// theme and language preferences are in-memory. The widget tree reads all of
/// this through [AppScope].
class AppState extends ChangeNotifier {
  AppState({AuthService? authService, HistoryService? historyService})
      : _auth = authService ?? AuthService(),
        _historyService = historyService ?? HistoryService() {
    // Drive the app off Firebase's auth state: the first event resolves the
    // splash, and every sign-in/out re-points the history stream.
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final AuthService _auth;
  final HistoryService _historyService;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<TranslationRecord>>? _historySub;

  User? _firebaseUser;
  bool _authResolved = false;
  List<TranslationRecord> _history = [];

  ThemeMode _themeMode = ThemeMode.system;
  String _sourceLang = 'en';
  String _targetLang = 'ceb';
  bool _notificationsEnabled = true;
  bool _offlineModeEnabled = false;
  bool _autoDetectEnabled = true;

  // ---------------------------------------------------------------- auth glue

  void _onAuthChanged(User? user) {
    _firebaseUser = user;
    _authResolved = true;
    _resubscribeHistory(user);
    notifyListeners();
  }

  void _resubscribeHistory(User? user) {
    _historySub?.cancel();
    _historySub = null;
    if (user == null) {
      _history = [];
      return;
    }
    _historySub = _historyService.getHistory(user.uid).listen((records) {
      _history = records;
      notifyListeners();
    });
  }

  // ---------------------------------------------------------------- getters

  /// True once Firebase has reported the initial auth state (splash → app).
  bool get authResolved => _authResolved;
  bool get isSignedIn => _firebaseUser != null;

  /// The signed-in user projected onto the app's [UserProfile] shape, or null.
  UserProfile? get user {
    final u = _firebaseUser;
    if (u == null) return null;
    final displayName = u.displayName?.trim();
    return UserProfile(
      name: (displayName != null && displayName.isNotEmpty)
          ? displayName
          : _nameFromEmail(u.email ?? ''),
      email: u.email ?? '',
      avatarUrl: u.photoURL,
      memberSince: u.metadata.creationTime,
    );
  }

  List<TranslationRecord> get history => List.unmodifiable(_history);

  List<TranslationRecord> get favorites =>
      List.unmodifiable(_history.where((r) => r.isFavorite));

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

  /// Signs in with email/password. Throws on failure so the caller can show a
  /// message (see [authErrorMessage]); on success the auth stream updates the
  /// gate automatically.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signIn(email: email, password: password);
  }

  /// Creates an account, sets the display name, and signs in. Throws on failure.
  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) {
    return _auth.signUp(name: name, email: email, password: password);
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordReset(email);

  Future<void> signOut() => _auth.signOut();

  Future<void> updateProfile({required String name}) async {
    await _auth.updateDisplayName(name);
    _firebaseUser = _auth.currentUser;
    notifyListeners();
  }

  static String _nameFromEmail(String email) {
    if (email.isEmpty) return 'User';
    final local = email.split('@').first.replaceAll(RegExp(r'[._\-+]'), ' ');
    final words = local.split(' ').where((w) => w.isNotEmpty);
    if (words.isEmpty) return 'User';
    return words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
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
  //
  // Mutators write to Firestore; the history stream ([_resubscribeHistory])
  // is the source of truth and updates [_history] when the write lands.

  String? get _uid => _firebaseUser?.uid;

  Future<void> addRecord(TranslationRecord record) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _historyService.addRecord(uid, record);
    } catch (e) {
      debugPrint('addRecord failed: $e');
    }
  }

  /// Flips the favorite flag and returns the new value (used for the toast).
  Future<bool> toggleFavorite(String id) async {
    final uid = _uid;
    if (uid == null) return false;
    final index = _history.indexWhere((r) => r.id == id);
    if (index == -1) return false;
    final next = !_history[index].isFavorite;
    try {
      await _historyService.setFavorite(uid, id, next);
    } catch (e) {
      debugPrint('toggleFavorite failed: $e');
    }
    return next;
  }

  /// Removes [id] and returns the deleted record (from cache) so the caller can
  /// offer undo. The Firestore delete runs in the background.
  TranslationRecord? deleteRecord(String id) {
    final uid = _uid;
    if (uid == null) return null;
    final index = _history.indexWhere((r) => r.id == id);
    if (index == -1) return null;
    final removed = _history[index];
    _historyService
        .deleteRecord(uid, id)
        .catchError((Object e) => debugPrint('deleteRecord failed: $e'));
    return removed;
  }

  /// Re-adds a previously deleted record (used by the undo action). Firestore
  /// re-inserts it in the right place by its original timestamp.
  void restoreRecord(TranslationRecord record, int index) {
    final uid = _uid;
    if (uid == null) return;
    _historyService
        .addRecord(uid, record)
        .catchError((Object e) => debugPrint('restoreRecord failed: $e'));
  }

  int indexOfRecord(String id) => _history.indexWhere((r) => r.id == id);

  Future<void> clearHistory() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _historyService.clearHistory(uid);
    } catch (e) {
      debugPrint('clearHistory failed: $e');
    }
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

  @override
  void dispose() {
    _authSub?.cancel();
    _historySub?.cancel();
    super.dispose();
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
