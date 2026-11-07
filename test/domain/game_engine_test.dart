import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/data/repositories/word_repository.dart';
import 'package:party_game/domain/models/game_session.dart';
import 'package:party_game/domain/models/player.dart';
import 'package:party_game/domain/services/game_engine.dart';
import 'package:party_game/domain/services/randomization_service.dart';

void main() {
  const engine = GameEngine();
  const players = [
    Player(id: 'a', name: 'Ayşe'),
    Player(id: 'b', name: 'Burak'),
    Player(id: 'c', name: 'Cem'),
  ];

  GameSession newSession() => engine.createSession(
        players: players,
        wordRepository: LocalWordRepository(),
        randomizationService: const RandomizationService(),
        random: Random(42),
        sessionId: 'test',
      );

  GameSession votingSession() =>
      engine.startVoting(engine.startRound(newSession()));

  String innocentIdOf(GameSession s) =>
      s.players.firstWhere((p) => p.id != s.imposterId).id;

  group('aşama geçişleri', () {
    test('roleReveal → playing → voting', () {
      final session = newSession();
      expect(session.status, GameState.roleReveal);

      final playing = engine.startRound(session);
      expect(playing.status, GameState.playing);

      final voting = engine.startVoting(playing);
      expect(voting.status, GameState.voting);
    });

    test('sırası dışındaki geçişler oturumu değiştirmez', () {
      final session = newSession();
      expect(engine.startVoting(session).status, GameState.roleReveal);

      final voting = votingSession();
      expect(engine.startRound(voting).status, GameState.voting);
    });

    test('oylama açılmadan oy verilemez', () {
      final playing = engine.startRound(newSession());
      expect(
        () => engine.finishWithVote(playing, playing.imposterId),
        throwsStateError,
      );
    });
  });

  group('oyun sonucu', () {
    test('Imposter elenirse masumlar kazanır', () {
      final session = votingSession();
      final finished = engine.finishWithVote(session, session.imposterId);

      expect(finished.isFinished, isTrue);
      expect(finished.result, GameResult.innocentsWon);
      expect(finished.accusedPlayerId, session.imposterId);
    });

    test('masum elenirse Imposter kazanır', () {
      final session = votingSession();
      final innocentId = innocentIdOf(session);
      final finished = engine.finishWithVote(session, innocentId);

      expect(finished.result, GameResult.imposterWon);
      expect(finished.accusedPlayer?.id, innocentId);
    });

    test('bitmiş oturumda ikinci oy sonucu değiştirmez', () {
      final session = votingSession();
      final finished = engine.finishWithVote(session, session.imposterId);
      final again = engine.finishWithVote(finished, innocentIdOf(session));

      expect(again.result, GameResult.innocentsWon);
      expect(again.accusedPlayerId, session.imposterId);
    });

    test('bilinmeyen oyuncu elenemez', () {
      expect(
        () => engine.finishWithVote(votingSession(), 'yok'),
        throwsArgumentError,
      );
    });
  });

  group('Imposter ipucu', () {
    final repository = LocalWordRepository();

    GameSession sessionWithHint(bool giveImposterHint, int seed) =>
        engine.createSession(
          players: players,
          wordRepository: repository,
          randomizationService: const RandomizationService(),
          random: Random(seed),
          sessionId: 'ipucu_$seed',
          giveImposterHint: giveImposterHint,
        );

    test('ayar açıkken ipucu seçilen kelimenin ipucuna eşit', () {
      for (var seed = 0; seed < 25; seed++) {
        final session = sessionWithHint(true, seed);
        final expected = repository
            .entriesIn(session.category)
            .firstWhere((e) => e.word == session.secretWord)
            .hint;
        expect(session.imposterHint, expected, reason: session.secretWord);
        expect(session.giveImposterHint, isTrue);
      }
    });

    test('ayar kapalıyken ipucu yok', () {
      for (var seed = 0; seed < 10; seed++) {
        expect(sessionWithHint(false, seed).imposterHint, isNull);
      }
    });

    test('varsayılan olarak ipucu verilmez', () {
      expect(newSession().imposterHint, isNull);
      expect(newSession().giveImposterHint, isFalse);
    });

    test('ipucu oyun boyunca (oylama ve sonuç) korunur', () {
      final session = engine.startVoting(
        engine.startRound(sessionWithHint(true, 3)),
      );
      final finished = engine.finishWithVote(session, session.imposterId);
      expect(finished.imposterHint, session.imposterHint);
      expect(finished.imposterHint, isNotNull);
    });
  });
}
