import '../player.dart';
import 'bomb_settings.dart';
import 'bomb_task.dart';

/// Tik Tak Bomba'nın aşaması.
///
/// Akış: `ready → ticking → exploded → ready → … → finished`.
enum BombPhase { ready, ticking, exploded, finished }

/// Bir Tik Tak Bomba oyununun TÜM görünür durumu (immutable).
///
/// GİZLİLİK: Fitil süresi bu modelde BİLEREK yoktur. Süre yalnızca sayacı
/// çalıştıran notifier'ın özel alanında tutulur; böylece hiçbir ekran,
/// ilerleme çubuğu ya da ekran okuyucu etiketi kalan süreyi bilemez.
class BombGameState {
  const BombGameState({
    required this.id,
    required this.players,
    required this.settings,
    required this.phase,
    required this.roundNumber,
    required this.task,
    required this.holderIndex,
    required this.explosionCounts,
    this.lastExplodedId,
  });

  final String id;
  final List<Player> players;
  final BombSettings settings;
  final BombPhase phase;

  /// 1'den başlayan tur numarası.
  final int roundNumber;

  /// Bu turun görevi.
  final BombTask task;

  /// Bombayı şu an tutan oyuncunun [players] içindeki sırası.
  final int holderIndex;

  /// Oyuncu id → toplam patlama sayısı (her oyuncu için kayıt vardır).
  final Map<String, int> explosionCounts;

  /// En son patlayan oyuncu (henüz patlama yoksa `null`).
  final String? lastExplodedId;

  Player get holder => players[holderIndex];

  int get totalRounds => settings.rounds;

  bool get isLastRound => roundNumber >= totalRounds;

  bool get isFinished => phase == BombPhase.finished;

  Player? get lastExploded {
    final id = lastExplodedId;
    if (id == null) return null;
    return players.where((p) => p.id == id).firstOrNull;
  }

  int explosionsOf(String playerId) => explosionCounts[playerId] ?? 0;

  BombGameState copyWith({
    BombPhase? phase,
    int? roundNumber,
    BombTask? task,
    int? holderIndex,
    Map<String, int>? explosionCounts,
    String? lastExplodedId,
  }) {
    return BombGameState(
      id: id,
      players: players,
      settings: settings,
      phase: phase ?? this.phase,
      roundNumber: roundNumber ?? this.roundNumber,
      task: task ?? this.task,
      holderIndex: holderIndex ?? this.holderIndex,
      explosionCounts: explosionCounts ?? this.explosionCounts,
      lastExplodedId: lastExplodedId ?? this.lastExplodedId,
    );
  }
}

/// Final ekranındaki sıralama satırı.
typedef BombStanding = ({Player player, int explosions});

/// Oyun sonu özeti.
class BombSummary {
  const BombSummary({
    required this.standings,
    required this.mostExploded,
    required this.neverExploded,
    required this.lastExploded,
  });

  /// Çoktan aza patlama sıralaması (eşitlikte oyuncu sırası korunur).
  final List<BombStanding> standings;

  /// En çok patlayan(lar); hiç patlama yoksa boş.
  final List<Player> mostExploded;

  /// Hiç patlamayan oyuncular.
  final List<Player> neverExploded;

  /// Oyunun son patlayanı.
  final Player? lastExploded;
}
