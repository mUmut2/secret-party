import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/data/repositories/word_repository.dart';
import 'package:party_game/domain/models/player.dart';
import 'package:party_game/domain/models/taboo_card.dart';
import 'package:party_game/domain/models/taboo_settings.dart';
import 'package:party_game/domain/services/game_engine.dart';
import 'package:party_game/domain/services/randomization_service.dart';
import 'package:party_game/domain/services/seen_content_tracker.dart';
import 'package:party_game/domain/services/taboo_engine.dart';

/// Tekrar önleme ("görülenler") servisinin kuralları.
void main() {
  String keyOf(String item) => 'test:$item';

  group('SeenContentTracker', () {
    test('havuz bitene kadar aynı kayıt tekrar gelmez', () {
      final tracker = SeenContentTracker(InMemorySeenContentStore());
      final pool = [for (var i = 0; i < 20; i++) 'k$i'];
      final random = Random(7);
      final picked = [
        for (var i = 0; i < 20; i++) tracker.pick(pool, keyOf, random)
      ];
      expect(picked.toSet().length, 20);
    });

    test('havuz bitince yalnızca o havuz sıfırlanır ve seçim sürer', () {
      final tracker = SeenContentTracker(InMemorySeenContentStore());
      final poolA = ['a1', 'a2', 'a3'];
      final random = Random(3);
      tracker.markSeen(keyOf('b1'));
      for (var i = 0; i < 3; i++) {
        tracker.pick(poolA, keyOf, random);
      }
      // 4. seçim: A havuzu sıfırlanır, B'nin geçmişi korunur.
      final next = tracker.pick(poolA, keyOf, random);
      expect(poolA, contains(next));
      expect(tracker.isSeen(keyOf('b1')), isTrue);
      expect(tracker.unseenOf(poolA, keyOf).length, 2);
    });

    test('tek kayıtlı havuz çökmez, hep aynı kaydı verir', () {
      final tracker = SeenContentTracker(InMemorySeenContentStore());
      final random = Random(1);
      for (var i = 0; i < 5; i++) {
        expect(tracker.pick(['tek'], keyOf, random), 'tek');
      }
    });

    test('boş havuz programlama hatasıdır', () {
      final tracker = SeenContentTracker(InMemorySeenContentStore());
      expect(
        () => tracker.pick(<String>[], keyOf, Random(1)),
        throwsArgumentError,
      );
    });

    test('kayıt boyutu sınırlıdır, en eskiler atılır', () async {
      final store = InMemorySeenContentStore();
      final tracker = SeenContentTracker(store, maxEntries: 5);
      for (var i = 0; i < 8; i++) {
        tracker.markSeen('k$i');
      }
      await pumpEventQueue();
      expect(tracker.length, 5);
      expect(tracker.isSeen('k0'), isFalse);
      expect(tracker.isSeen('k7'), isTrue);
      expect(store.keys, ['k3', 'k4', 'k5', 'k6', 'k7']);
    });

    test('kayıtlı geçmiş yeniden açılışta okunur, boş anahtarlar atılır', () {
      final tracker = SeenContentTracker(
        InMemorySeenContentStore(['', 'test:x', 'test:y']),
      );
      expect(tracker.length, 2);
      expect(tracker.isSeen('test:x'), isTrue);
    });

    test('varsayılan sınır 3000 ve fazlası açılışta kırpılır', () {
      final tracker = SeenContentTracker(
        InMemorySeenContentStore([for (var i = 0; i < 3100; i++) 'k$i']),
      );
      expect(SeenContentTracker.defaultMaxEntries, 3000);
      expect(tracker.length, 3000);
      expect(tracker.isSeen('k99'), isFalse);
    });

    test('clear tüm geçmişi siler ve depoya yazar', () async {
      final store = InMemorySeenContentStore(['test:a']);
      final tracker = SeenContentTracker(store)..clear();
      await pumpEventQueue();
      expect(tracker.length, 0);
      expect(store.keys, isEmpty);
    });
  });

  group('Imposter entegrasyonu', () {
    final repository = LocalWordRepository();
    final players = [
      for (final name in ['Ali', 'Ayşe', 'Can', 'Ece'])
        Player(id: name, name: name),
    ];
    const engine = GameEngine();

    test('kategori havuzu bitene kadar kelime tekrar etmez', () {
      final tracker = SeenContentTracker(InMemorySeenContentStore());
      final category = repository.categoryIds.first;
      final poolSize = repository.entriesIn(category).length;
      final random = Random(42);
      final words = <String>{};
      for (var i = 0; i < poolSize; i++) {
        final session = engine.createSession(
          players: players,
          wordRepository: repository,
          randomizationService: const RandomizationService(),
          random: random,
          sessionId: 's$i',
          categoryId: category,
          seenContent: tracker,
        );
        expect(words.add(session.secretWord), isTrue,
            reason: 'tekrar: ${session.secretWord}');
      }
      expect(words.length, poolSize);
    });

    test('Karışık havuz tüm kategorileri kapsar ve tekrar etmez', () {
      final tracker = SeenContentTracker(InMemorySeenContentStore());
      final random = Random(5);
      final seen = <String>{};
      final categories = <String>{};
      for (var i = 0; i < 200; i++) {
        final session = engine.createSession(
          players: players,
          wordRepository: repository,
          randomizationService: const RandomizationService(),
          random: random,
          sessionId: 's$i',
          seenContent: tracker,
        );
        expect(seen.add('${session.category}:${session.secretWord}'), isTrue);
        categories.add(session.category);
      }
      expect(categories.length, repository.categoryIds.length);
    });

    test('Tekrar Oyna zincirinde aynı kişi art arda Imposter olmaz', () {
      const service = RandomizationService();
      final random = Random(9);
      var previous = service.pickImposterId(players, random);
      for (var i = 0; i < 100; i++) {
        final next =
            service.pickImposterId(players, random, excludeId: previous);
        expect(next, isNot(previous));
        previous = next;
      }
    });

    test('tek oyuncuda art arda Imposter kuralı esner', () {
      final solo = [const Player(id: 'p', name: 'P')];
      expect(
        const RandomizationService()
            .pickImposterId(solo, Random(1), excludeId: 'p'),
        'p',
      );
    });
  });

  group('Tabu entegrasyonu', () {
    test('daha önce görülmeyen kartlar önce çekilir', () {
      final cards = [
        for (var i = 0; i < 10; i++)
          TabooCard(
            id: 'c$i',
            targetWord: 'Kart$i',
            forbiddenWords: const ['a', 'b', 'c', 'd', 'e'],
            categoryId: 'genel',
          ),
      ];
      final seenIds = {'c0', 'c1', 'c2', 'c3', 'c4', 'c5'};
      final match = const TabooEngine().createMatch(
        settings: const TabooSettings(),
        cards: cards,
        random: Random(2),
        isSeen: (card) => seenIds.contains(card.id),
      );
      // Deste sondan çekilir: son 4 kart görülmemişler olmalı.
      final drawOrder = match.deck.reversed.map((c) => c.id).toList();
      expect(drawOrder.take(4).toSet(), {'c6', 'c7', 'c8', 'c9'});
    });
  });
}
