import 'spy_location.dart';
import 'spy_player.dart';
import 'spy_settings.dart';

/// Ajan oyununun aşamaları.
///
/// Akış: `setup → roleReveal → inProgress → (spyGuessing | voting) → …
/// → gameFinished`. Oylamada ajan yakalanırsa son bir tahmin için yeniden
/// `spyGuessing`'e geçilir.
enum SpyPhase {
  setup,
  roleReveal,
  inProgress,
  spyGuessing,
  voting,
  gameFinished
}

/// Ajanın neden konum tahmini yaptığı.
enum SpyGuessReason {
  /// Ajan oyunu kendisi durdurdu.
  voluntary,

  /// Oylamada yakalandı; son şansı.
  caughtByVote,
}

/// Kazanan taraf.
enum SpyTeam {
  spies('Ajan'),
  innocents('Masumlar');

  const SpyTeam(this.label);

  final String label;
}

/// Oyunun nasıl bittiği.
enum SpyOutcome {
  spyGuessedCorrectly(
    SpyTeam.spies,
    'Ajan oyunu durdurdu ve konumu doğru tahmin etti!',
  ),
  spyGuessedWrong(
    SpyTeam.innocents,
    'Ajan oyunu durdurdu ama konumu yanlış tahmin etti.',
  ),
  caughtButGuessedCorrectly(
    SpyTeam.spies,
    'Ajan yakalandı ama son şansında konumu doğru bildi!',
  ),
  caughtAndGuessedWrong(
    SpyTeam.innocents,
    'Ajan oylamada yakalandı ve konumu da bilemedi.',
  ),
  innocentAccused(
    SpyTeam.spies,
    'Köy masum birini suçladı; ajan gölgelerde kaldı.',
  ),
  voteTie(
    SpyTeam.spies,
    'Oylar eşit dağıldı; ajan bulunamadı.',
  );

  const SpyOutcome(this.winner, this.description);

  final SpyTeam winner;
  final String description;
}

/// Bir Ajan oyununun TÜM durumunu tutan immutable model.
///
/// Kuralları içermez; geçişler `SpyEngine` tarafından üretilir.
class SpyGameState {
  const SpyGameState({
    required this.id,
    required this.settings,
    required this.players,
    required this.location,
    required this.allLocations,
    required this.firstAskerId,
    required this.phase,
    this.guessReason,
    this.guessedLocationName,
    this.turnOrder = const [],
    this.turnIndex = 0,
    this.votes = const {},
    this.voteTally = const {},
    this.accusedId,
    this.outcome,
  });

  /// Her yeni oyunda değişir; ekran akışları bunu izleyerek sıfırlanır.
  final String id;

  final SpySettings settings;
  final List<SpyPlayer> players;

  /// Bu oyunun gizli konumu.
  final SpyLocation location;

  /// Ajanın tahmin ekranında ve "Muhtemel Konumlar" rehberinde gösterilen
  /// tüm konumlar.
  final List<SpyLocation> allLocations;

  /// İlk soruyu soracak oyuncu.
  final String firstAskerId;

  final SpyPhase phase;

  final SpyGuessReason? guessReason;

  /// Ajanın tahmin ettiği konum (tahmin yapılmadıysa `null`).
  final String? guessedLocationName;

  /// Oylamada telefonun sırayla geçeceği oyuncular ve telefonun kimde olduğu.
  final List<String> turnOrder;
  final int turnIndex;

  /// Gizli oylar: seçmen id → suçladığı kişi id.
  final Map<String, String> votes;

  /// Sayım: oyuncu id → aldığı oy.
  final Map<String, int> voteTally;

  /// Oylamada en çok oyu alan (eşitlikte `null`).
  final String? accusedId;

  final SpyOutcome? outcome;

  // --- Yardımcı okuyucular ---

  List<SpyPlayer> get spies =>
      players.where((p) => p.isSpy).toList(growable: false);

  SpyPlayer get firstAsker => playerById(firstAskerId);

  SpyPlayer? get accused => tryPlayerById(accusedId);

  SpyTeam? get winner => outcome?.winner;

  bool get isFinished => phase == SpyPhase.gameFinished;

  bool get hasVoted => voteTally.isNotEmpty;

  bool get isVoteComplete => turnIndex >= turnOrder.length;

  SpyPlayer? get currentVoter =>
      isVoteComplete ? null : playerById(turnOrder[turnIndex]);

  SpyPlayer? get nextVoter => turnIndex + 1 < turnOrder.length
      ? playerById(turnOrder[turnIndex + 1])
      : null;

  SpyPlayer playerById(String id) => players.firstWhere((p) => p.id == id);

  SpyPlayer? tryPlayerById(String? id) {
    if (id == null) return null;
    return players.where((p) => p.id == id).firstOrNull;
  }

  SpyGameState copyWith({
    SpyPhase? phase,
    SpyGuessReason? guessReason,
    String? guessedLocationName,
    List<String>? turnOrder,
    int? turnIndex,
    Map<String, String>? votes,
    Map<String, int>? voteTally,
    String? accusedId,
    SpyOutcome? outcome,
  }) {
    return SpyGameState(
      id: id,
      settings: settings,
      players: players,
      location: location,
      allLocations: allLocations,
      firstAskerId: firstAskerId,
      phase: phase ?? this.phase,
      guessReason: guessReason ?? this.guessReason,
      guessedLocationName: guessedLocationName ?? this.guessedLocationName,
      turnOrder: turnOrder ?? this.turnOrder,
      turnIndex: turnIndex ?? this.turnIndex,
      votes: votes ?? this.votes,
      voteTally: voteTally ?? this.voteTally,
      accusedId: accusedId ?? this.accusedId,
      outcome: outcome ?? this.outcome,
    );
  }
}
