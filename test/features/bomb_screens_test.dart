import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/app/session_guard.dart';
import 'package:party_game/core/routing/app_router.dart';
import 'package:party_game/core/services/audio_service.dart';
import 'package:party_game/core/services/haptic_service.dart';
import 'package:party_game/core/services/wakelock_service.dart';
import 'package:party_game/core/theme/app_theme.dart';
import 'package:party_game/data/repositories/local_storage_repository.dart';
import 'package:party_game/domain/models/bomb/bomb_game_state.dart';
import 'package:party_game/domain/models/bomb/bomb_settings.dart';
import 'package:party_game/domain/models/player.dart';
import 'package:party_game/features/bomb/viewmodels/bomb_game_notifier.dart';
import 'package:party_game/features/bomb/viewmodels/bomb_setup_notifier.dart';
import 'package:party_game/features/bomb/views/bomb_explosion_screen.dart';
import 'package:party_game/features/bomb/views/bomb_final_screen.dart';
import 'package:party_game/features/bomb/views/bomb_play_screen.dart';
import 'package:party_game/features/bomb/views/bomb_ready_screen.dart';
import 'package:party_game/features/bomb/views/bomb_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Elle ilerletilen sahte saat (fitil bitiş zamanı bununla hesaplanır).
class _FakeClock {
  DateTime now = DateTime(2026, 10, 18, 22);

  DateTime call() => now;

  void advance(Duration duration) => now = now.add(duration);
}

class _SilentWakelock extends WakelockService {
  @override
  Future<void> setEnabled(bool enabled) async {}
}

