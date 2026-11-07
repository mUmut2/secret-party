import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/core/services/haptic_service.dart';
import 'package:party_game/core/theme/app_theme.dart';
import 'package:party_game/core/widgets/app_hold_button.dart';
import 'package:party_game/data/repositories/local_storage_repository.dart';
import 'package:party_game/data/repositories/word_repository.dart';
import 'package:party_game/domain/models/game_session.dart';
import 'package:party_game/domain/models/player.dart';
import 'package:party_game/domain/services/game_engine_notifier.dart';
import 'package:party_game/features/game_selection/views/game_selection_screen.dart';
import 'package:party_game/features/help/how_to_play.dart';
import 'package:party_game/features/home/views/home_screen.dart';
import 'package:party_game/features/imposter/viewmodels/role_reveal_notifier.dart';
import 'package:party_game/features/imposter/viewmodels/round_notifier.dart';
import 'package:party_game/features/imposter/viewmodels/voting_notifier.dart';
import 'package:party_game/features/imposter/views/role_reveal_screen.dart';
import 'package:party_game/features/imposter/views/round_screen.dart';
import 'package:party_game/features/imposter/views/voting_screen.dart';
import 'package:party_game/features/players/viewmodels/player_setup_notifier.dart';
import 'package:party_game/features/players/views/player_setup_screen.dart';
import 'package:party_game/features/results/views/result_screen.dart';
import 'package:party_game/features/settings/viewmodels/game_settings_notifier.dart';
import 'package:party_game/features/settings/views/privacy_policy_screen.dart';
import 'package:party_game/features/settings/utils/settings_labels.dart';
import 'package:party_game/features/settings/widgets/game_settings_sheet.dart';
import 'package:party_game/features/settings/views/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ana menü, ayarlar ve Imposter ekranlarının küçük telefonda, standart
/// telefonda ve büyük sistem yazı boyutunda taşma üretmediğini doğrular.
void main() {
  const scenarios = [
    (name: 'küçük telefon', size: Size(320, 568), textScale: 1.0),
    (name: 'standart telefon', size: Size(375, 812), textScale: 1.0),
    (name: 'küçük telefon + büyük yazı', size: Size(320, 568), textScale: 1.3),
  ];

  final players = [
    for (final name in ['Ali', 'Ayşe', 'Can', 'Ece', 'Mert'])
      Player(id: name, name: name),
  ];

  Future<ProviderContainer> pump(
    WidgetTester tester,
    ({String name, Size size, double textScale}) scenario,
    Widget screen, {
    void Function(ProviderContainer container)? arrange,
  }) async {
    tester.view.physicalSize = scenario.size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scenario.textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    SharedPreferences.setMockInitialValues({
      'player_history_v1': ['Zeynep', 'Emre', 'Deniz'],
    });
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        hapticServiceProvider.overrideWithValue(
          const HapticService(enabled: false),
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

  /// Havuzdaki en uzun ipucu (rol kartı için en kötü durum).
  final repository = LocalWordRepository();
  final longestHint = [
    for (final id in repository.categoryIds) ...repository.entriesIn(id),
  ].map((e) => e.hint).reduce((a, b) => a.length >= b.length ? a : b);

  void startImposter(ProviderContainer c) =>
      c.read(gameSessionProvider.notifier).startGame(players);

  for (final scenario in scenarios) {
    group(scenario.name, () {
      testWidgets('ana ekran', (tester) async {
        await pump(tester, scenario, const HomeScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('oyun seçimi', (tester) async {
        await pump(tester, scenario, const GameSelectionScreen());
        expect(tester.takeException(), isNull);
        expect(find.text('Imposter'), findsOneWidget);
      });

      testWidgets('ayarlar', (tester) async {
        await pump(tester, scenario, const SettingsScreen());
        expect(tester.takeException(), isNull);
        expect(find.text('Titreşim'), findsOneWidget);
      });

      testWidgets('gizlilik politikası', (tester) async {
        await pump(tester, scenario, const PrivacyPolicyScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('nasıl oynanır rehberi (4 oyun)', (tester) async {
        await pump(tester, scenario, const SettingsScreen());
        for (final guide in GameGuide.values) {
          final context = tester.element(find.byType(SettingsScreen));
          showHowToPlaySheet(context, guide);
          await tester.pumpAndSettle();
          expect(find.text('${guide.title} · Nasıl Oynanır?'), findsOneWidget);
          expect(tester.takeException(), isNull);
          Navigator.of(context).pop();
          await tester.pumpAndSettle();
        }
      });

      testWidgets('imposter oyuncu kurulumu (geçmiş + 5 oyuncu)',
          (tester) async {
        await pump(
          tester,
          scenario,
          const PlayerSetupScreen(),
          arrange: (c) {
            final n = c.read(playerSetupProvider.notifier);
            for (final p in players) {
              n.addPlayer(p.name);
            }
          },
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Nasıl Oynanır?'), findsOneWidget);
      });

      testWidgets('imposter rol gösterme: kilitli geçiş ve rol',
          (tester) async {
        final c = await pump(
          tester,
          scenario,
          const RoleRevealScreen(),
          arrange: startImposter,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(AppHoldButton), findsOneWidget);

        c.read(roleRevealProvider.notifier).revealCurrentPlayer();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('ANLADIM, GİZLE'), findsOneWidget);
      });

      for (final imposterId in ['Ali', 'Ayşe']) {
        testWidgets(
            'imposter rol kartı (${imposterId == 'Ali' ? 'Imposter + en uzun ipucu' : 'en uzun kelime'})',
            (tester) async {
          final c = await pump(
            tester,
            scenario,
            const RoleRevealScreen(),
            arrange: (c) =>
                c.read(gameSessionProvider.notifier).state = GameSession(
              id: 'test_$imposterId',
              players: players,
              secretWord: 'Mercimek Çorbası',
              imposterId: imposterId,
              category: 'yemekler',
              status: GameState.roleReveal,
              roundDurationSeconds: 180,
              // En kötü durum: havuzdaki en uzun ipucu.
              giveImposterHint: true,
              imposterHint: longestHint,
            ),
          );
          c.read(roleRevealProvider.notifier).revealCurrentPlayer();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (imposterId == 'Ali') {
            expect(find.text('İPUCUN'), findsOneWidget);
          }
        });
      }

      testWidgets('imposter ayar penceresi ve "İpuçlu" özet kartı',
          (tester) async {
        final c = await pump(
          tester,
          scenario,
          const PlayerSetupScreen(),
          arrange: (c) =>
              c.read(gameSettingsProvider.notifier).setGiveImposterHint(true),
        );
        expect(find.textContaining('İpuçlu'), findsOneWidget);
        expect(tester.takeException(), isNull);

        showGameSettingsSheet(tester.element(find.byType(PlayerSetupScreen)));
        await tester.pumpAndSettle();
        expect(find.text("Imposter'a ipucu ver"), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Anahtarı kapat: özet kartından "İpuçlu" kalkar.
        await tester.ensureVisible(find.byType(Switch).last);
        await tester.tap(find.byType(Switch).last);
        await tester.pumpAndSettle();
        expect(c.read(gameSettingsProvider).giveImposterHint, isFalse);
        expect(tester.takeException(), isNull);
      });

      testWidgets('ayar penceresinde tüm kategoriler erişilebilir',
          (tester) async {
        final c = await pump(tester, scenario, const PlayerSetupScreen());
        showGameSettingsSheet(tester.element(find.byType(PlayerSetupScreen)));
        await tester.pumpAndSettle();

        final ids = c.read(wordRepositoryProvider).categoryIds;
        final last = categoryLabel(ids.last);
        await tester.ensureVisible(find.text(last));
        await tester.pumpAndSettle();
        await tester.tap(find.text(last));
        await tester.pumpAndSettle();
        expect(c.read(gameSettingsProvider).selectedCategoryId, ids.last);
        expect(tester.takeException(), isNull);
      });

      testWidgets('imposter herkes rolünü gördü', (tester) async {
        await pump(
          tester,
          scenario,
          const RoleRevealScreen(),
          arrange: (c) {
            startImposter(c);
            final n = c.read(roleRevealProvider.notifier);
            for (var i = 0; i < players.length; i++) {
              n
                ..revealCurrentPlayer()
                ..hideAndAdvance(totalPlayers: players.length);
            }
          },
        );
        expect(tester.takeException(), isNull);
        expect(find.text('TURA BAŞLA'), findsOneWidget);
      });

      testWidgets('imposter tur: son saniyeler ve tur bitti', (tester) async {
        final c = await pump(
          tester,
          scenario,
          const RoundScreen(),
          arrange: (c) {
            startImposter(c);
            c.read(gameSessionProvider.notifier).beginRound();
            c.read(roundProvider.notifier).start(durationSeconds: 8);
          },
        );
        expect(tester.takeException(), isNull);
        expect(find.text('SON 10 SANİYE!'), findsOneWidget);

        c.read(roundProvider.notifier).endEarly();
        await tester.pumpAndSettle();
        expect(find.text('TUR BİTTİ!'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('imposter oylama ve sonuç', (tester) async {
        final c = await pump(
          tester,
          scenario,
          const VotingScreen(),
          arrange: (c) {
            startImposter(c);
            c.read(gameSessionProvider.notifier)
              ..beginRound()
              ..beginVoting();
          },
        );
        expect(tester.takeException(), isNull);
        c.read(votingProvider.notifier).selectPlayer('Ali');
        await tester.pumpAndSettle();
        expect(find.text('Seçildi'), findsOneWidget);
        expect(tester.takeException(), isNull);

        c.read(votingProvider.notifier).confirmVote();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: MaterialApp(
              theme: AppTheme.dark,
              home: const ResultScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('YENİDEN OYNA'), findsOneWidget);
      });
    });
  }
}
