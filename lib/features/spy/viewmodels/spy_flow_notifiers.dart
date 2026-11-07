import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../domain/models/spy/spy_game_state.dart';
import 'spy_game_notifier.dart';

// -----------------------------------------------------------------------------
// Rol öğrenme akışı
// -----------------------------------------------------------------------------

/// Rol öğrenme (pass-and-play) ekranının durumu.
///
/// Her oyuncu için: KİLİTLİ geçiş ekranı → rol kartı → "Gördüm, Telefonu
/// Ayşe'ye Ver" → sıradaki oyuncunun kilitli ekranı.
class SpyRevealState {
  const SpyRevealState({
    this.currentIndex = 0,
    this.isUnlocked = false,
    this.allRevealed = false,
  });

  final int currentIndex;
  final bool isUnlocked;
  final bool allRevealed;
}

class SpyRevealNotifier extends Notifier<SpyRevealState> {
  @override
  SpyRevealState build() {
    // Yeni oyunda (id değişince) sıra baştan başlar.
    ref.watch(spyGameProvider.select((game) => game?.id));
    return const SpyRevealState();
  }

  /// Kilitli onay tamamlandı: rol görünür. Güçlü titreşim verir.
  void unlock() {
    if (state.allRevealed || state.isUnlocked) return;
    ref.read(hapticServiceProvider).heavyImpact();
    state = SpyRevealState(currentIndex: state.currentIndex, isUnlocked: true);
  }

  /// "Gördüm": sıradaki oyuncunun KİLİTLİ ekranına geçer.
  void confirmSeen({required int totalPlayers}) {
    if (!state.isUnlocked) return;
    final isLast = state.currentIndex >= totalPlayers - 1;
    state = isLast
        ? SpyRevealState(currentIndex: state.currentIndex, allRevealed: true)
        : SpyRevealState(currentIndex: state.currentIndex + 1);
  }
}

final spyRevealProvider = NotifierProvider<SpyRevealNotifier, SpyRevealState>(
  SpyRevealNotifier.new,
);

// -----------------------------------------------------------------------------
// Oylama akışı
// -----------------------------------------------------------------------------

/// Bireysel gizli oylamanın ekran durumu (telefonun kimde olduğu motorda).
///
/// Oyunda tek oylama olduğu için yalnızca yeni oyunda sıfırlanır; sayımdan
/// sonra aşama değişse de (ajan yakalandı / oyun bitti) açılan sonuç kapanmaz.
class SpyVoteFlowState {
  const SpyVoteFlowState({
    this.introSeen = false,
    this.unlockedTurn,
    this.resultsRevealed = false,
  });

  final bool introSeen;

  /// Kilidi açılmış sıra. Telefon başkasına geçince eşleşmez → kilitli.
  final int? unlockedTurn;
  final bool resultsRevealed;

  bool isUnlocked(int turnIndex) => unlockedTurn == turnIndex;

  SpyVoteFlowState copyWith({
    bool? introSeen,
    int? unlockedTurn,
    bool? resultsRevealed,
  }) {
    return SpyVoteFlowState(
      introSeen: introSeen ?? this.introSeen,
      unlockedTurn: unlockedTurn ?? this.unlockedTurn,
      resultsRevealed: resultsRevealed ?? this.resultsRevealed,
    );
  }
}

class SpyVoteFlowNotifier extends Notifier<SpyVoteFlowState> {
  @override
  SpyVoteFlowState build() {
    ref.watch(spyGameProvider.select((game) => game?.id));
    return const SpyVoteFlowState();
  }

  void dismissIntro() => state = state.copyWith(introSeen: true);

  void unlock(SpyGameState game) =>
      state = state.copyWith(unlockedTurn: game.turnIndex);

  void revealResults() => state = state.copyWith(resultsRevealed: true);
}

final spyVoteFlowProvider =
    NotifierProvider<SpyVoteFlowNotifier, SpyVoteFlowState>(
  SpyVoteFlowNotifier.new,
);
