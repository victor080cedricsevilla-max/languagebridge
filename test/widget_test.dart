import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:languagebridge/main.dart';

/// Sizes the test viewport like a phone. The default 800x600 surface is wider
/// and shorter than any real device, which pushes the auth form off-screen.
void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('app opens on the login screen', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const LanguageBridgeApp());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('login rejects an invalid email', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const LanguageBridgeApp());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'you@example.com'),
      'not-an-email',
    );

    final signIn = find.widgetWithText(FilledButton, 'Sign In');
    await tester.ensureVisible(signIn);
    await tester.pumpAndSettle();
    await tester.tap(signIn);
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('demo account lands on the translate tab', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const LanguageBridgeApp());

    final skip = find.text('Skip — explore with demo account');
    await tester.ensureVisible(skip);
    await tester.pumpAndSettle();
    await tester.tap(skip);
    await tester.pumpAndSettle();

    // Bottom navigation is up with all three destinations.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Translate'), findsWidgets);
    expect(find.text('History'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);

    // Translate tab greets the seeded demo user.
    expect(find.text('Hi Cedric 👋'), findsOneWidget);
  });

  testWidgets('translating a known phrase adds it to history', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const LanguageBridgeApp());

    final skip = find.text('Skip — explore with demo account');
    await tester.ensureVisible(skip);
    await tester.pumpAndSettle();
    await tester.tap(skip);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Enter text to translate…'),
      'thank you',
    );
    await tester.pump();

    final translate = find.byKey(const ValueKey('translate-button'));
    await tester.ensureVisible(translate);
    await tester.pumpAndSettle();
    await tester.tap(translate);
    await tester.pumpAndSettle();

    // English -> Filipino is the default pair.
    expect(find.text('Salamat'), findsOneWidget);
  });
}
