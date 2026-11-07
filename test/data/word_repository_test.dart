import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/core/utils/turkish_text.dart';
import 'package:party_game/data/repositories/word_repository.dart';
import 'package:party_game/domain/models/secret_word.dart';
import 'package:party_game/features/settings/utils/settings_labels.dart';

import '../support/content_rules.dart';

/// Imposter kelime havuzunun içerik kurallarını denetler.
///
/// Karşılaştırmalar Türkçe büyük/küçük harf (I/ı, İ/i) ve şapkalı harf
/// (â, î, û) farkları gözetilerek yapılır.
void main() {
  final repository = LocalWordRepository();
  final categories = repository.categoryIds;
  final allEntries = [
    for (final id in categories) ...repository.entriesIn(id),
  ];

  String normalize(String text) => normalizeTr(text);

  group('denetim kuralları gerçekten hata yakalıyor', () {
    test('kötü örnekler yakalanır', () {
      expect(leaks('Simit', 'simitçi'), isTrue);
      expect(leaks('Futbolcu', 'futbol'), isTrue);
      expect(leaks('Taksici', 'taksimetre'), isTrue);
      expect(leaks('Hâkim', 'hakimlik'), isTrue);
      expect(leaks('Kara Şövalye', 'şövalyelik'), isTrue);
      expect(leaks('İnek', 'İNEKLER'), isTrue, reason: 'Türkçe İ/i eşleşmesi');
      expect(leaks('Işık', 'ışıklı'), isTrue, reason: 'Türkçe I/ı eşleşmesi');
      expect('doktor aleti'.contains(RegExp(r'\s')), isTrue);
    });

    test('iyi örnekler geçer', () {
      expect(leaks('Penguen', 'buz'), isFalse);
      expect(leaks('Kapadokya', 'balon'), isFalse);
      expect(leaks('Lionel Messi', 'Arjantin'), isFalse);
    });
  });

  group('kelime havuzu', () {
    test('12-15 kategori, her kategoride en az 100 kelime, toplam 1500+', () {
      expect(categories.length, inInclusiveRange(12, 15));
      for (final id in categories) {
        expect(
          repository.entriesIn(id).length,
          greaterThanOrEqualTo(100),
          reason: id,
        );
      }
      expect(allEntries.length, greaterThanOrEqualTo(1500));
    });

    test('ilk altı kategoride en az 120 kelime var', () {
      for (final id in [
        'hayvanlar',
        'mekanlar',
        'filmler',
        'yemekler',
        'meslekler',
        'ünlüler',
      ]) {
        expect(
          repository.entriesIn(id).length,
          greaterThanOrEqualTo(120),
          reason: id,
        );
      }
    });

    test('kelime boş değil ve baş/son boşluk içermiyor', () {
      for (final entry in allEntries) {
        expect(entry.word, isNotEmpty);
        expect(entry.word, entry.word.trim(), reason: entry.word);
      }
    });

    test('aynı kategoride aynı kelime iki kez geçmiyor', () {
      for (final id in categories) {
        final words = repository.entriesIn(id).map((e) => normalize(e.word));
        final seen = <String>{};
        final duplicates = words.where((w) => !seen.add(w)).toList();
        expect(duplicates, isEmpty, reason: '$id kategorisinde tekrar');
      }
    });

    test('aynı kelime iki farklı kategoride geçmiyor', () {
      final owner = <String, String>{};
      final conflicts = <String>[];
      for (final entry in allEntries) {
        final key = normalize(entry.word);
        final previous = owner[key];
        if (previous != null && previous != entry.category) {
          conflicts.add('${entry.word}: $previous / ${entry.category}');
        }
        owner[key] = entry.category;
      }
      expect(conflicts, isEmpty);
    });

    test('siyasi / dini / hukuki açıdan hassas kayıtlar havuzda yok', () {
      const banned = [
        // Kişiler
        'atatürk', 'hakan şükür', 'ezhel', 'fatih terim', 'johnny depp',
        'michael jackson', 'will smith', 'diego maradona', 'kenan sofuoğlu',
        'fazıl say', 'orhan pamuk', 'yaşar kemal', 'cem karaca',
        // Dini / siyasi açıdan hassas yerler
        'ayasofya', 'sümela manastırı', 'anıtkabir', 'taksim meydanı',
        'las vegas', 'vatikan', 'israil', 'filistin',
        // Siyasi boykot tartışmalarında sık geçen markalar
        'coca-cola', 'starbucks', "mcdonald's",
        // Şiddet / suç çağrışımlı filmler
        'kuzuların sessizliği', 'dövüş kulübü', 'yeşil yol', 'baba',
        'joker', 'kurtlar vadisi', 'çukur',
      ];
      final words = allEntries.map((e) => normalize(e.word)).toSet();
      for (final name in banned) {
        expect(words, isNot(contains(name)), reason: name);
      }
    });

    test('alkol / kumar / şiddet çağrışımlı kelime ve ipucu yok', () {
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
        'seks',
      ];
      for (final entry in allEntries) {
        final text = '${normalize(entry.word)} ${normalize(entry.hint)}';
        for (final part in bannedParts) {
          expect(
            text.contains(part),
            isFalse,
            reason: '${entry.word} → ${entry.hint} ($part)',
          );
        }
      }
    });

    test('kategori adları ayarlar ekranında okunur biçimde gösterilir', () {
      for (final id in categories) {
        final label = categoryLabel(id);
        expect(label, isNotEmpty);
        expect(label[0], label[0].toUpperTr(), reason: label);
        expect(label.substring(1), id.substring(1));
      }
    });

    test('rastgele kelime ipucuyla birlikte döner', () {
      final entry = repository.randomWord(random: Random(1));
      expect(entry.hint, isNotEmpty);
      expect(
        repository.entriesIn(entry.category).map((e) => e.word),
        contains(entry.word),
      );
    });
  });

  group('ipuçları', () {
    void expectAll(
      bool Function(SecretWordEntry entry) isValid,
      String rule,
    ) {
      final violations = [
        for (final entry in allEntries)
          if (!isValid(entry)) '${entry.word} → "${entry.hint}"',
      ];
      expect(violations, isEmpty, reason: rule);
    }

    test('ipucu boş değil ve baş/son boşluk içermiyor', () {
      expectAll(
        (e) => e.hint.isNotEmpty && e.hint == e.hint.trim(),
        'ipucu boş ya da kırpılmamış',
      );
    });

    test('ipucu tek kelime (boşluk içermiyor)', () {
      expectAll(
        (e) => !e.hint.contains(RegExp(r'\s')),
        'ipucu birden fazla kelime',
      );
    });

    test('ipucu kelimeyi, bir parçasını ya da aynı kökü içermiyor', () {
      expectAll(
        (e) => !leaks(e.word, e.hint),
        'ipucu kelimeyi sızdırıyor',
      );
    });

    test('aynı kategoride iki kelimenin ipucu aynı değil', () {
      for (final id in categories) {
        final hints = repository.entriesIn(id).map((e) => normalize(e.hint));
        final seen = <String>{};
        final duplicates = hints.where((h) => !seen.add(h)).toList();
        expect(duplicates, isEmpty, reason: '$id kategorisinde aynı ipucu');
      }
    });
  });
}
