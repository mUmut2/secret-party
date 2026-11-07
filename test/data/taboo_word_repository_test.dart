import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/data/repositories/taboo_word_repository.dart';
import 'package:party_game/domain/models/taboo_card.dart';

import '../support/content_rules.dart';

/// Tabu destesinin içerik kuralları.
void main() {
  const repository = LocalTabooWordRepository();
  final cards = repository.cards();

  void expectNoViolations(List<String> violations, String rule) =>
      expect(violations, isEmpty, reason: rule);

  test('kategoriler korunur ve her kategoride kart var', () {
    expect(repository.categoryNames.keys, [
      'genel',
      'yiyecek',
      'spor',
      'eglence',
      'mekan',
      'meslek',
      'teknoloji',
      'doga',
    ]);
    for (final id in repository.categoryNames.keys) {
      expect(repository.cards(categoryIds: {id}), isNotEmpty, reason: id);
    }
  });

  test('her kategoride en az 50 kart, destede en az 500 kart var', () {
    for (final id in repository.categoryNames.keys) {
      expect(
        repository.cards(categoryIds: {id}).length,
        greaterThanOrEqualTo(50),
        reason: id,
      );
    }
    expect(cards.length, greaterThanOrEqualTo(500));
  });

  test('her zorluk seviyesinde kart var', () {
    for (final difficulty in TabooDifficulty.values) {
      expect(repository.cards(difficulty: difficulty), isNotEmpty);
    }
  });

  test('her kartta tam 5 dolu, kırpılmış yasaklı kelime var', () {
    expectNoViolations([
      for (final card in cards)
        if (card.forbiddenWords.length != TabooCard.forbiddenWordCount ||
            card.forbiddenWords.any((w) => w.isEmpty || w != w.trim()) ||
            card.targetWord.isEmpty)
          '${card.targetWord}: ${card.forbiddenWords}',
    ], 'kart biçimi bozuk');
  });

  test('kart içinde aynı yasaklı kelime iki kez geçmiyor', () {
    expectNoViolations([
      for (final card in cards)
        if (card.forbiddenWords.map(normalizeTr).toSet().length !=
            card.forbiddenWords.length)
          card.targetWord,
    ], 'kart içinde tekrar');
  });

  test('yasaklı kelime hedefi, bir parçasını ya da aynı kökü içermiyor', () {
    expectNoViolations([
      for (final card in cards)
        for (final word in card.forbiddenWords)
          if (leaks(card.targetWord, word)) '${card.targetWord} → $word',
    ], 'yasaklı kelime hedefi sızdırıyor');
  });

  test('hedef kelimeler destede benzersiz', () {
    final seen = <String>{};
    expectNoViolations([
      for (final card in cards)
        if (!seen.add(normalizeTr(card.targetWord))) card.targetWord,
    ], 'hedef kelime tekrarı');
  });

  test('kart kimlikleri benzersiz', () {
    expect(cards.map((c) => c.id).toSet().length, cards.length);
  });

  test('alkol / kumar / şiddet / siyaset çağrışımlı içerik yok', () {
    const bannedParts = [
      'alkol',
      'bira',
      'rakı',
      'şarap',
      'viski',
      'votka',
      'kumar',
      'casino',
      'kumarhane',
      'silah',
      'tabanca',
      'tüfek',
      'bomba',
      'cinayet',
      'öldür',
      'ceset',
      'infaz',
      'mafya',
      'uyuşturucu',
      'sigara',
      'seksüel',
      'siyaset',
      'seçim',
      'parti lideri',
    ];
    expectNoViolations([
      for (final card in cards)
        for (final part in bannedParts)
          if ([card.targetWord, ...card.forbiddenWords]
              .map(normalizeTr)
              .any((text) => text.contains(part)))
            '${card.targetWord} ($part)',
    ], 'yasaklı içerik');
  });

  test('bozuk kart satırı açık bir hata verir', () {
    expect(
      () => LocalTabooWordRepository.parseCardLine(
        'İki nokta yok',
        id: 'x',
        categoryId: 'genel',
        difficulty: TabooDifficulty.easy,
      ),
      throwsFormatException,
    );
  });
}
