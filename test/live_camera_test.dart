import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languagebridge/services/live_text_filter.dart';
import 'package:languagebridge/widgets/live_camera_card.dart';

void main() {
  test(
    'waits for stable OCR, normalizes whitespace and suppresses repeats',
    () {
      final filter = LiveTextFilter();
      expect(filter.add('good\nmorning'), isNull);
      expect(filter.add(' good   morning '), 'good morning');
      expect(filter.add('good morning'), isNull);
      expect(filter.add('good morning'), isNull);
      expect(filter.add('thank you'), isNull);
      expect(filter.add('thank you'), 'thank you');
    },
  );

  test('moving camera and blank frames cannot trigger unstable text', () {
    final filter = LiveTextFilter();
    expect(filter.add('hello'), isNull);
    expect(filter.add('help'), isNull);
    expect(filter.add(''), isNull);
    expect(filter.add('help'), isNull);
    expect(filter.add('help'), 'help');
    expect(filter.add(''), isNull);
    expect(filter.add('help'), isNull);
    expect(filter.add('help'), isNull);
  });

  testWidgets(
    'unsupported camera displays an explanation and can be closed',
    (tester) async {
      var closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveCameraCard(
              onText: (_) => fail('No camera text expected'),
              onClose: () => closed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('available on Android and iPhone'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Back to typing'));
      expect(closed, isTrue);
    },
    variant: TargetPlatformVariant({TargetPlatform.windows}),
  );
}
