/// Bir oyuncuyu temsil eden, tüm oyun modlarının ortak kullanacağı model.
class Player {
  const Player({required this.id, required this.name});

  final String id;
  final String name;

  Player copyWith({String? name}) {
    return Player(id: id, name: name ?? this.name);
  }
}
