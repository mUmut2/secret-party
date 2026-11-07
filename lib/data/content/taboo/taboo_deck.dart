/// Bir Tabu kategorisinin kartları, zorluğa göre gruplanmış.
///
/// Her kart tek satırdır: `'Hedef: yasak1, yasak2, yasak3, yasak4, yasak5'`.
/// Satırlar `LocalTabooWordRepository` tarafından `TabooCard`'a çevrilir.
///
/// İÇERİK KURALLARI (`test/data/taboo_word_repository_test.dart` denetler):
/// - Tam 5 yasaklı kelime; kart içinde tekrar yok.
/// - Yasaklı kelime hedef kelimeyi, bir parçasını ya da aynı kökü içermez.
/// - Hedef kelimeler tüm destede benzersizdir.
/// - Yasaklı kelimeler hedefle gerçekten ilişkili, akla ilk gelen kelimelerdir.
/// - Siyaset, din, hukuki tartışma, alkol, kumar, cinsellik ve şiddet yok.
class TabooCategoryDeck {
  const TabooCategoryDeck({
    required this.easy,
    required this.medium,
    required this.hard,
  });

  final List<String> easy;
  final List<String> medium;
  final List<String> hard;
}
