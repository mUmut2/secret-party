import 'player.dart';

/// Bir oyun oturumunun aşaması.
///
/// Geçişler yalnızca ileri yönlüdür ve `GameEngine` tarafından yapılır:
/// `roleReveal → playing → voting → finished`.
enum GameState { setup, roleReveal, playing, voting, finished }

/// Oylama sonunda ortaya çıkan oyun sonucu.
///
/// - [innocentsWon]: Elenen kişi gerçekten Imposter'dı.
/// - [imposterWon]: Elenen kişi masumdu, Imposter yakalanmadı.
enum GameResult { innocentsWon, imposterWon }

/// Bir Imposter oyun oturumunun TÜM durumunu tutan immutable model.
class GameSession {
  const GameSession({
    required this.id,
    required this.players,
    required this.secretWord,
    required this.imposterId,
    required this.category,
    required this.status,
    required this.roundDurationSeconds,
    this.selectedCategoryId,
    this.giveImposterHint = false,
    this.imposterHint,
    this.accusedPlayerId,
    this.result,
  });

  final String id;
  final List<Player> players;
  final String secretWord;
  final String imposterId;

  /// Bu oyunda gerçekten kullanılan kategori (Karışık seçildiyse rastgele
  /// çıkan kategori).
  final String category;

  final GameState status;

  /// Tur süresi (saniye). "Tura Başla" sayacı bu değerle başlatılır.
  final int roundDurationSeconds;

  /// Oyuncunun kurulumda yaptığı seçim. `null` ise "Karışık" seçilmiştir.
  /// "Tekrar Oyna" aynı seçimle yeni oyun kurabilsin diye saklanır.
  final String? selectedCategoryId;

  /// Kurulumda "Imposter'a ipucu ver" seçildi mi? "Tekrar Oyna" aynı tercihle
  /// yeni oyun kurabilsin diye saklanır.
  final bool giveImposterHint;

  /// Imposter'a gösterilen tek kelimelik ipucu (ayar kapalıysa `null`).
  ///
  /// GİZLİ BİLGİDİR: yalnızca Imposter'ın rol kartında ve oyun sonunda
  /// gösterilir.
  final String? imposterHint;

  /// Grubun oylamada elediği oyuncunun id'si (oylama yapılmadıysa `null`).
  final String? accusedPlayerId;

  /// Oylama sonucu (oylama yapılmadıysa `null`).
  final GameResult? result;

  /// Imposter olan oyuncu. Oturum kurulurken id her zaman listeden seçildiği
  /// için bu arama her zaman bir sonuç bulur.
  Player get imposter => players.firstWhere((p) => p.id == imposterId);

  /// Oylama işlendi ve oyun sonuçlandı mı?
  bool get isFinished => status == GameState.finished;

  /// Oylamada elenen oyuncu (oylama yapılmadıysa `null`).
  Player? get accusedPlayer {
    final id = accusedPlayerId;
    if (id == null) return null;
    return players.where((p) => p.id == id).firstOrNull;
  }

  GameSession copyWith({
    GameState? status,
    String? accusedPlayerId,
    GameResult? result,
  }) {
    return GameSession(
      id: id,
      players: players,
      secretWord: secretWord,
      imposterId: imposterId,
      category: category,
      status: status ?? this.status,
      roundDurationSeconds: roundDurationSeconds,
      selectedCategoryId: selectedCategoryId,
      giveImposterHint: giveImposterHint,
      imposterHint: imposterHint,
      accusedPlayerId: accusedPlayerId ?? this.accusedPlayerId,
      result: result ?? this.result,
    );
  }
}
