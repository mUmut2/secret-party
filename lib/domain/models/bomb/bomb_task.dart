/// Tik Tak Bomba'da bir turun görevi (örn. "Bir meyve söyle").
class BombTask {
  const BombTask({required this.categoryId, required this.prompt});

  /// Görevin kategorisi (bkz. `BombTaskRepository.categoryNames`).
  final String categoryId;

  /// Ekranda gösterilen görev cümlesi.
  final String prompt;
}
