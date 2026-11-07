import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/domain/models/player.dart';
import 'package:party_game/domain/models/werewolf/werewolf_game_state.dart';
import 'package:party_game/domain/models/werewolf/werewolf_player.dart';
import 'package:party_game/domain/models/werewolf/werewolf_role.dart';
import 'package:party_game/domain/models/werewolf/werewolf_settings.dart';
import 'package:party_game/domain/services/werewolf_engine.dart';

void main() {
  const engine = WerewolfEngine();
  final random = Random(1);

  /// Rolleri elle verilmiş, ilk gecesi başlamış oyun. Oturma sırası
  /// map'teki sıradır; isimler rolü belli edecek şekilde seçildi.
  WerewolfGameState gameWith(
    Map<String, WerewolfRole> roles, {
    WerewolfTieBreak tieBreak = WerewolfTieBreak.noElimination,
  }) {
    final state = WerewolfGameState(
      id: 'test',
      settings: WerewolfSettings(vampireCount: 1, tieBreak: tieBreak),
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

  /// Telefonu herkesten geçirir; her oyuncu için [actions] içindeki hamleyi
  /// (varsa) yapar, sonra sırasını bitirir.
  WerewolfGameState playNight(
    WerewolfGameState state,
    Map<String, WerewolfGameState Function(WerewolfGameState)> actions,
  ) {
    var s = state;
    while (!s.isTurnSequenceComplete) {
      final id = s.currentTurnPlayer!.id;
      final action = actions[id];
      if (action != null) s = action(s);
      s = engine.completeNightTurn(s);
    }
    return engine.resolveNight(s, random);
  }

  /// Yaşayan herkes sırayla oy verir. [ballot]: seçmen → hedef.
  WerewolfGameState playVote(
    WerewolfGameState state,
    Map<String, String> ballot,
  ) {
    var s = engine.startVoting(state);
    while (!s.voteResolved) {
      final voter = s.currentTurnPlayer!.id;
      s = engine.castVote(s, voter, ballot[voter]!, random);
    }
    return s;
  }

  const village = {
    'vampir1': WerewolfRole.vampir,
    'vampir2': WerewolfRole.vampir,
    'doktor': WerewolfRole.doktor,
    'cadi': WerewolfRole.cadi,
    'kahin': WerewolfRole.kahin,
    'koylu1': WerewolfRole.koylu,
    'koylu2': WerewolfRole.koylu,
  };

  group('rol dağılımı', () {
    test('önerilen dağılım her oyuncu sayısında geçerli', () {
      for (var n = WerewolfSettings.minPlayers;
          n <= WerewolfSettings.maxPlayers;
          n++) {
        final settings = WerewolfSettings.recommended(n);
        expect(settings.validate(n), isNull, reason: '$n oyuncu');
        expect(settings.roleDeck(n), hasLength(n));
      }
    });

    test('6 oyuncu: 2 vampir, doktor, kâhin, 2 köylü', () {
      final deck = WerewolfSettings.recommended(6).roleDeck(6);
      expect(deck.where((r) => r == WerewolfRole.vampir), hasLength(2));
      expect(deck, contains(WerewolfRole.doktor));
      expect(deck, contains(WerewolfRole.kahin));
      expect(deck.where((r) => r == WerewolfRole.koylu), hasLength(2));
    });
  });

  group('sıralı tek telefon gecesi', () {
    test('telefon yaşayan HER oyuncunun eline oturma sırasıyla geçer', () {
      final state = gameWith(village);
      expect(state.turnOrder, village.keys.toList());
      expect(state.currentTurnPlayer!.id, 'vampir1');
      expect(state.nextTurnPlayer!.id, 'vampir2');
    });

    test('ölüler gece sırasına girmez', () {
      var state = playNight(gameWith(village), {
        'vampir1': (s) => engine.vampireVote(s, 'vampir1', 'koylu1'),
        'vampir2': (s) => engine.vampireVote(s, 'vampir2', 'koylu1'),
        'doktor': (s) => engine.doctorProtect(s, 'doktor', 'doktor'),
      });
      state = playVote(state, {
        for (final p in state.alivePlayers) p.id: 'koylu2',
        'koylu2': 'vampir1',
      });
      state = engine.startNight(state);
      expect(state.turnOrder, isNot(contains('koylu1')));
      expect(state.turnOrder, isNot(contains('koylu2')));
    });

    test('köylünün aksiyonu yoktur; zorunlu hamle yapılmadan sıra geçmez', () {
      final state = gameWith(village);
      expect(
        engine.nightAbilityOf(state, state.playerById('koylu1')),
        WerewolfNightAbility.none,
      );
      expect(() => engine.completeNightTurn(state), throwsStateError);
    });

    test('sırası olmayan oyuncu hamle yapamaz', () {
      final state = gameWith(village);
      expect(
        () => engine.doctorProtect(state, 'doktor', 'koylu1'),
        throwsStateError,
      );
    });

    test('vampirlerin en çok seçtiği kişi ölür', () {
      final state = playNight(gameWith(village), {
        'vampir1': (s) => engine.vampireVote(s, 'vampir1', 'koylu1'),
        'vampir2': (s) => engine.vampireVote(s, 'vampir2', 'koylu1'),
        'doktor': (s) => engine.doctorProtect(s, 'doktor', 'koylu2'),
      });
      expect(state.lastNightDeaths, ['koylu1']);
      expect(state.deathOf('koylu1')?.cause, WerewolfDeathCause.vampires);
    });

    test('doktor korursa kimse ölmez', () {
      final state = playNight(gameWith(village), {
        'vampir1': (s) => engine.vampireVote(s, 'vampir1', 'koylu1'),
        'vampir2': (s) => engine.vampireVote(s, 'vampir2', 'koylu1'),
        'doktor': (s) => engine.doctorProtect(s, 'doktor', 'koylu1'),
      });
      expect(state.lastNightDeaths, isEmpty);
      expect(state.someoneSavedLastNight, isTrue);
    });

    test('cadı iyileştirir ve zehirler; iksirler tükenir', () {
      final state = playNight(gameWith(village), {
        'vampir1': (s) => engine.vampireVote(s, 'vampir1', 'koylu1'),
        'vampir2': (s) => engine.vampireVote(s, 'vampir2', 'koylu1'),
        'doktor': (s) => engine.doctorProtect(s, 'doktor', 'vampir1'),
        'cadi': (s) => engine.witchAct(
              s,
              'cadi',
              healTargetId: 'koylu1',
              poisonTargetId: 'vampir1',
            ),
      });
      expect(state.playerById('koylu1').isAlive, isTrue);
      // Zehir doktor korumasını deler.
      expect(state.playerById('vampir1').isAlive, isFalse);
      expect(state.witchHealAvailable, isFalse);
      expect(state.witchPoisonAvailable, isFalse);
    });

    test('kâhin oyun boyunca yalnızca BİR kez sorgulayabilir', () {
      var state = gameWith(village);
      // kâhinin sırasına kadar ilerle
      state = engine.completeNightTurn(
        engine.vampireVote(state, 'vampir1', 'koylu1'),
      );
      state = engine.completeNightTurn(
        engine.vampireVote(state, 'vampir2', 'koylu1'),
      );
      state = engine.completeNightTurn(
        engine.doctorProtect(state, 'doktor', 'koylu2'),
      );
      state = engine.completeNightTurn(state); // cadı pas geçer
      expect(state.currentTurnPlayer!.id, 'kahin');

      state = engine.seerInspect(state, 'kahin', 'vampir2');
      expect(state.seerAvailable, isFalse);
      expect(
        state.playerById(state.nightActions.seerInspectedId!).role,
        WerewolfRole.vampir,
      );
      expect(
        () => engine.seerInspect(state, 'kahin', 'koylu2'),
        throwsStateError,
      );

      // Sonraki gecelerde hakkı yoktur.
      while (!state.isTurnSequenceComplete) {
        state = engine.completeNightTurn(state);
      }
      state = engine.resolveNight(state, random);
      state = playVote(state, {
        for (final p in state.alivePlayers) p.id: 'koylu2',
        'koylu2': 'vampir1',
      });
      state = engine.startNight(state);
      expect(
        engine.nightAbilityOf(state, state.playerById('kahin')),
        WerewolfNightAbility.none,
      );
    });

    test('doktor aynı kişiyi art arda iki gece koruyamaz', () {
      var state = playNight(gameWith(village), {
        'vampir1': (s) => engine.vampireVote(s, 'vampir1', 'koylu1'),
        'vampir2': (s) => engine.vampireVote(s, 'vampir2', 'koylu1'),
        'doktor': (s) => engine.doctorProtect(s, 'doktor', 'koylu2'),
      });
      state = playVote(state, {
        for (final p in state.alivePlayers) p.id: 'doktor',
        'doktor': 'vampir1',
        'vampir1': 'kahin',
        'vampir2': 'cadi',
        'cadi': 'kahin',
        'kahin': 'cadi',
      });
      // Eşitlik (kahin 2, cadi 2, ...) → kimse elenmez.
      state = engine.startNight(state);
      expect(
        engine.doctorOptions(state).map((p) => p.id),
        isNot(contains('koylu2')),
      );
    });
  });

  group('bireysel gizli oylama', () {
    WerewolfGameState afterQuietNight([
      WerewolfTieBreak tieBreak = WerewolfTieBreak.noElimination,
    ]) =>
        playNight(gameWith(village, tieBreak: tieBreak), {
          'vampir1': (s) => engine.vampireVote(s, 'vampir1', 'koylu1'),
          'vampir2': (s) => engine.vampireVote(s, 'vampir2', 'koylu1'),
          'doktor': (s) => engine.doctorProtect(s, 'doktor', 'koylu1'),
        });

    test('kimse kendine oy veremez', () {
      final state = engine.startVoting(afterQuietNight());
      final voter = state.currentTurnPlayer!.id;
      expect(
        engine.voteOptions(state, voter).map((p) => p.id),
        isNot(contains(voter)),
      );
      expect(
        () => engine.castVote(state, voter, voter, random),
        throwsArgumentError,
      );
    });

    test('sırası gelmeyen oy veremez', () {
      final state = engine.startVoting(afterQuietNight());
      expect(
        () => engine.castVote(state, 'koylu2', 'vampir1', random),
        throwsStateError,
      );
    });

    test('son oyla birlikte otomatik sayılır, en çok oy alan sürülür', () {
      final state = playVote(afterQuietNight(), {
        'vampir1': 'koylu1',
        'vampir2': 'koylu1',
        'doktor': 'vampir1',
        'cadi': 'vampir1',
        'kahin': 'vampir1',
        'koylu1': 'vampir2',
        'koylu2': 'vampir1',
      });
      expect(state.voteResolved, isTrue);
      expect(state.voteTally['vampir1'], 4);
      expect(state.lastExiledId, 'vampir1');
      expect(state.playerById('vampir1').isAlive, isFalse);
    });

    test('eşitlikte varsayılan kural: kimse elenmez', () {
      final state = playVote(afterQuietNight(), {
        'vampir1': 'koylu1',
        'vampir2': 'koylu1',
        'doktor': 'koylu1',
        'cadi': 'vampir1',
        'kahin': 'vampir1',
        'koylu1': 'vampir1',
        'koylu2': 'doktor',
      });
      expect(state.voteWasTie, isTrue);
      expect(state.lastExiledId, isNull);
      expect(state.alivePlayers, hasLength(7));
    });

    test('eşitlikte kura ayarı: berabere kalanlardan biri elenir', () {
      final state = playVote(afterQuietNight(WerewolfTieBreak.randomDraw), {
        'vampir1': 'koylu1',
        'vampir2': 'koylu1',
        'doktor': 'koylu1',
        'cadi': 'vampir1',
        'kahin': 'vampir1',
        'koylu1': 'vampir1',
        'koylu2': 'doktor',
      });
      expect(state.voteWasTie, isTrue);
      expect(state.lastExiledId, isIn(['koylu1', 'vampir1']));
    });
  });

  group('avcı ve zafer', () {
    const withHunter = {
      'vampir1': WerewolfRole.vampir,
      'vampir2': WerewolfRole.vampir,
      'avci': WerewolfRole.avci,
      'doktor': WerewolfRole.doktor,
      'koylu1': WerewolfRole.koylu,
      'koylu2': WerewolfRole.koylu,
    };

    WerewolfGameState hunterKilledAtNight() => playNight(gameWith(withHunter), {
          'vampir1': (s) => engine.vampireVote(s, 'vampir1', 'avci'),
          'vampir2': (s) => engine.vampireVote(s, 'vampir2', 'avci'),
          'doktor': (s) => engine.doctorProtect(s, 'doktor', 'koylu1'),
        });

    test('gece ölen avcı karar verene kadar oylama başlamaz', () {
      final state = hunterKilledAtNight();
      expect(state.pendingHunterId, 'avci');
      expect(() => engine.startVoting(state), throwsStateError);
    });

    test('avcı tek kurşunuyla birini vurur', () {
      final state = engine.hunterShoot(hunterKilledAtNight(), 'vampir1');
      expect(state.pendingHunterId, isNull);
      expect(state.hunterBulletAvailable, isFalse);
      expect(state.deathOf('vampir1')?.cause, WerewolfDeathCause.hunter);
    });

    test('avcı kurşunu kullanmamayı seçebilir', () {
      final state = engine.hunterHoldFire(hunterKilledAtNight());
      expect(state.pendingHunterId, isNull);
      expect(state.alivePlayers, hasLength(5));
    });

    test('oylamayla sürülen avcı da karar verir; zafer ondan sonra', () {
      // Gece koylu2 ölür → 2 vampir, avcı, doktor, koylu1.
      var state = playNight(gameWith(withHunter), {
        'vampir1': (s) => engine.vampireVote(s, 'vampir1', 'koylu2'),
        'vampir2': (s) => engine.vampireVote(s, 'vampir2', 'koylu2'),
        'doktor': (s) => engine.doctorProtect(s, 'doktor', 'koylu1'),
      });
      // Avcı sürülür → 2 vampir vs 2 köylü olurdu (vampir zaferi)...
      state = playVote(state, {
        'vampir1': 'avci',
        'vampir2': 'avci',
        'avci': 'vampir1',
        'doktor': 'avci',
        'koylu1': 'avci',
      });
      expect(state.pendingHunterId, 'avci');
      expect(state.isFinished, isFalse);

      // ...ama avcı bir vampiri vurarak oyunu sürdürür.
      state = engine.hunterShoot(state, 'vampir1');
      expect(state.isFinished, isFalse);
    });

    test('son vampir sürülünce köylüler kazanır', () {
      var state = playNight(gameWith(withHunter), {
        'vampir1': (s) => engine.vampireVote(s, 'vampir1', 'koylu2'),
        'vampir2': (s) => engine.vampireVote(s, 'vampir2', 'koylu2'),
        'doktor': (s) => engine.doctorProtect(s, 'doktor', 'koylu2'),
      });
      state = engine.hunterShoot(
        playVote(state, {
          'vampir1': 'avci',
          'vampir2': 'avci',
          'avci': 'vampir1',
          'doktor': 'avci',
          'koylu1': 'avci',
          'koylu2': 'avci',
        }),
        'vampir1',
      );
      state = playNight(engine.startNight(state), {
        'vampir2': (s) => engine.vampireVote(s, 'vampir2', 'koylu1'),
        'doktor': (s) => engine.doctorProtect(s, 'doktor', 'koylu1'),
      });
      state = playVote(state, {
        'vampir2': 'doktor',
        'doktor': 'vampir2',
        'koylu1': 'vampir2',
        'koylu2': 'vampir2',
      });
      expect(state.winner, WerewolfTeam.villagers);
      expect(state.phase, WerewolfPhase.gameFinished);
    });

    test('vampirler köylülere eşitlenince kazanır', () {
      final state = playNight(
        gameWith({
          'vampir1': WerewolfRole.vampir,
          'vampir2': WerewolfRole.vampir,
          'a': WerewolfRole.koylu,
          'b': WerewolfRole.koylu,
          'c': WerewolfRole.koylu,
        }),
        {
          'vampir1': (s) => engine.vampireVote(s, 'vampir1', 'a'),
          'vampir2': (s) => engine.vampireVote(s, 'vampir2', 'a'),
        },
      );
      expect(state.winner, WerewolfTeam.vampires);
    });
  });
}
