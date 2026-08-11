import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/app_state.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();
  runApp(const LanguageBridgeApp());
}

/// Initializes Firebase. Best-effort: if `firebase_options.dart` is still the
/// placeholder (you haven't run `flutterfire configure`), the app still boots
/// and the auth gate simply shows the login screen.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase not initialized (run flutterfire configure): $e');
  }
}

/// Root widget.
///
/// Owns the single [AppState] instance and rebuilds [MaterialApp] when auth or
/// theme changes. The `home` acts as an auth gate: splash while auth resolves,
/// then the login screen or the app shell.
class LanguageBridgeApp extends StatefulWidget {
  const LanguageBridgeApp({super.key});

  @override
  State<LanguageBridgeApp> createState() => _LanguageBridgeAppState();
}

class _LanguageBridgeAppState extends State<LanguageBridgeApp> {
  final _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: AnimatedBuilder(
        animation: _state,
        builder: (context, _) => MaterialApp(
          title: 'Language Bridge',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: _state.themeMode,
          home: _gate(),
        ),
      ),
    );
  }

  /// Chooses the root screen from the current auth state.
  Widget _gate() {
    if (!_state.authResolved) return const SplashScreen();
    return _state.isSignedIn ? const HomeShell() : const LoginScreen();
  }
}
