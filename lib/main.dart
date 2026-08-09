import 'package:flutter/material.dart';

import 'data/app_state.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LanguageBridgeApp());
}

/// Root widget.
///
/// Owns the single [AppState] instance and rebuilds [MaterialApp] when the
/// theme mode changes. `Firebase.initializeApp()` would go in [main] above.
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
          home: const LoginScreen(),
        ),
      ),
    );
  }
}
