import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/data/repositories/taboo_word_repository.dart';
import 'package:party_game/domain/models/taboo_card.dart';
import 'package:party_game/domain/models/taboo_match.dart';
import 'package:party_game/domain/models/taboo_settings.dart';
import 'package:party_game/domain/services/taboo_engine.dart';

void main() {
  const engine = TabooEngine();
  const repository = LocalTabooWordRepository();

  TabooMatch newMatch({
    TabooSettings settings = const TabooSettings(),
    List<TabooCard>? cards,
  }) =>
      engine.createMatch(
        settings: settings,
        cards: cards ?? repository.cards(),
        random: Random(7),
      );

  TabooMatch playing([TabooSettings settings = const TabooSettings()]) =>
      engine.startTurn(newMatch(settings: settings), Random(7));

  group('kart deposu', () {
    test('en az 20 kart var ve her kartta tam 5 yasaklı kelime var', () {
      final cards = repository.cards();
      expect(cards.length, greaterThanOrEqualTo(20));
      for (final card in cards) {
        expect(card.forbiddenWords, hasLength(TabooCard.forbiddenWordCount),
            reason: card.targetWord);
      }
    });

    test('kart kimlikleri benzersiz', () {
      final ids = repository.cards().map((c) => c.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('her kartın kategorisi tanımlı', () {
      for (final card in repository.cards()) {
        expect(repository.categoryNames, contains(card.categoryId));
      }
    });

    test('kategori ve zorluk filtresi çalışır', () {
      final spor = repository.cards(categoryIds: {'spor'});
      expect(spor, isNotEmpty);
      expect(spor.every((c) => c.categoryId == 'spor'), isTrue);

      final hard = repository.cards(difficulty: TabooDifficulty.hard);
      expect(hard, isNotEmpty);
      expect(hard.every((c) => c.difficulty == TabooDifficulty.hard), isTrue);
    });
  });

  group('tur akışı', () {
    test('maç hazır durumda ve sıra ilk takımda başlar', () {
      final match = newMatch();
      expect(match.status, TabooGameStatus.ready);
      expect(match.activeTeamIndex, 0);
      expect(match.currentCard, isNull);
      expect(match.teams.map((t) => t.name), ['Takım A', 'Takım B']);
    });

    test('tur başlayınca kart çekilir ve pas hakkı yenilenir', () {
      final match = playing();
      expect(match.status, TabooGameStatus.inProgress);
      expect(match.currentCard, isNotNull);
      expect(match.activeTeam.passesLeft, TabooSettings.defaultPassLimit);
    });

    test('DOĞRU +1, TABU −1 puan verir ve kart değişir', () {
      var match = playing();
      final first = match.currentCard;

      match = engine.markCorrect(match, Random(1));
      expect(match.activeTeam.score, 1);
      expect(match.currentCard, isNot(first));

      match = engine.markTaboo(match, Random(1));
      expect(match.activeTeam.score, 0);
      expect(match.turnEntries.map((e) => e.outcome),
          [TabooOutcome.correct, TabooOutcome.taboo]);
    });

    test('PAS puanı değiştirmez ve hakkı bitince kart değiştirmez', () {
      var match = playing(const TabooSettings(passLimit: 1));

      match = engine.pass(match, Random(1));
      expect(match.activeTeam.score, 0);
      expect(match.activeTeam.passesLeft, 0);

      final cardBefore = match.currentCard;
      final after = engine.pass(match, Random(1));
      expect(after.currentCard, cardBefore);
      expect(after.countOf(TabooOutcome.pass), 1);
    });

    test('süre bitince tur biter, sıra devredilince diğer takım hazırlanır',
        () {
      var match = engine.tick(playing(), 0);
      expect(match.status, TabooGameStatus.roundEnded);
      expect(match.currentCard, isNull);
      expect(match.completedTurns, 1);

      match = engine.passTurnToNextTeam(match);
      expect(match.status, TabooGameStatus.ready);
      expect(match.activeTeamIndex, 1);
      expect(match.remainingSeconds, TabooSettings.defaultRoundDurationSeconds);
    });

    test('deste bitince kartlar karıştırılıp yeniden kullanılır', () {
      final cards = repository.cards().take(3).toList();
      var match = engine.startTurn(newMatch(cards: cards), Random(3));
      for (var i = 0; i < 10; i++) {
        final previous = match.currentCard;
        match = engine.markCorrect(match, Random(i));
        expect(match.currentCard, isNotNull);
        expect(match.currentCard, isNot(previous),
            reason: 'Aynı kart arka arkaya gelmemeli');
      }
      expect(match.activeTeam.score, 10);
    });
  });

  group('kazanma', () {
    const settings = TabooSettings(targetScore: 2);

    TabooMatch scoreAndEnd(TabooMatch match, int correctCount) {
      var current = engine.startTurn(match, Random(1));
      for (var i = 0; i < correctCount; i++) {
        current = engine.markCorrect(current, Random(i));
      }
      return engine.endTurn(current);
    }

    test('ilk takım hedefe ulaşsa da ikinci takım turunu oynamadan bitmez', () {
      final afterA = scoreAndEnd(newMatch(settings: settings), 3);
      expect(afterA.status, TabooGameStatus.roundEnded);
      expect(afterA.winnerIndex, isNull);
    });

    test('eşit turdan sonra hedefi geçen önde olan takım kazanır', () {
      final afterA = scoreAndEnd(newMatch(settings: settings), 3);
      final afterB = scoreAndEnd(engine.passTurnToNextTeam(afterA), 1);

      expect(afterB.status, TabooGameStatus.gameFinished);
      expect(afterB.winnerIndex, 0);
      expect(afterB.winner?.name, 'Takım A');
    });

    test('skorlar eşitse oyun devam eder', () {
      final afterA = scoreAndEnd(newMatch(settings: settings), 2);
      final afterB = scoreAndEnd(engine.passTurnToNextTeam(afterA), 2);

      expect(afterB.status, TabooGameStatus.roundEnded);
      expect(afterB.winnerIndex, isNull);
    });
  });
}
