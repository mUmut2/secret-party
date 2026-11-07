import 'dart:math';

import '../../data/repositories/word_repository.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/secret_word.dart';
import 'randomization_service.dart';
import 'seen_content_tracker.dart';

/// Oyunun KURALLARINI içeren saf Dart sınıfı.
///
/// Flutter'a hiçbir bağımlılığı yok. Bu yüzden "oturum nasıl kurulur?",
/// "doğru kişi elenince kim kazanıyor?" gibi kurallar widget olmadan,
/// hızlı unit testlerle sınanabilir. State tutmaz.
class GameEngine {
  const GameEngine();

  /// Varsayılan tur süresi (saniye).
  static const int defaultRoundDurationSeconds = 180;

  /// Yeni bir oyun oturumu kurar.
  ///
  /// - [categoryId] `null` ise "Karışık": kategori rastgele seçilir.
  /// - [roundDurationSeconds] sıfırdan büyük olmalıdır.
  /// - [giveImposterHint] açıksa Imposter'a seçilen kelimenin ipucu verilir
  ///   ([GameSession.imposterHint]); kapalıysa ipucu `null` olur.
  /// - [seenContent] verilirse kelime, seçilen havuzda (kategori ya da
  ///   Karışık) daha önce görülmemişler arasından seçilir; havuz tükenince
  ///   yalnızca o havuzun geçmişi sıfırlanır.
  /// - [previousImposterId] verilirse (Tekrar Oyna) o oyuncu art arda Imposter
  ///   olmaz (tek oyuncuda kural esner).
  /// - Rastgelelik ([random]) ve kimlik ([sessionId]) dışarıdan verilir; bu
  ///   sayede testlerde sabit `Random(seed)` ile sonuç deterministik olur.
  ///
  /// Geçersiz kategori ya da süre [ArgumentError] fırlatır (bu bir
  /// programlama hatasıdır, kullanıcı hatası değil).
  GameSession createSession({
    required List<Player> players,
    required WordRepository wordRepository,
    required RandomizationService randomizationService,
    required Random random,
    required String sessionId,
    String? categoryId,
    int roundDurationSeconds = defaultRoundDurationSeconds,
    bool giveImposterHint = false,
    SeenContentTracker? seenContent,
    String? previousImposterId,
  }) {
    if (roundDurationSeconds <= 0) {
      throw ArgumentError('Tur süresi sıfırdan büyük olmalı.');
    }
    if (categoryId != null &&
        !wordRepository.categoryIds.contains(categoryId)) {
      throw ArgumentError('Bilinmeyen kategori: $categoryId');
    }

    final SecretWordEntry wordEntry = seenContent == null
        ? wordRepository.randomWord(categoryId: categoryId, random: random)
        : seenContent.pick(
            wordRepository.poolFor(categoryId),
            (entry) =>
                SeenContentTracker.imposterKey(entry.category, entry.word),
            random,
          );
    final imposterId = randomizationService.pickImposterId(
      players,
      random,
      excludeId: previousImposterId,
    );

    return GameSession(
      id: sessionId,
      players: List<Player>.unmodifiable(players),
      secretWord: wordEntry.word,
      imposterId: imposterId,
      category: wordEntry.category,
      status: GameState.roleReveal,
      roundDurationSeconds: roundDurationSeconds,
      selectedCategoryId: categoryId,
      giveImposterHint: giveImposterHint,
      imposterHint: giveImposterHint ? wordEntry.hint : null,
    );
  }

  /// Herkes rolünü gördükten sonra ipucu turunu başlatır
  /// (`roleReveal → playing`).
  ///
  /// Oturum başka bir aşamadaysa değiştirmeden döndürür; böylece çift dokunuş
  /// veya tekrar çağrı zararsızdır.
  GameSession startRound(GameSession session) {
    if (session.status != GameState.roleReveal) return session;
    return session.copyWith(status: GameState.playing);
  }

  /// Tur bittiğinde (süre doldu ya da erken bitirildi) oylamayı açar
  /// (`playing → voting`).
  ///
  /// Oturum başka bir aşamadaysa değiştirmeden döndürür.
  GameSession startVoting(GameSession session) {
    if (session.status != GameState.playing) return session;
    return session.copyWith(status: GameState.voting);
  }

  /// Elenen oyuncuya göre oyunun sonucunu hesaplar.
  ///
  /// Elenen kişi Imposter ise [GameResult.innocentsWon], değilse
  /// [GameResult.imposterWon] döner. Elenen id oyuncular arasında yoksa
  /// [ArgumentError] fırlatır.
  GameResult evaluateVote(GameSession session, String accusedPlayerId) {
    final isKnownPlayer = session.players.any((p) => p.id == accusedPlayerId);
    if (!isKnownPlayer) {
      throw ArgumentError('Elenen oyuncu bu oturumda yok: $accusedPlayerId');
    }

    return accusedPlayerId == session.imposterId
        ? GameResult.innocentsWon
        : GameResult.imposterWon;
  }

  /// Oylamayı işler ve oturumu `finished` durumuna geçirir.
  ///
  /// Oturum zaten bitmişse (örneğin butona hızlı çift dokunulduysa) aynı
  /// oturumu değiştirmeden döndürür; oy iki kez işlenmez.
  ///
  /// Oylama açılmadan oy verilirse [StateError] fırlatır (programlama hatası).
  GameSession finishWithVote(GameSession session, String accusedPlayerId) {
    if (session.status == GameState.finished) return session;
    if (session.status != GameState.voting) {
      throw StateError(
        'Oylama açık değilken oy verilemez (aşama: ${session.status.name}).',
      );
    }

    final result = evaluateVote(session, accusedPlayerId);

    return session.copyWith(
      status: GameState.finished,
      accusedPlayerId: accusedPlayerId,
      result: result,
    );
  }
}
