import 'package:flutter/material.dart';

import 'history_screen.dart';
import 'profile_screen.dart';
import 'translate_screen.dart';
import 'module_screen.dart';
import '../widgets/glass_navigation_bar.dart';

/// Floating navigation container for the four main screens.
///
/// Uses [IndexedStack] so each tab keeps its scroll position and form state
/// when the user switches away and back.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _index,
          children: const [
            TranslateScreen(),
            HistoryScreen(),
            ModuleScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: GlassNavigationBar(
        selectedIndex: _index,
        onSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
