import 'dart:math';

import '../models/bomb/bomb_game_state.dart';
import '../models/bomb/bomb_settings.dart';
import '../models/bomb/bomb_task.dart';
import '../models/player.dart';

/// Tik Tak Bomba'nın KURALLARINI içeren saf Dart sınıfı.
///
/// State tutmaz; her metot bir [BombGameState] alıp yenisini döndürür.
/// Rastgelelik dışarıdan verilir (testte `Random(seed)`). Zamanlayıcı, ses ve
/// titreşim gibi yan etkiler `BombGameNotifier`'dadır.
///
/// Kurallar:
/// - İlk turda bombayı rastgele bir oyuncu alır; sonraki turlarda bir önceki
///   turda patlayan oyuncu başlar.
/// - "GEÇİR" bombayı sıradaki oyuncuya verir (oyuncu sırasıyla, döngüsel).
/// - Gizli fitil bitince bomba kimdeyse o oyuncu patlar (+1 patlama).
/// - [BombSettings.rounds] tur oynanınca oyun biter.
class BombGameEngine {
  const BombGameEngine();

  /// Yeni oyun kurar (`ready`, 1. tur). Geçersiz oyuncu / tur sayısı
  /// [ArgumentError] fırlatır (programlama hatası; kurulum ekranı engeller).
  BombGameState createGame({
    required List<Player> players,
    required BombSettings settings,
    required BombTask firstTask,
    required Random random,
    required String gameId,
  }) {
    final error = BombSettings.validatePlayerCount(players.length);
    if (error != null) throw ArgumentError(error);
    if (!BombSettings.roundOptions.contains(settings.rounds)) {
      throw ArgumentError('Geçersiz tur sayısı: ${settings.rounds}');
    }
    return BombGameState(
      id: gameId,
      players: List.unmodifiable(players),
      settings: settings,
      phase: BombPhase.ready,
      roundNumber: 1,
      task: firstTask,
      holderIndex: random.nextInt(players.length),
      explosionCounts: Map.unmodifiable({for (final p in players) p.id: 0}),
    );
  }

  /// Bu turun gizli fitil süresi: fitil aralığından (uçlar dahil) milisaniye
  /// hassasiyetinde rastgele.
  Duration pickFuse(BombFuse fuse, Random random) {
    final minMs = fuse.minSeconds * 1000;
    final spanMs = (fuse.maxSeconds - fuse.minSeconds) * 1000;
    return Duration(milliseconds: minMs + random.nextInt(spanMs + 1));
  }

  /// İlk tik aralığı, her saniyede kısalma miktarı ve alt sınır (ms).
  static const int firstTickMs = 1000;
  static const int tickSpeedUpMsPerSecond = 12;
  static const int fastestTickMs = 350;

  /// Tik sesi / titreşimi arası süre.
  ///
  /// Tempo TURUN BAŞINDAN BERİ geçen süreye göre hafifçe hızlanır ve
  /// [fastestTickMs]'de sabitlenir. Fitilin KALAN süresine bağlı DEĞİLDİR;
  /// böylece tempodan patlama anı tahmin edilemez (her tur aynı tempoyla
  /// başlar, fitil 15 sn de olsa 70 sn de olsa aynı hızda ilerler).
  Duration tickInterval(Duration elapsedSinceRoundStart) {
    final ms =
        firstTickMs - elapsedSinceRoundStart.inSeconds * tickSpeedUpMsPerSecond;
    return Duration(milliseconds: max(ms, fastestTickMs));
  }

  /// Fitili ateşler (`ready → ticking`).
  BombGameState startRound(BombGameState state) {
    if (state.phase != BombPhase.ready) return state;
    return state.copyWith(phase: BombPhase.ticking);
  }

  /// Bombayı sıradaki oyuncuya geçirir. Yalnızca fitil yanarken etki eder.
  BombGameState passBomb(BombGameState state) {
    if (state.phase != BombPhase.ticking) return state;
    return state.copyWith(
      holderIndex: (state.holderIndex + 1) % state.players.length,
    );
  }

  /// Fitil bitti: bombayı tutan oyuncu patlar (`ticking → exploded`).
  BombGameState explode(BombGameState state) {
    if (state.phase != BombPhase.ticking) return state;
    final holderId = state.holder.id;
    return state.copyWith(
      phase: BombPhase.exploded,
      lastExplodedId: holderId,
      explosionCounts: Map.unmodifiable({
        ...state.explosionCounts,
        holderId: state.explosionsOf(holderId) + 1,
      }),
    );
  }

  /// Patlamadan sonra: son tur değilse yeni tura (`ready`), son turdaysa
  /// oyun sonuna (`finished`) geçer. Yeni turu patlayan oyuncu başlatır.
  BombGameState nextRound(BombGameState state, BombTask nextTask) {
    if (state.phase != BombPhase.exploded) return state;
    if (state.isLastRound) return state.copyWith(phase: BombPhase.finished);
    return state.copyWith(
      phase: BombPhase.ready,
      roundNumber: state.roundNumber + 1,
      task: nextTask,
    );
  }

  /// Oyun sonu özeti: sıralama, en çok patlayan(lar), hiç patlamayanlar ve
  /// son patlayan.
  BombSummary summarize(BombGameState state) {
    final order = {
      for (var i = 0; i < state.players.length; i++) state.players[i].id: i,
    };
    final standings = [
      for (final p in state.players)
        (player: p, explosions: state.explosionsOf(p.id)),
    ]..sort((a, b) {
        final byCount = b.explosions.compareTo(a.explosions);
        return byCount != 0
            ? byCount
            : order[a.player.id]!.compareTo(order[b.player.id]!);
      });

    final top = standings.isEmpty ? 0 : standings.first.explosions;
    return BombSummary(
      standings: List.unmodifiable(standings),
      mostExploded: top == 0
          ? const []
          : [
              for (final s in standings)
                if (s.explosions == top) s.player,
            ],
      neverExploded: [
        for (final s in standings)
          if (s.explosions == 0) s.player,
      ],
      lastExploded: state.lastExploded,
    );
  }
}
