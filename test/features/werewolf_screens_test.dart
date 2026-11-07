import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/core/services/haptic_service.dart';
import 'package:party_game/core/theme/app_theme.dart';
import 'package:party_game/core/utils/turkish_text.dart';
import 'package:party_game/core/widgets/app_hold_button.dart';
import 'package:party_game/data/repositories/local_storage_repository.dart';
import 'package:party_game/domain/models/player.dart';
import 'package:party_game/domain/models/werewolf/werewolf_game_state.dart';
import 'package:party_game/domain/models/werewolf/werewolf_player.dart';
import 'package:party_game/domain/models/werewolf/werewolf_role.dart';
import 'package:party_game/domain/models/werewolf/werewolf_settings.dart';
import 'package:party_game/domain/services/werewolf_engine.dart';
import 'package:party_game/features/werewolf/viewmodels/werewolf_day_timer_notifier.dart';
import 'package:party_game/features/werewolf/viewmodels/werewolf_game_notifier.dart';
import 'package:party_game/features/werewolf/viewmodels/werewolf_pass_flow_notifier.dart';
import 'package:party_game/features/werewolf/viewmodels/werewolf_reveal_notifier.dart';
import 'package:party_game/features/werewolf/viewmodels/werewolf_setup_notifier.dart';
import 'package:party_game/features/werewolf/views/werewolf_day_screen.dart';
import 'package:party_game/features/werewolf/views/werewolf_night_screen.dart';
import 'package:party_game/features/werewolf/views/werewolf_result_screen.dart';
import 'package:party_game/features/werewolf/views/werewolf_role_reveal_screen.dart';
import 'package:party_game/features/werewolf/views/werewolf_setup_screen.dart';
import 'package:party_game/features/werewolf/views/werewolf_voting_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Vampir Köylü ekranlarının "sıralı tek telefon" akışını ve küçük /
/// standart telefon boyutlarında taşma üretmediğini doğrular.
void main() {
  const engine = WerewolfEngine();
  const sizes = {
    'küçük telefon (320x568)': Size(320, 568),
    'standart telefon (375x812)': Size(375, 812),
    'küçük telefon + büyük yazı (1.3x)': Size(320, 568),
  };

  /// Oturma sırası ve rolleri bilinen, ilk gecesi başlamış 7 kişilik oyun.
  WerewolfGameState fixedNight() {
    const roles = {
      'Ali': WerewolfRole.vampir,
      'Ayşe': WerewolfRole.koylu,
      'Can': WerewolfRole.doktor,
      'Ece': WerewolfRole.kahin,
      'Mert': WerewolfRole.avci,
      'Su': WerewolfRole.cadi,
      'Umut': WerewolfRole.vampir,
    };
    final state = WerewolfGameState(
      id: 'test',
      settings: const WerewolfSettings(vampireCount: 2, includeHunter: true),
      players: [
        for (final entry in roles.entries)
          WerewolfPlayer(
            player: Player(id: entry.key, name: entry.key),
            role: entry.value,
          ),
      ],
      phase: WerewolfPhase.roleReveal,
    );
    return engine.startNight(state);
  }

  /// Gecenin tüm sıralarını motor üzerinden oynatır.
  void playWholeNight(
    ProviderContainer c, {
    String victim = 'Ayşe',
    String protect = 'Can',
  }) {
    final n = c.read(werewolfGameProvider.notifier);
    while (!c.read(werewolfGameProvider)!.isTurnSequenceComplete) {
      final p = c.read(werewolfGameProvider)!.currentTurnPlayer!;
      if (p.role == WerewolfRole.vampir) n.vampireVote(victim);
      if (p.role == WerewolfRole.doktor) n.doctorProtect(protect);
      n.completeNightTurn();
    }
    n.resolveNight();
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

  void setGame(ProviderContainer c, WerewolfGameState state) =>
      c.read(werewolfGameProvider.notifier).state = state;

  /// Kilitli onay butonunu basılı tutarak açar.
  Future<void> holdToUnlock(WidgetTester tester) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AppHoldButton)),
    );
    // İlk kare animasyonun başlangıç zamanını kaydeder; süre ondan sonra akar.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  test('Türkçe yönelme eki ünlü uyumuna uyar', () {
    expect('Ali'.withDativeSuffix(), "Ali'ye");
    expect('Can'.withDativeSuffix(), "Can'a");
    expect('Ayşe'.withDativeSuffix(), "Ayşe'ye");
    expect('Umut'.withDativeSuffix(), "Umut'a");
    expect('Su'.withDativeSuffix(), "Su'ya");
    expect('Ömer'.withDativeSuffix(), "Ömer'e");
  });

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

      testWidgets('kurulum ekranı taşmaz', (tester) async {
        await pump(
          tester,
          size,
          const WerewolfSetupScreen(),
          arrange: (c) {
            final n = c.read(werewolfSetupProvider.notifier);
            for (final name in ['Ali', 'Ayşe', 'Can', 'Ece', 'Mert', 'Su']) {
              n.addPlayer(name);
            }
          },
        );
        expect(tester.takeException(), isNull);
        expect(find.text('ROLLERİ DAĞIT'), findsOneWidget);
      });

      testWidgets('rol öğrenme: kilitli geçiş → basılı tut → sıradakine ver',
          (tester) async {
        final c = await pump(
          tester,
          size,
          const WerewolfRoleRevealScreen(),
          arrange: (c) => setGame(
            c,
            fixedNight().copyWith(phase: WerewolfPhase.roleReveal),
          ),
        );
        expect(find.text("Telefonu Ali'ye Ver"), findsOneWidget);
        expect(find.text('VAMPİR'), findsNothing);

        // Tek dokunuş kilidi açmaz.
        await tester.tap(find.byType(AppHoldButton));
        await tester.pumpAndSettle();
        expect(c.read(werewolfRevealProvider).isUnlocked, isFalse);

        await holdToUnlock(tester);
        expect(c.read(werewolfRevealProvider).isUnlocked, isTrue);
        expect(tester.takeException(), isNull);

        final card = await tester.startGesture(
          tester.getCenter(find.text('BASILI TUT')),
        );
        await tester.pumpAndSettle();
        expect(find.text('VAMPİR'), findsOneWidget);
        expect(find.textContaining('Diğer vampirler: Umut'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await card.up();
        await tester.pumpAndSettle();

        await tester.tap(find.textContaining("TELEFONU AYŞE'YE VER"));
        await tester.pumpAndSettle();
        expect(find.text("Telefonu Ayşe'ye Ver"), findsOneWidget);
        expect(c.read(werewolfRevealProvider).isUnlocked, isFalse);
      });

      testWidgets('gece: telefon herkese sırayla geçer, ekran kilitlenir',
          (tester) async {
        final c = await pump(
          tester,
          size,
          const WerewolfNightScreen(),
          arrange: (c) => setGame(c, fixedNight()),
        );
        expect(find.text('GECE BAŞLASIN'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('GECE BAŞLASIN'));
        await tester.pumpAndSettle();
        expect(find.text("Telefonu Ali'ye Ver"), findsOneWidget);

        // Ali (vampir): kilidi aç → av seç.
        await holdToUnlock(tester);
        expect(find.text('Bu gece kimi avlıyorsun?'), findsOneWidget);
        expect(tester.takeException(), isNull);
        c.read(werewolfGameProvider.notifier)
          ..vampireVote('Ayşe')
          ..completeNightTurn();
        await tester.pumpAndSettle();

        // Sıra Ayşe'de ve ekran yeniden kilitli.
        expect(find.text("Telefonu Ayşe'ye Ver"), findsOneWidget);
        expect(find.textContaining('avlıyorsun'), findsNothing);

        // Ayşe (köylü): "Aksiyonun Yok".
        await holdToUnlock(tester);
        expect(find.text('Aksiyonun Yok'), findsOneWidget);
        expect(find.textContaining("TELEFONU CAN'A VER"), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.textContaining("TELEFONU CAN'A VER"));
        await tester.pumpAndSettle();

        // Can (doktor).
        await holdToUnlock(tester);
        expect(find.text('Bu gece kimi koruyorsun?'), findsOneWidget);
        expect(tester.takeException(), isNull);
        c.read(werewolfGameProvider.notifier)
          ..doctorProtect('Can')
          ..completeNightTurn();
        await tester.pumpAndSettle();

        // Ece (kâhin): tek sorgu → sonuç görünür.
        await holdToUnlock(tester);
        expect(find.text('Kimin rolünü sorgulayacaksın?'), findsOneWidget);
        c.read(werewolfGameProvider.notifier).seerInspect('Umut');
        await tester.pumpAndSettle();
        expect(find.text('Kehanet gerçekleşti'), findsOneWidget);
        expect(find.text('bir VAMPİR'), findsOneWidget);
        expect(tester.takeException(), isNull);
        c.read(werewolfGameProvider.notifier).completeNightTurn();
        await tester.pumpAndSettle();

        // Mert (avcı): kurşun hazır, hamle yok.
        await holdToUnlock(tester);
        expect(find.text('Kurşunun Hazır'), findsOneWidget);
        c.read(werewolfGameProvider.notifier).completeNightTurn();
        await tester.pumpAndSettle();

        // Su (cadı): iksir paneli.
        await holdToUnlock(tester);
        expect(find.text('İksirlerini kullanacak mısın?'), findsOneWidget);
        expect(find.textContaining('şu anki hedefi: Ayşe'), findsOneWidget);
        expect(tester.takeException(), isNull);
        c.read(werewolfGameProvider.notifier)
          ..witchAct()
          ..completeNightTurn();
        await tester.pumpAndSettle();

        // Umut (vampir, son kişi) → gece biter.
        await holdToUnlock(tester);
        expect(find.textContaining('Seçimleri: Ali → Ayşe'), findsOneWidget);
        c.read(werewolfGameProvider.notifier)
          ..vampireVote('Ayşe')
          ..completeNightTurn();
        await tester.pumpAndSettle();
        expect(find.text('SABAHI GETİR'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('gündüz: avcı elenince karar paneli açılır', (tester) async {
        final c = await pump(
          tester,
          size,
          const WerewolfDayScreen(),
          arrange: (c) {
            setGame(c, fixedNight());
            playWholeNight(c, victim: 'Mert');
          },
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Güneş Doğdu'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('EVET, ATEŞ ET'), 200);
        expect(find.text('Avcı Elendi!'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text('HAYIR, KURŞUNU KULLANMA'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('HAYIR, KURŞUNU KULLANMA'));
        await tester.pumpAndSettle();
        expect(c.read(werewolfGameProvider)!.pendingHunterId, isNull);
        expect(tester.takeException(), isNull);
      });

      testWidgets('gündüz: tartışma sayacı başlar ve taşmaz', (tester) async {
        final c = await pump(
          tester,
          size,
          const WerewolfDayScreen(),
          arrange: (c) {
            setGame(c, fixedNight());
            playWholeNight(c);
          },
        );
        await tester.scrollUntilVisible(find.text('TARTIŞMAYI BAŞLAT'), 200);
        await tester.ensureVisible(find.text('TARTIŞMAYI BAŞLAT'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('TARTIŞMAYI BAŞLAT'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(c.read(werewolfDayTimerProvider).isRunning, isTrue);
        expect(tester.takeException(), isNull);
        c.read(werewolfGameProvider.notifier).quit();
        await tester.pump();
      });

      testWidgets('oylama: herkes gizlice oy verir, sonuç birlikte açılır',
          (tester) async {
        final c = await pump(
          tester,
          size,
          const WerewolfVotingScreen(),
          arrange: (c) {
            setGame(c, fixedNight());
            playWholeNight(c);
            c.read(werewolfGameProvider.notifier).startVoting();
          },
        );
        expect(find.text('Bireysel Gizli Oylama'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('OYLAMAYI BAŞLAT'));
        await tester.pumpAndSettle();
        expect(find.text("Telefonu Ali'ye Ver"), findsOneWidget);

        await holdToUnlock(tester);
        expect(find.text('Ali, kimi sürgün etmek istiyorsun?'), findsOneWidget);
        // Kendisi listede yok.
        expect(find.text('Ali'), findsNothing);
        expect(tester.takeException(), isNull);

        // Herkes oyunu verir: Umut en çok oyu alır.
        final n = c.read(werewolfGameProvider.notifier);
        while (!c.read(werewolfGameProvider)!.voteResolved) {
          final voter = c.read(werewolfGameProvider)!.currentTurnPlayer!;
          n.castVote(voter.id == 'Umut' ? 'Can' : 'Umut');
        }
        await tester.pumpAndSettle();
        expect(find.text('Tüm Oylar Kullanıldı'), findsOneWidget);

        await tester.tap(find.text('SONUCU AÇIKLA'));
        await tester.pumpAndSettle();
        expect(find.text('Köy Kararını Verdi'), findsOneWidget);
        expect(c.read(werewolfGameProvider)!.lastExiledId, 'Umut');
        expect(tester.takeException(), isNull);
      });

      testWidgets('sonuç ekranı taşmaz ve herkesin rolünü gösterir',
          (tester) async {
        await pump(
          tester,
          size,
          const WerewolfResultScreen(),
          arrange: (c) {
            setGame(c, fixedNight());
            playWholeNight(c);
            final n = c.read(werewolfGameProvider.notifier)..startVoting();
            // İki tur oylamayla iki vampir de sürülür.
            while (!c.read(werewolfGameProvider)!.voteResolved) {
              final v = c.read(werewolfGameProvider)!.currentTurnPlayer!;
              n.castVote(v.id == 'Umut' ? 'Can' : 'Umut');
            }
            n.startNight();
            playWholeNight(c, victim: 'Can', protect: 'Ece');
            n.startVoting();
            while (!c.read(werewolfGameProvider)!.voteResolved) {
              final v = c.read(werewolfGameProvider)!.currentTurnPlayer!;
              n.castVote(v.id == 'Ali' ? 'Ece' : 'Ali');
            }
          },
        );
        expect(tester.takeException(), isNull);
        expect(find.textContaining('KAZANDI!'), findsOneWidget);
        expect(find.textContaining('KÖYLÜLER'), findsOneWidget);
      });
    });
  }

  test('kurulum: otomatik dağılım oyuncu sayısına göre güncellenir', () async {
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
    final n = c.read(werewolfSetupProvider.notifier);
    for (final name in ['A', 'B', 'C', 'D', 'E', 'F']) {
      n.addPlayer(name);
    }

    var state = c.read(werewolfSetupProvider);
    expect(state.settings.vampireCount, 2);
    expect(state.canStart, isTrue);

    n.changeVampireCount(-1);
    state = c.read(werewolfSetupProvider);
    expect(state.autoBalance, isFalse);
    expect(state.settings.vampireCount, 1);

    n.setAutoBalance(true);
    expect(c.read(werewolfSetupProvider).settings.vampireCount, 2);
  });

  test('geçiş akışı telefon el değiştirince kendiliğinden kilitlenir', () {
    final c = ProviderContainer(
      overrides: [
        hapticServiceProvider.overrideWithValue(
          const HapticService(enabled: false),
        ),
      ],
    );
    addTearDown(c.dispose);
    c.read(werewolfGameProvider.notifier).state = fixedNight();
    c
        .read(werewolfPassFlowProvider.notifier)
        .unlock(c.read(werewolfGameProvider)!);
    expect(c.read(werewolfPassFlowProvider).isUnlocked(0), isTrue);

    c.read(werewolfGameProvider.notifier)
      ..vampireVote('Ayşe')
      ..completeNightTurn();
    expect(c.read(werewolfPassFlowProvider).isUnlocked(1), isFalse);
  });
}
