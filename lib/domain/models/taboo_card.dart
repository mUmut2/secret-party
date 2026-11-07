/// Tabu kartının zorluk seviyesi.
enum TabooDifficulty {
  easy('Kolay'),
  medium('Orta'),
  hard('Zor');

  const TabooDifficulty(this.label);

  /// Ekranda gösterilen Türkçe ad.
  final String label;
}

/// Tek bir Tabu kartı: anlatılacak hedef kelime ve anlatırken söylenmesi
/// yasak olan kelimeler.
class TabooCard {
  const TabooCard({
    required this.id,
    required this.targetWord,
    required this.forbiddenWords,
    required this.categoryId,
    this.difficulty = TabooDifficulty.medium,
  });

  /// Her kartta tam olarak bu kadar yasaklı kelime bulunur.
  static const int forbiddenWordCount = 5;

  /// Destede kartı benzersiz tanımlayan kimlik.
  final String id;

  /// Takım arkadaşlarının tahmin etmesi gereken kelime.
  final String targetWord;

  /// Anlatıcının söyleyemeyeceği [forbiddenWordCount] kelime.
  final List<String> forbiddenWords;

  /// Kartın ait olduğu kategori (bkz. `TabooWordRepository.categoryNames`).
  final String categoryId;

  final TabooDifficulty difficulty;

  @override
  bool operator ==(Object other) => other is TabooCard && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
