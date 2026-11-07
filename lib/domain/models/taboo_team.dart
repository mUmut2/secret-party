/// Bir Tabu takımı: adı, toplam skoru ve O ANKİ turda kalan pas hakkı.
///
/// Pas hakkı her turun başında oyun ayarındaki limite sıfırlanır; skor ise
/// oyun boyunca birikir (Tabu cezasıyla eksiye de düşebilir).
class TabooTeam {
  const TabooTeam({
    required this.id,
    required this.name,
    this.score = 0,
    this.passesLeft = 0,
  });

  final String id;
  final String name;
  final int score;

  /// Bu takımın aktif turunda kullanabileceği kalan pas sayısı.
  final int passesLeft;

  bool get canPass => passesLeft > 0;

  TabooTeam copyWith({String? name, int? score, int? passesLeft}) {
    return TabooTeam(
      id: id,
      name: name ?? this.name,
      score: score ?? this.score,
      passesLeft: passesLeft ?? this.passesLeft,
    );
  }
}
