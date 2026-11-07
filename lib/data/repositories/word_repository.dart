import 'dart:math';

import '../../domain/models/secret_word.dart';
import '../content/imposter/imposter_categories.dart';
import '../content/imposter/imposter_word.dart';

/// Gizli kelime içeriğine erişimin TEK soyutlaması.
/// Game Engine kelimelerin nereden geldiğini (local / ileride uzak) bilmez.
abstract class WordRepository {
  /// Mevcut tüm kategori id'leri (ekranda gösterim sırasıyla).
  List<String> get categoryIds;

  /// [categoryId] verilirse o kategoriden, verilmezse (Karışık) rastgele bir
  /// kategoriden rastgele bir kelime döner.
  SecretWordEntry randomWord({String? categoryId, required Random random});

  /// Bir kategorideki tüm kayıtlar. Bilinmeyen kategoride boş liste döner.
  List<SecretWordEntry> entriesIn(String categoryId);

  /// Seçim havuzu: [categoryId] verilirse o kategorinin, `null` ise (Karışık)
  /// tüm kategorilerin kayıtları.
  List<SecretWordEntry> poolFor(String? categoryId);
}

/// Uygulama içi veri kaynağı: kelimeler `lib/data/content/imposter/`
/// altında kategori başına ayrı dosyalarda durur.
///
/// Kategori id'leri kullanıcıya gösterilen Türkçe isimlerdir (küçük harfle).
/// Gerçek JSON/asset tabanlı sisteme geçerken bu sınıfın içi değişecek,
/// [WordRepository] arayüzü ve tüketen kodlar aynı kalacak.
///
/// İÇERİK KURALLARI (`test/data/word_repository_test.dart` denetler):
/// - Her kategoride en az 100 kelime; aynı kelime iki kez geçmez (kategori
///   içinde ya da kategoriler arasında).
/// - İpucu tek kelimedir, kelimenin kendisini / bir parçasını / aynı kökü
///   içermez; kategori içinde tekrar etmez. Cins isimler küçük, özel isimler
///   Türkçe yazım kurallarına göre büyük harfle başlar.
/// - Siyasi, dini ya da hukuki açıdan tartışmalı kişi / yer / olay; alkol,
///   kumar, cinsellik ve şiddet çağrışımlı kayıt havuza eklenmez.
class LocalWordRepository implements WordRepository {
  static const Map<String, List<ImposterWord>> _wordsByCategory =
      imposterWordsByCategory;

  @override
  List<String> get categoryIds => _wordsByCategory.keys.toList();

  @override
  SecretWordEntry randomWord({String? categoryId, required Random random}) {
    final resolvedCategory =
        categoryId ?? categoryIds[random.nextInt(categoryIds.length)];

    final words = _wordsByCategory[resolvedCategory];
    if (words == null || words.isEmpty) {
      throw ArgumentError('Bilinmeyen veya boş kategori: $resolvedCategory');
    }

    final picked = words[random.nextInt(words.length)];
    return SecretWordEntry(
      category: resolvedCategory,
      word: picked.word,
      hint: picked.hint,
    );
  }

  @override
  List<SecretWordEntry> poolFor(String? categoryId) => categoryId == null
      ? [for (final id in categoryIds) ...entriesIn(id)]
      : entriesIn(categoryId);

  @override
  List<SecretWordEntry> entriesIn(String categoryId) {
    final words = _wordsByCategory[categoryId] ?? const [];
    return [
      for (final w in words)
        SecretWordEntry(category: categoryId, word: w.word, hint: w.hint),
    ];
  }
}
