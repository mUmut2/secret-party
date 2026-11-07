import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/data/repositories/spy_location_repository.dart';
import 'package:party_game/domain/models/player.dart';
import 'package:party_game/domain/models/spy/spy_game_state.dart';
import 'package:party_game/domain/models/spy/spy_settings.dart';
import 'package:party_game/domain/services/spy_engine.dart';

void main() {
  const engine = SpyEngine();
  const repository = LocalSpyLocationRepository();

  List<Player> players(int n) =>
      [for (var i = 0; i < n; i++) Player(id: 'p$i', name: 'Oyuncu $i')];

  SpyGameState newGame({int count = 5, int spies = 1, int seed = 3}) =>
      engine.createGame(
        players: players(count),
        settings: SpySettings(spyCount: spies),
        locations: repository.locations,
        random: Random(seed),
        gameId: 'g',
      );

  /// Herkes [target]'a oy verir; [target] kendi sırasında [fallback]'e verir.
  SpyGameState voteAll(SpyGameState state, String target, String fallback) {
    var s = engine.startVoting(state);
    while (!s.isVoteComplete) {
      final voter = s.currentVoter!.id;
      s = engine.castVote(s, voter, voter == target ? fallback : target);
    }
    return s;
  }

  group('konum deposu', () {
    test('en az 20 konum, her konumda en az 5 benzersiz rol', () {
      final locations = repository.locations;
      expect(locations.length, greaterThanOrEqualTo(20));
      expect(locations.map((l) => l.name).toSet(), hasLength(locations.length));
      for (final location in locations) {
        expect(location.roles.length, greaterThanOrEqualTo(5));
        expect(
          location.roles.toSet(),
          hasLength(location.roles.length),
          reason: location.name,
        );
      }
    });

    test('her konum en kalabalık oyunda bile herkese benzersiz rol verebilir',
        () {
      for (final location in repository.locations) {
        expect(
          location.roles.length,
          greaterThanOrEqualTo(SpySettings.maxPlayers - 1),
          reason: location.name,
        );
      }
    });
  });

  group('rol dağıtımı', () {
    test('tek ajan konumu bilmez, masumlar benzersiz rol alır', () {
      for (var seed = 0; seed < 20; seed++) {
        final game = newGame(count: 9, seed: seed);
        expect(game.spies, hasLength(1));
        expect(game.spies.single.roleName, isNull);
        final roles = game.players
            .where((p) => !p.isSpy)
            .map((p) => p.roleName!)
            .toList();
        expect(roles.toSet(), hasLength(roles.length));
        expect(roles.every(game.location.roles.contains), isTrue);
      }
    });

    test('iki ajan seçeneği ve oyuncu sınırları', () {
      expect(newGame(count: 6, spies: 2).spies, hasLength(2));
      expect(
        const SpySettings(spyCount: 2).validate(5),
        isNotNull,
      );
      expect(const SpySettings().validate(2), isNotNull);
      expect(const SpySettings().validate(10), isNotNull);
    });
  });

  group('kazanma şartları', () {
    test('ajan konumu doğru tahmin ederse Ajan kazanır', () {
      var game = engine.startRound(newGame());
      game = engine.startSpyGuess(game);
      game = engine.guessLocation(game, game.location.name);
      expect(game.outcome, SpyOutcome.spyGuessedCorrectly);
      expect(game.winner, SpyTeam.spies);
    });

    test('ajan kendisi durdurup yanlış tahmin ederse Masumlar kazanır', () {
      var game = engine.startRound(newGame());
      final wrong = game.allLocations.firstWhere((l) => l != game.location);
      game = engine.guessLocation(engine.startSpyGuess(game), wrong.name);
      expect(game.outcome, SpyOutcome.spyGuessedWrong);
      expect(game.winner, SpyTeam.innocents);
    });

    test('oylamada masum suçlanırsa Ajan kazanır', () {
      final game = engine.startRound(newGame());
      final innocent = game.players.firstWhere((p) => !p.isSpy).id;
      final other = game.players.firstWhere((p) => p.id != innocent).id;
      final result = voteAll(game, innocent, other);
      expect(result.outcome, SpyOutcome.innocentAccused);
      expect(result.winner, SpyTeam.spies);
    });

    test('oylar eşitse ajan bulunamaz, Ajan kazanır', () {
      var game = engine.startVoting(engine.startRound(newGame(count: 4)));
      // p0→p1, p1→p0, p2→p3, p3→p2: herkes 1 oy.
      const ballot = {'p0': 'p1', 'p1': 'p0', 'p2': 'p3', 'p3': 'p2'};
      while (!game.isVoteComplete) {
        final voter = game.currentVoter!.id;
        game = engine.castVote(game, voter, ballot[voter]!);
      }
      expect(game.outcome, SpyOutcome.voteTie);
      expect(game.winner, SpyTeam.spies);
    });

    test('ajan yakalanırsa son şansı vardır: yanlışsa Masumlar kazanır', () {
      final game = engine.startRound(newGame());
      final spy = game.spies.single.id;
      final other = game.players.firstWhere((p) => p.id != spy).id;
      var result = voteAll(game, spy, other);

      expect(result.phase, SpyPhase.spyGuessing);
      expect(result.guessReason, SpyGuessReason.caughtByVote);
      expect(result.accusedId, spy);

      final wrong = result.allLocations.firstWhere((l) => l != result.location);
      result = engine.guessLocation(result, wrong.name);
      expect(result.outcome, SpyOutcome.caughtAndGuessedWrong);
      expect(result.winner, SpyTeam.innocents);
    });

    test('yakalanan ajan konumu bilirse yine Ajan kazanır', () {
      final game = engine.startRound(newGame());
      final spy = game.spies.single.id;
      final other = game.players.firstWhere((p) => p.id != spy).id;
      var result = voteAll(game, spy, other);
      result = engine.guessLocation(result, result.location.name);
      expect(result.outcome, SpyOutcome.caughtButGuessedCorrectly);
      expect(result.winner, SpyTeam.spies);
    });
  });

  group('oylama kuralları', () {
    test('kimse kendine oy veremez ve sırası olmayan oy veremez', () {
      final game = engine.startVoting(engine.startRound(newGame()));
      final voter = game.currentVoter!.id;
      expect(
        () => engine.castVote(game, voter, voter),
        throwsArgumentError,
      );
      final notVoter = game.players.last.id;
      expect(
        () => engine.castVote(game, notVoter, voter),
        throwsStateError,
      );
    });

    test('oylama başlayınca ajan artık kendiliğinden tahmin edemez', () {
      final game = engine.startVoting(engine.startRound(newGame()));
      expect(() => engine.startSpyGuess(game), throwsStateError);
    });
  });
}
