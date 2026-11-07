import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/domain/models/bomb/bomb_game_state.dart';
import 'package:party_game/domain/models/bomb/bomb_settings.dart';
import 'package:party_game/domain/models/bomb/bomb_task.dart';
import 'package:party_game/domain/models/player.dart';
import 'package:party_game/domain/services/bomb_game_engine.dart';

void main() {
  const engine = BombGameEngine();
  const task = BombTask(categoryId: 'yiyecek', prompt: 'Bir meyve söyle');
  final players = [
    for (final name in ['Ali', 'Ayşe', 'Can', 'Ece'])
      Player(id: name, name: name),
  ];

  BombGameState newGame({int rounds = 5, int seed = 1}) => engine.createGame(
        players: players,
        settings: BombSettings(rounds: rounds),
        firstTask: task,
        random: Random(seed),
        gameId: 'g',
      );

  /// Turu oynatır: [passes] kez geçirip patlatır.
  BombGameState playRound(BombGameState state, int passes) {
    var s = engine.startRound(state);
    for (var i = 0; i < passes; i++) {
      s = engine.passBomb(s);
    }
    return engine.explode(s);
  }

  group('kurulum', () {
    test('3 oyuncudan az ya da 10 oyuncudan fazla kabul edilmez', () {
      expect(
        () => engine.createGame(
          players: players.take(2).toList(),
          settings: const BombSettings(),
          firstTask: task,
          random: Random(1),
          gameId: 'g',
        ),
        throwsArgumentError,
      );
      expect(BombSettings.validatePlayerCount(2), isNotNull);
      expect(BombSettings.validatePlayerCount(3), isNull);
      expect(BombSettings.validatePlayerCount(10), isNull);
      expect(BombSettings.validatePlayerCount(11), isNotNull);
    });

    test('oyun 1. turda, hazır aşamasında ve sıfır patlamayla başlar', () {
      final game = newGame();
      expect(game.phase, BombPhase.ready);
      expect(game.roundNumber, 1);
      expect(game.explosionCounts.values.every((c) => c == 0), isTrue);
      expect(game.lastExplodedId, isNull);
    });
  });

  group('fitil', () {
    test('her fitil süresi seçilen aralıkta kalır', () {
      for (final fuse in BombFuse.values) {
        final random = Random(fuse.index);
        for (var i = 0; i < 500; i++) {
          final d = engine.pickFuse(fuse, random);
          expect(
              d.inMilliseconds, greaterThanOrEqualTo(fuse.minSeconds * 1000));
          expect(d.inMilliseconds, lessThanOrEqualTo(fuse.maxSeconds * 1000));
        }
      }
    });

    test('fitil aralıkları: Kısa 15-30, Orta 25-50, Uzun 40-70', () {
      expect((BombFuse.short.minSeconds, BombFuse.short.maxSeconds), (15, 30));
      expect(
          (BombFuse.medium.minSeconds, BombFuse.medium.maxSeconds), (25, 50));
      expect((BombFuse.long.minSeconds, BombFuse.long.maxSeconds), (40, 70));
      expect(const BombSettings().fuse, BombFuse.medium);
      expect(const BombSettings().rounds, 10);
    });

    test('tik temposu geçen süreyle hızlanır, alt sınırda sabitlenir', () {
      final first = engine.tickInterval(Duration.zero);
      final later = engine.tickInterval(const Duration(seconds: 20));
      final latest = engine.tickInterval(const Duration(minutes: 5));
      expect(later, lessThan(first));
      expect(
        latest,
        const Duration(milliseconds: BombGameEngine.fastestTickMs),
      );
      // Tempo yalnızca geçen süreye bağlıdır: her tur aynı tempoyla başlar.
      expect(engine.tickInterval(Duration.zero), first);
    });
  });

  group('tur akışı', () {
    test('GEÇİR bombayı sıradakine verir, sona gelince başa döner', () {
      var game = engine.startRound(newGame());
      final start = game.holderIndex;
      for (var i = 1; i <= players.length; i++) {
        game = engine.passBomb(game);
        expect(game.holderIndex, (start + i) % players.length);
      }
    });

    test('GEÇİR yalnızca fitil yanarken çalışır', () {
      final game = newGame();
      expect(engine.passBomb(game).holderIndex, game.holderIndex);
    });

    test('patlama bombayı tutanı sayar; sonraki turu patlayan başlatır', () {
      var game = newGame();
      game = playRound(game, 2);
      final exploded = game.lastExplodedId!;
      expect(game.phase, BombPhase.exploded);
      expect(game.explosionsOf(exploded), 1);
      expect(game.explosionCounts.values.reduce((a, b) => a + b), 1);

      const nextTask = BombTask(categoryId: 'hayvan', prompt: 'Bir kuş söyle');
      game = engine.nextRound(game, nextTask);
      expect(game.phase, BombPhase.ready);
      expect(game.roundNumber, 2);
      expect(game.holder.id, exploded);
      expect(game.task.prompt, 'Bir kuş söyle');
    });

    test('çift patlama tetiklenirse ikinci kez sayılmaz', () {
      var game = playRound(newGame(), 1);
      game = engine.explode(game);
      expect(game.explosionCounts.values.reduce((a, b) => a + b), 1);
    });

    test('seçilen tur sayısı oynanınca oyun biter', () {
      var game = newGame(rounds: 5);
      for (var round = 1; round <= 5; round++) {
        expect(game.roundNumber, round);
        game = playRound(game, round);
        game = engine.nextRound(game, task);
      }
      expect(game.phase, BombPhase.finished);
      expect(game.explosionCounts.values.reduce((a, b) => a + b), 5);
    });
  });

  group('final özeti', () {
    test('sıralama, en çok patlayan, hiç patlamayan ve son patlayan', () {
      var game = newGame(rounds: 5, seed: 3);
      // Her turda aynı geçiş sayısı: patlayan aynı kişi olur (başlatan o).
      for (var round = 0; round < 3; round++) {
        game = playRound(game, 0);
        game = engine.nextRound(game, task);
      }
      final victim = game.holder.id;
      game = playRound(game, 1);
      final last = game.lastExplodedId;

      final summary = engine.summarize(game);
      expect(summary.standings.first.player.id, victim);
      expect(summary.standings.first.explosions, 3);
      expect(summary.mostExploded.map((p) => p.id), [victim]);
      expect(summary.lastExploded?.id, last);
      expect(summary.neverExploded.length, players.length - 2);
      final counts = summary.standings.map((s) => s.explosions).toList();
      final sorted = [...counts]..sort((a, b) => b.compareTo(a));
      expect(counts, sorted);
    });

    test('eşitlikte birden fazla "en çok patlayan" olur', () {
      var game = newGame(rounds: 5);
      game = playRound(game, 0);
      game = engine.nextRound(game, task);
      game = playRound(game, 1);
      final summary = engine.summarize(game);
      expect(summary.mostExploded.length, 2);
    });
  });
}
