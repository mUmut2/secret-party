import 'dart:math';

import '../models/player.dart';

/// Imposter seçimi gibi rastgelelik gerektiren kuralların tek merkezi.
/// Saf Dart: unit testte `Random(sabitSeed)` ile deterministik test edilebilir.
class RandomizationService {
  const RandomizationService();

  /// Oyuncu listesinden rastgele TAM 1 kişiyi Imposter olarak seçer.
  ///
  /// [excludeId] verilirse (bir önceki oyunun Imposter'ı) o kişi seçilmez;
  /// böylece "Tekrar Oyna" zincirinde aynı kişi art arda Imposter olmaz.
  /// Listede başka aday yoksa (tek oyuncu) kural esner.
  String pickImposterId(
    List<Player> players,
    Random random, {
    String? excludeId,
  }) {
    if (players.isEmpty) {
      throw ArgumentError('Imposter seçmek için en az 1 oyuncu gerekli.');
    }
    final candidates = players.where((p) => p.id != excludeId).toList();
    final pool = candidates.isEmpty ? players : candidates;
    return pool[random.nextInt(pool.length)].id;
  }
}
