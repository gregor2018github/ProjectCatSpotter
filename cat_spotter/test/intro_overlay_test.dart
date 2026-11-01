import 'package:cat_spotter/providers/app_providers.dart';
import 'package:cat_spotter/widgets/intro_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  // Don't fetch fonts over the network in tests.
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<ProviderContainer> pumpIntro(WidgetTester tester) async {
    final container = ProviderContainer();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: IntroOverlay(child: Text('app content')),
      ),
    ));
    return container;
  }

  testWidgets('single tap skips the intro immediately', (tester) async {
    final c = await pumpIntro(tester);
    await tester.pump(const Duration(milliseconds: 300)); // mid-animation
    expect(find.text('Cat Spotter'), findsOneWidget);
    expect(c.read(introFinishedProvider), isFalse);

    await tester.tap(find.text('Cat Spotter'));
    await tester.pump(); // first frame starts the 150ms fade-out
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pump(); // overlay removed on the frame after the fade ends

    expect(find.text('Cat Spotter'), findsNothing);
    expect(find.text('app content'), findsOneWidget);
    expect(c.read(introFinishedProvider), isTrue);

    // Let the start-up font wait time out; skipping must not restart it.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Cat Spotter'), findsNothing);
  });

  testWidgets('intro finishes by itself', (tester) async {
    final c = await pumpIntro(tester);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(c.read(introFinishedProvider), isFalse);

    // Start delay + 2.6s build + 0.4s hold + 0.35s fade, well under 6s.
    for (var i = 0; i < 60 && !c.read(introFinishedProvider); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump();

    expect(find.text('Cat Spotter'), findsNothing);
    expect(c.read(introFinishedProvider), isTrue);
  });
}
