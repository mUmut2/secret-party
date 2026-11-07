import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/core/services/haptic_service.dart';
import 'package:party_game/core/theme/app_theme.dart';
import 'package:party_game/data/repositories/seen_content_store.dart';
import 'package:party_game/domain/models/taboo_match.dart';
import 'package:party_game/domain/services/seen_content_tracker.dart';
import 'package:party_game/features/taboo/viewmodels/taboo_game_notifier.dart';
import 'package:party_game/features/taboo/viewmodels/taboo_setup_state.dart';
import 'package:party_game/features/taboo/views/taboo_game_screen.dart';
import 'package:party_game/features/taboo/views/taboo_result_screen.dart';
import 'package:party_game/features/taboo/views/taboo_setup_screen.dart';

/// Tabu ekranlarının küçük ve standart telefon boyutlarında taşma
/// (RenderFlex overflow) üretmediğini doğrular.
void main() {
  const sizes = {
    'küçük telefon (320x568)': Size(320, 568),
    'standart telefon (375x812)': Size(375, 812),
    'küçük telefon + büyük yazı (1.3x)': Size(320, 568),
  };

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Size size,
    Widget screen, {
    void Function(ProviderContainer container)? arrange,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        hapticServiceProvider.overrideWithValue(
          const HapticService(enabled: false),
        ),
        seenContentTrackerProvider.overrideWithValue(
          SeenContentTracker(InMemorySeenContentStore()),
        ),
      ],
    );
    addTearDown(container.dispose);
    arrange?.call(container);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark, home: screen),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    return container;
  }

  void startMatch(ProviderContainer container) {
    container
        .read(tabooGameProvider.notifier)
        .startGame(const TabooSetupState().toSettings());
  }

  for (final entry in sizes.entries) {
    group(entry.key, () {
      // Sistem yazı boyutu büyütülmüş küçük telefon (erişilebilirlik).
      if (entry.key.contains('büyük yazı')) {
        setUp(() => TestWidgetsFlutterBinding
            .instance.platformDispatcher.textScaleFactorTestValue = 1.3);
        tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher
            .clearTextScaleFactorTestValue());
      }

      testWidgets('kurulum ekranı taşmaz', (tester) async {
        await pump(tester, entry.value, const TabooSetupScreen());
        expect(tester.takeException(), isNull);
        expect(find.text('OYUNA BAŞLA'), findsOneWidget);
      });

      testWidgets('hazır ekranı taşmaz', (tester) async {
        await pump(
          tester,
          entry.value,
          const TabooGameScreen(),
          arrange: startMatch,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('BAŞLA'), findsOneWidget);
      });

      testWidgets('oyun ekranı ve 3 aksiyon butonu taşmaz', (tester) async {
        final container = await pump(
          tester,
          entry.value,
          const TabooGameScreen(),
          arrange: (c) {
            startMatch(c);
            c.read(tabooGameProvider.notifier).startTurn();
          },
        );
        expect(tester.takeException(), isNull);
        expect(find.text('TABU!'), findsOneWidget);
        expect(find.text('PAS (3)'), findsOneWidget);
        expect(find.text('DOĞRU'), findsOneWidget);

        await tester.tap(find.text('DOĞRU'));
        await tester.pump(const Duration(seconds: 1));
        expect(container.read(tabooGameProvider)!.activeTeam.score, 1);
        expect(tester.takeException(), isNull);

        // Zamanlayıcıyı durdurmak için maçtan çık.
        container.read(tabooGameProvider.notifier).quit();
        await tester.pump();
      });

      testWidgets('tur sonu ekranı taşmaz', (tester) async {
        await pump(
          tester,
          entry.value,
          const TabooResultScreen(),
          arrange: (c) {
            startMatch(c);
            final notifier = c.read(tabooGameProvider.notifier)..startTurn();
            for (var i = 0; i < 6; i++) {
              notifier.markCorrect();
            }
            notifier
              ..markTaboo()
              ..pass();
            // Süre dolmuş gibi turu motor üzerinden bitir.
            final match = c.read(tabooGameProvider)!;
            c.read(tabooGameProvider.notifier).quit();
            c.read(tabooGameProvider.notifier).state =
                c.read(tabooEngineProvider).endTurn(match);
          },
        );
        expect(tester.takeException(), isNull);
        expect(find.textContaining('SIRAYI DEVRET'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is Text && w.data == '+5 puan',
          ),
          findsOneWidget,
        );
      });
    });
  }

  test('oyun bitişi durumları ekranda kullanılan enum ile aynı', () {
    expect(TabooGameStatus.values, hasLength(4));
  });
}