void main() {
  final players = [
    for (final name in ['Ali', 'Ayşe', 'Can', 'Ece'])
      Player(id: name, name: name),
  ];

  /// En uzun fitilden de uzun bir süre: bu kadar ilerletilince bomba
  /// kesinlikle patlar.
  final beyondAnyFuse = Duration(seconds: BombFuse.long.maxSeconds + 1);

  Future<(ProviderContainer, _FakeClock)> createContainer([
    Map<String, Object> prefs = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(prefs);
    final preferences = await SharedPreferences.getInstance();
    final clock = _FakeClock();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        hapticServiceProvider.overrideWithValue(
          const HapticService(enabled: false),
        ),
        audioServiceProvider.overrideWithValue(
          const AudioService(enabled: false),
        ),
        bombClockProvider.overrideWithValue(clock.call),
        wakelockServiceProvider.overrideWithValue(_SilentWakelock()),
      ],
    );
    addTearDown(container.dispose);
    return (container, clock);
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    ProviderContainer container,
    Widget screen, {
    Size size = const Size(375, 812),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark, home: screen),
      ),
    );
    await tester.pump();
  }

  BombGameNotifier game(ProviderContainer c) =>
      c.read(bombGameProvider.notifier);

  group('fitil ve tur', () {
    testWidgets('fitil bitince bombayı tutan oyuncu patlar', (tester) async {
      final (c, clock) = await createContainer();
      game(c)
        ..startGame(players, const BombSettings(fuse: BombFuse.short))
        ..startRound();
      expect(c.read(bombGameProvider)!.phase, BombPhase.ticking);

      clock.advance(const Duration(seconds: 14));
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.read(bombGameProvider)!.phase, BombPhase.ticking,
          reason: 'Kısa fitil en az 15 sn');

      final holder = c.read(bombGameProvider)!.holder.id;
      clock.advance(const Duration(seconds: 17));
      await tester.pump(const Duration(milliseconds: 100));
      final state = c.read(bombGameProvider)!;
      expect(state.phase, BombPhase.exploded);
      expect(state.lastExplodedId, holder);
      expect(state.explosionsOf(holder), 1);
    });

    testWidgets('arka plana alınınca fitil durur, dönünce devam eder',
        (tester) async {
      final (c, clock) = await createContainer();
      game(c)
        ..startGame(players, const BombSettings(fuse: BombFuse.short))
        ..startRound();

      clock.advance(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 100));
      game(c).pause();
      expect(game(c).isPaused, isTrue);

      // Cepte geçen uzun süre fitili yakmaz.
      clock.advance(const Duration(minutes: 10));
      await tester.pump(const Duration(seconds: 1));
      expect(c.read(bombGameProvider)!.phase, BombPhase.ticking);

      game(c).resume();
      expect(game(c).isPaused, isFalse);
      // Kalan süre en az 10 sn (15 - 5): hemen patlamaz.
      clock.advance(const Duration(seconds: 9));
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.read(bombGameProvider)!.phase, BombPhase.ticking);

      clock.advance(beyondAnyFuse);
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.read(bombGameProvider)!.phase, BombPhase.exploded);
    });

    testWidgets('duraklatmalar sayılır: hepsi kalkınca fitil yanar',
        (tester) async {
      final (c, clock) = await createContainer();
      game(c)
        ..startGame(players, const BombSettings(fuse: BombFuse.short))
        ..startRound()
        ..pause()
        ..pause()
        ..resume();
      expect(game(c).isPaused, isTrue);
      game(c).resume();
      expect(game(c).isPaused, isFalse);
      clock.advance(beyondAnyFuse);
      await tester.pump(const Duration(milliseconds: 100));
      expect(c.read(bombGameProvider)!.phase, BombPhase.exploded);
    });

    testWidgets('GEÇİR çift dokunuşa karşı korumalı', (tester) async {
      final (c, clock) = await createContainer();
      game(c)
        ..startGame(players, const BombSettings())
        ..startRound();
      final start = c.read(bombGameProvider)!.holderIndex;

      expect(game(c).passBomb(), isTrue);
      expect(game(c).passBomb(), isFalse, reason: 'debounce');
      expect(
        c.read(bombGameProvider)!.holderIndex,
        (start + 1) % players.length,
      );
      clock.advance(BombGameNotifier.passDebounce);
      expect(game(c).passBomb(), isTrue);
      game(c).quit();
    });

    testWidgets('tüm turlar bitince final; görevler tekrar etmez',
        (tester) async {
      final (c, clock) = await createContainer();
      game(c).startGame(players, const BombSettings(rounds: 5));
      final prompts = <String>{c.read(bombGameProvider)!.task.prompt};
      for (var round = 1; round <= 5; round++) {
        game(c).startRound();
        clock.advance(beyondAnyFuse);
        await tester.pump(const Duration(milliseconds: 100));
        expect(c.read(bombGameProvider)!.phase, BombPhase.exploded);
        game(c).nextRound();
        final state = c.read(bombGameProvider)!;
        if (!state.isFinished) prompts.add(state.task.prompt);
      }
      expect(c.read(bombGameProvider)!.phase, BombPhase.finished);
      expect(prompts.length, 5);
    });
  });

  group('ayarlar', () {
    test('ayarlar kaydedilir ve yeniden açılışta okunur', () async {
      final (c, _) = await createContainer();
      c.read(bombSetupProvider.notifier)
        ..setFuse(BombFuse.long)
        ..setRounds(15)
        ..setCategory('hayvan');
      await pumpEventQueue();

      final preferences = c.read(sharedPreferencesProvider);
      final reopened = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(reopened.dispose);
      final settings = reopened.read(bombSetupProvider).settings;
      expect(settings.fuse, BombFuse.long);
      expect(settings.rounds, 15);
      expect(settings.categoryId, 'hayvan');
    });

    test('bozuk kayıtta varsayılanlar kullanılır', () async {
      final (c, _) = await createContainer({
        'bomb_fuse_v1': 'yok',
        'bomb_rounds_v1': 7,
        'bomb_category_v1': 'kaldirildi',
      });
      final settings = c.read(bombSetupProvider).settings;
      expect(settings.fuse, BombFuse.medium);
      expect(settings.rounds, 10);
      expect(settings.categoryId, isNull);
    });
  });

  group('ekranlar', () {
    testWidgets('kurulumda en az 3 oyuncu kuralı', (tester) async {
      final (c, _) = await createContainer();
      await pumpScreen(tester, c, const BombSetupScreen());
      final notifier = c.read(bombSetupProvider.notifier)
        ..addPlayer('Ali')
        ..addPlayer('Ayşe');
      await tester.pump();
      expect(find.text('En az 3 oyuncu gerekli.'), findsOneWidget);
      expect(c.read(bombSetupProvider).canStart, isFalse);

      notifier.addPlayer('Can');
      await tester.pump();
      expect(find.text('En az 3 oyuncu gerekli.'), findsNothing);
      expect(c.read(bombSetupProvider).canStart, isTrue);
    });

    testWidgets('bomba ekranında kalan süre / sayı / çubuk görünmez',
        (tester) async {
      final (c, clock) = await createContainer();
      game(c)
        ..startGame(players, const BombSettings())
        ..startRound();
      await pumpScreen(tester, c, const BombPlayScreen());
      clock.advance(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Tur rozeti dışında hiçbir metinde rakam yok (süre gösterilmez).
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .where((t) => !t.startsWith('TUR '));
      expect(texts.where((t) => t.contains(RegExp(r'\d'))), isEmpty);
      // Ekran okuyucu etiketlerinde de süre yok.
      final handle = tester.ensureSemantics();
      final labels =
          find.bySemanticsLabel(RegExp(r'saniye|sn|süre|kalan')).evaluate();
      expect(labels, isEmpty);
      handle.dispose();
      game(c).quit();
    });

    testWidgets('bomba ekranı arka plana alınınca fitili duraklatır',
        (tester) async {
      final (c, _) = await createContainer();
      game(c)
        ..startGame(players, const BombSettings())
        ..startRound();
      await pumpScreen(tester, c, const BombPlayScreen());

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(game(c).isPaused, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(game(c).isPaused, isFalse);
      game(c).quit();
    });

    testWidgets('geri tuşu çıkış onayı sorar ve fitili bekletir',
        (tester) async {
      final (c, _) = await createContainer();
      game(c)
        ..startGame(players, const BombSettings())
        ..startRound();
      await pumpScreen(tester, c, const BombPlayScreen());

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Oyundan Çık'), findsOneWidget);
      expect(game(c).isPaused, isTrue);

      await tester.tap(find.text('OYUNA DEVAM ET'));
      await tester.pumpAndSettle();
      expect(game(c).isPaused, isFalse);
      expect(c.read(bombGameProvider), isNotNull);
      game(c).quit();
    });

    testWidgets('patlama ekranı patlayanı ve sayısını gösterir',
        (tester) async {
      final (c, clock) = await createContainer();
      game(c)
        ..startGame(players, const BombSettings())
        ..startRound();
      clock.advance(beyondAnyFuse);
      await tester.pump(const Duration(milliseconds: 100));
      final exploded = c.read(bombGameProvider)!.lastExploded!;

      await pumpScreen(tester, c, const BombExplosionScreen());
      await tester.pumpAndSettle();
      expect(find.text('PATLADI!'), findsOneWidget);
      expect(find.text(exploded.name), findsOneWidget);
      expect(find.text('Bu oyunda 1. patlaması'), findsOneWidget);
      expect(find.text('SONRAKİ TUR'), findsOneWidget);
    });
  });

  group('taşma (320x568, 375x812, 1.3x yazı)', () {
    const scenarios = [
      (name: 'küçük', size: Size(320, 568), scale: 1.0),
      (name: 'standart', size: Size(375, 812), scale: 1.0),
      (name: 'küçük + büyük yazı', size: Size(320, 568), scale: 1.3),
    ];
    final tenPlayers = [
      for (var i = 0; i < 10; i++)
        Player(id: 'p$i', name: 'Oyuncu Adı Uzun $i'),
    ];

    for (final s in scenarios) {
      testWidgets('${s.name}: kurulum', (tester) async {
        final (c, _) = await createContainer({
          'player_history_v1': ['Zeynep', 'Emre', 'Deniz'],
        });
        final notifier = c.read(bombSetupProvider.notifier);
        for (final p in tenPlayers.take(9)) {
          notifier.addPlayer(p.name.substring(0, 14));
        }
        await pumpScreen(tester, c, const BombSetupScreen(),
            size: s.size, textScale: s.scale);
        expect(tester.takeException(), isNull);
      });

      testWidgets('${s.name}: hazır', (tester) async {
        final (c, _) = await createContainer();
        game(c).startGame(tenPlayers, const BombSettings());
        await pumpScreen(tester, c, const BombReadyScreen(),
            size: s.size, textScale: s.scale);
        expect(tester.takeException(), isNull);
      });

      testWidgets('${s.name}: bomba', (tester) async {
        final (c, _) = await createContainer();
        game(c)
          ..startGame(tenPlayers, const BombSettings(categoryId: 'harf'))
          ..startRound();
        await pumpScreen(tester, c, const BombPlayScreen(),
            size: s.size, textScale: s.scale);
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        game(c).quit();
      });

      testWidgets('${s.name}: patlama', (tester) async {
        final (c, clock) = await createContainer();
        game(c)
          ..startGame(tenPlayers, const BombSettings())
          ..startRound();
        clock.advance(beyondAnyFuse);
        await tester.pump(const Duration(milliseconds: 100));
        await pumpScreen(tester, c, const BombExplosionScreen(),
            size: s.size, textScale: s.scale);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('${s.name}: final', (tester) async {
        final (c, clock) = await createContainer();
        game(c).startGame(tenPlayers, const BombSettings(rounds: 5));
        for (var round = 0; round < 5; round++) {
          game(c).startRound();
          clock.advance(beyondAnyFuse);
          await tester.pump(const Duration(milliseconds: 100));
          game(c).nextRound();
        }
        expect(c.read(bombGameProvider)!.isFinished, isTrue);
        await pumpScreen(tester, c, const BombFinalScreen(),
            size: s.size, textScale: s.scale);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Oyun Bitti!'), findsOneWidget);
      });
    }
  });

  testWidgets('ana menüye dönülünce bomba oyunu ve fitil kapanır',
      (tester) async {
    final (c, _) = await createContainer();
    AppRouter.router.go(AppRouter.home);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: SessionGuard(
          router: AppRouter.router,
          child: MaterialApp.router(
            theme: AppTheme.dark,
            routerConfig: AppRouter.router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    game(c)
      ..startGame(players, const BombSettings())
      ..startRound();
    AppRouter.router.go(AppRouter.bombPlay);
    await tester.pump(const Duration(seconds: 1));
    expect(c.read(bombGameProvider), isNotNull);

    AppRouter.router.go(AppRouter.home);
    await tester.pumpAndSettle();
    expect(c.read(bombGameProvider), isNull);
  });
}
