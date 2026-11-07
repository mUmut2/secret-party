import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/seen_content_store.dart';
import '../../data/repositories/word_repository.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import 'game_engine.dart';
import 'randomization_service.dart';

/// Aktif [GameSession]'ı tutan Notifier.
///
/// Kuralları kendisi içermez: oturum kurma ve oylama sonucu [GameEngine]'e,
/// kelime seçimi [WordRepository]'ye, Imposter seçimi [RandomizationService]'e
/// aittir. Bu sınıf yalnızca sonucu state'e yazar.
class GameEngineNotifier extends Notifier<GameSession?> {
  @override
  GameSession? build() => null;

  /// Verilen oyuncu listesiyle yeni bir oyun oturumu başlatır.
  ///
  /// [categoryId] `null` ise "Karışık" (rastgele kategori).
  /// [roundDurationSeconds] tur süresidir.
  /// [giveImposterHint] açıksa Imposter'a tek kelimelik ipucu verilir.
  void startGame(
    List<Player> players, {
    String? categoryId,
    int roundDurationSeconds = GameEngine.defaultRoundDurationSeconds,
    bool giveImposterHint = false,
    String? previousImposterId,
  }) {
    state = ref.read(gameEngineProvider).createSession(
          players: players,
          wordRepository: ref.read(wordRepositoryProvider),
          randomizationService: ref.read(randomizationServiceProvider),
          random: Random(),
          sessionId: _generateSessionId(),
          categoryId: categoryId,
          roundDurationSeconds: roundDurationSeconds,
          giveImposterHint: giveImposterHint,
          seenContent: ref.read(seenContentTrackerProvider),
          previousImposterId: previousImposterId,
        );
  }

  /// Herkes rolünü gördü: ipucu turu başlar (`roleReveal → playing`).
  void beginRound() {
    final current = state;
    if (current == null) return;
    state = ref.read(gameEngineProvider).startRound(current);
  }

  /// Tur bitti: oylama açılır (`playing → voting`).
  void beginVoting() {
    final current = state;
    if (current == null) return;
    state = ref.read(gameEngineProvider).startVoting(current);
  }

  /// Grubun oylamada elediği oyuncuyu işler ve oyunu bitirir.
  ///
  /// Oy kaydedildiyse (oturum `finished` durumundaysa) `true`; aktif oturum
  /// yoksa ya da oylama açık değilse `false` döner.
  bool submitVote(String accusedPlayerId) {
    final current = state;
    if (current == null) return false;
    if (current.status != GameState.voting && !current.isFinished) {
      return false;
    }

    state =
        ref.read(gameEngineProvider).finishWithVote(current, accusedPlayerId);
    return true;
  }

  /// Aynı oyuncular ve AYNI AYARLARLA (kategori seçimi, süre, ipucu) yeni bir oyun
  /// başlatır. Kelime yeniden seçilir (daha önce görülmemişlerden); bir
  /// önceki Imposter art arda Imposter olmaz.
  void restartWithSamePlayers() {
    final current = state;
    if (current == null) return;
    startGame(
      current.players,
      categoryId: current.selectedCategoryId,
      roundDurationSeconds: current.roundDurationSeconds,
      giveImposterHint: current.giveImposterHint,
      previousImposterId: current.imposterId,
    );
  }

  /// Oturumu tamamen kapatır (ana menüye dönüş / oyundan çıkış).
  ///
  /// Oturuma bağlı ekran akışları (rol gösterme, tur sayacı, oylama) oturum
  /// id'sini izlediği için kendiliğinden sıfırlanır; çalışan tur sayacı da
  /// iptal edilir.
  void endSession() => state = null;

  String _generateSessionId() =>
      'session_${DateTime.now().microsecondsSinceEpoch}';
}

final wordRepositoryProvider = Provider<WordRepository>((ref) {
  return LocalWordRepository();
});

final randomizationServiceProvider = Provider<RandomizationService>((ref) {
  return const RandomizationService();
});

final gameEngineProvider = Provider<GameEngine>((ref) {
  return const GameEngine();
});

final gameSessionProvider = NotifierProvider<GameEngineNotifier, GameSession?>(
  GameEngineNotifier.new,
);
