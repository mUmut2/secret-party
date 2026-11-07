import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/core/services/haptic_service.dart';
import 'package:party_game/core/theme/app_theme.dart';
import 'package:party_game/core/widgets/app_hold_button.dart';
import 'package:party_game/data/repositories/local_storage_repository.dart';
import 'package:party_game/data/repositories/spy_location_repository.dart';
import 'package:party_game/domain/models/player.dart';
import 'package:party_game/domain/models/spy/spy_game_state.dart';
import 'package:party_game/domain/models/spy/spy_player.dart';
import 'package:party_game/domain/models/spy/spy_settings.dart';
import 'package:party_game/features/spy/viewmodels/spy_flow_notifiers.dart';
import 'package:party_game/features/spy/viewmodels/spy_game_notifier.dart';
import 'package:party_game/features/spy/viewmodels/spy_setup_notifier.dart';
import 'package:party_game/features/spy/viewmodels/spy_timer_notifier.dart';
import 'package:party_game/features/spy/views/spy_game_screen.dart';
import 'package:party_game/features/spy/views/spy_location_guess_screen.dart';
import 'package:party_game/features/spy/views/spy_result_screen.dart';
import 'package:party_game/features/spy/views/spy_role_reveal_screen.dart';
import 'package:party_game/features/spy/views/spy_setup_screen.dart';
import 'package:party_game/features/spy/views/spy_voting_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ajan ekranlarının "sıralı tek telefon" akışını ve küçük / standart
/// telefon boyutlarında taşma üretmediğini doğrular.
void main() {
  const sizes = {
    'küçük telefon (320x568)': Size(320, 568),
    'standart telefon (375x812)': Size(375, 812),
    'küçük telefon + büyük yazı (1.3x)': Size(320, 568),
  };

  /// Konumu ve ajanı bilinen oyun: Can ajan, konum Korsan Gemisi.
  SpyGameState fixedGame() {
    final locations = const LocalSpyLocationRepository().locations;
    final ship = locations.firstWhere((l) => l.name == 'Korsan Gemisi');
    const roles = ['Kaptan', 'Tayfa', null, 'Aşçı', 'Tutsak'];
    const names = ['Ali', 'Ayşe', 'Can', 'Ece', 'Umut'];
    return SpyGameState(
      id: 'test',
      settings: const SpySettings(),
      players: [
        for (var i = 0; i < names.length; i++)
          SpyPlayer(
            player: Player(id: names[i], name: names[i]),
            isSpy: roles[i] == null,
            roleName: roles[i],
          ),
      ],
      location: ship,
      allLocations: locations,
      firstAskerId: 'Ece',
      phase: SpyPhase.roleReveal,
    );
  }

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Size size,
    Widget screen, {
    void Function(ProviderContainer container)? arrange,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'player_history_v1': ['Zeynep', 'Emre'],
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

  void setGame(ProviderContainer c, SpyGameState state) =>
      c.read(spyGameProvider.notifier).state = state;

  Future<void> holdToUnlock(WidgetTester tester) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppHoldButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// Herkes Can'a oy verir (Can de Ali'ye).
  void everyoneAccusesCan(ProviderContainer c) {
    final n = c.read(spyGameProvider.notifier)
      ..startRound()
      ..startVoting();
    while (!c.read(spyGameProvider)!.isVoteComplete) {
      final voter = c.read(spyGameProvider)!.currentVoter!;
      n.castVote(voter.id == 'Can' ? 'Ali' : 'Can');
    }
  }

  for (final entry in sizes.entries) {
    final size = entry.value;

    group(entry.key, () {
      // Sistem yazı boyutu büyütülmüş küçük telefon (erişilebilirlik).
      if (entry.key.contains('büyük yazı')) {
        setUp(() => TestWidgetsFlutterBinding
            .instance.platformDispatcher.textScaleFactorTestValue = 1.3);
        tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher
            .clearTextScaleFactorTestValue());
      }

      testWidgets('kurulum ekranı ve konum rehberi taşmaz', (tester) async {
        await pump(
          tester,
          size,
          const SpySetupScreen(),
          arrange: (c) {
            final n = c.read(spySetupProvider.notifier);
            for (final name in ['Ali', 'Ayşe', 'Can', 'Ece', 'Mert', 'Su']) {
              n.addPlayer(name);
            }
            n.setSpyCount(2);
          },
        );
        expect(tester.takeException(), isNull);
        expect(find.text('ROLLERİ DAĞIT'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.textContaining('MUHTEMEL KONUMLAR'),
          200,
          // Sayfada yatay "Geçmişten Seç" şeridi de var; ana listeyi kaydır.
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.textContaining('MUHTEMEL KONUMLAR'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('MUHTEMEL KONUMLAR'));
        await tester.pumpAndSettle();
        expect(find.text('Muhtemel Konumlar'), findsOneWidget);
        expect(find.text('Korsan Gemisi'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('rol öğrenme: masum ve ajan kartları, kilitli geçiş',
          (tester) async {
        final c = await pump(
          tester,
          size,
          const SpyRoleRevealScreen(),
          arrange: (c) => setGame(c, fixedGame()),
        );
        expect(find.text("Telefonu Ali'ye Ver"), findsOneWidget);
        expect(find.text('KORSAN GEMİSİ'), findsNothing);

        await holdToUnlock(tester);
        expect(find.text('KORSAN GEMİSİ'), findsOneWidget);
        expect(find.text('Kaptan'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.textContaining("TELEFONU AYŞE'YE VER"));
        await tester.pumpAndSettle();
        expect(find.text("Telefonu Ayşe'ye Ver"), findsOneWidget);
        expect(find.text('KORSAN GEMİSİ'), findsNothing);

        // Ayşe'yi geç, Can (ajan) kartını aç.
        await holdToUnlock(tester);
        await tester.tap(find.textContaining("TELEFONU CAN'A VER"));
        await tester.pumpAndSettle();
        await holdToUnlock(tester);
        expect(find.text('SEN AJANSIN!'), findsOneWidget);
        expect(find.text('KORSAN GEMİSİ'), findsNothing);
        expect(tester.takeException(), isNull);
        expect(c.read(spyRevealProvider).currentIndex, 2);
      });

      testWidgets('oyun ekranı: sayaç, ilk soru kartı ve kilitli ajan onayı',
          (tester) async {
        final c = await pump(
          tester,
          size,
          const SpyGameScreen(),
          arrange: (c) {
            setGame(c, fixedGame());
            c.read(spyGameProvider.notifier).startRound();
            c.read(spyTimerProvider.notifier).start(480);
          },
        );
        expect(tester.takeException(), isNull);
        expect(find.text('08:00'), findsOneWidget);
        expect(find.text('İlk Soruyu Ece Soruyor!'), findsOneWidget);
        expect(find.text('AJANIM, KONUMU TAHMİN EDECEĞİM!'), findsOneWidget);
        expect(find.text('AJANI OYLA'), findsOneWidget);

        await tester.tap(find.text('AJANIM, KONUMU TAHMİN EDECEĞİM!'));
        await tester.pumpAndSettle();
        expect(find.text('Ajan mısın?'), findsOneWidget);
        expect(find.byType(AppHoldButton), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('VAZGEÇ'));
        await tester.pumpAndSettle();
        expect(c.read(spyGameProvider)!.phase, SpyPhase.inProgress);
        c.read(spyTimerProvider.notifier).stop();
      });

      testWidgets('tahmin ekranı: konum grid ve kilitli onay', (tester) async {
        final c = await pump(
          tester,
          size,
          const SpyLocationGuessScreen(),
          arrange: (c) {
            setGame(c, fixedGame());
            c.read(spyGameProvider.notifier)
              ..startRound()
              ..startSpyGuess();
          },
        );
        expect(find.text('Konumu Tahmin Et'), findsOneWidget);
        expect(find.text('BİR KONUM SEÇ'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Korsan Gemisi'));
        await tester.pumpAndSettle();
        expect(find.byType(AppHoldButton), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(c.read(spyGameProvider)!.phase, SpyPhase.spyGuessing);
      });

      testWidgets('oylama: gizli oylar, ajan yakalanır, son şans',
          (tester) async {
        final c = await pump(
          tester,
          size,
          const SpyVotingScreen(),
          arrange: (c) {
            setGame(c, fixedGame());
            c.read(spyGameProvider.notifier)
              ..startRound()
              ..startVoting();
          },
        );
        expect(find.text('Ajan Kim?'), findsOneWidget);
        await tester.tap(find.text('OYLAMAYI BAŞLAT'));
        await tester.pumpAndSettle();
        expect(find.text("Telefonu Ali'ye Ver"), findsOneWidget);

        await holdToUnlock(tester);
        expect(find.text('Ali, sence ajan kim?'), findsOneWidget);
        expect(find.text('Ali'), findsNothing);
        expect(tester.takeException(), isNull);

        final n = c.read(spyGameProvider.notifier);
        while (!c.read(spyGameProvider)!.isVoteComplete) {
          final voter = c.read(spyGameProvider)!.currentVoter!;
          n.castVote(voter.id == 'Can' ? 'Ali' : 'Can');
        }
        await tester.pumpAndSettle();
        expect(find.text('Tüm Oylar Kullanıldı'), findsOneWidget);

        await tester.tap(find.text('SONUCU AÇIKLA'));
        await tester.pumpAndSettle();
        expect(find.text('AJAN YAKALANDI!'), findsOneWidget);
        expect(find.text('AJANIN SON TAHMİNİ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('son şans ekranı yakalanan ajanı gösterir', (tester) async {
        await pump(
          tester,
          size,
          const SpyLocationGuessScreen(),
          arrange: (c) {
            setGame(c, fixedGame());
            everyoneAccusesCan(c);
          },
        );
        expect(find.text('Yakalandın! Son Şansın'), findsOneWidget);
        expect(find.textContaining('Can, köy seni buldu'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('sonuç ekranı: masumlar kazandı, roller açık',
          (tester) async {
        await pump(
          tester,
          size,
          const SpyResultScreen(),
          arrange: (c) {
            setGame(c, fixedGame());
            everyoneAccusesCan(c);
            c.read(spyGameProvider.notifier).guessLocation('Uçak');
          },
        );
        expect(tester.takeException(), isNull);
        expect(find.text('MASUMLAR\nKAZANDI!'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Ajanın tahmini: Uçak'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('KORSAN GEMİSİ'), findsOneWidget);
        expect(find.text('Ajanın tahmini: Uçak'), findsOneWidget);
      });
    });
  }

  test('iki ajan seçeneği oyuncu azalınca kendiliğinden 1\'e iner', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        hapticServiceProvider.overrideWithValue(
          const HapticService(enabled: false),
        ),
      ],
    );
    addTearDown(c.dispose);
    final n = c.read(spySetupProvider.notifier);
    for (final name in ['A', 'B', 'C', 'D', 'E']) {
      n.addPlayer(name);
    }
    n.setSpyCount(2);
    expect(c.read(spySetupProvider).settings.spyCount, 1);

    n
      ..addPlayer('F')
      ..setSpyCount(2);
    expect(c.read(spySetupProvider).settings.spyCount, 2);

    n.removePlayer(c.read(spySetupProvider).players.last.id);
    expect(c.read(spySetupProvider).settings.spyCount, 1);
  });
}
