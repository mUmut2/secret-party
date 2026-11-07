import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/werewolf/werewolf_game_state.dart';
import 'werewolf_game_notifier.dart';

/// Gece ve oylamadaki "telefonu sıradakine ver" akışının ekran durumu.
///
/// Telefonun KİMDE olduğu (`turnIndex`) oyun motorundadır; bu state yalnızca
/// ekranın kilidi açılmış mı, giriş ekranı geçildi mi gibi saf arayüz
/// bilgisini tutar. Faz, gün ya da sıra değişince kendiliğinden sıfırlanır;
/// böylece telefon bir sonraki oyuncuya geçtiğinde ekran HER ZAMAN kilitli
/// açılır ve önceki oyuncunun gizli bilgisi görünmez.
class WerewolfPassFlowState {
  const WerewolfPassFlowState({
    this.introSeen = false,
    this.unlockedTurn,
    this.resultsRevealed = false,
  });

  /// "Gece oldu" / "Oylama başlıyor" giriş ekranı geçildi mi?
  final bool introSeen;

  /// Kilidi açılmış sıra (`turnIndex`). Telefon başkasına geçince eşleşmez.
  final int? unlockedTurn;

  /// Oylama: tüm oylar verildikten sonra sonuçlar herkese açıldı mı?
  final bool resultsRevealed;

  bool isUnlocked(int turnIndex) => unlockedTurn == turnIndex;

  WerewolfPassFlowState copyWith({
    bool? introSeen,
    int? unlockedTurn,
    bool? resultsRevealed,
  }) {
    return WerewolfPassFlowState(
      introSeen: introSeen ?? this.introSeen,
      unlockedTurn: unlockedTurn ?? this.unlockedTurn,
      resultsRevealed: resultsRevealed ?? this.resultsRevealed,
    );
  }
}

class WerewolfPassFlowNotifier extends Notifier<WerewolfPassFlowState> {
  @override
  WerewolfPassFlowState build() {
    // Yeni oyun / yeni gün / gece ↔ oylama geçişi → akış baştan.
    ref.watch(
      werewolfGameProvider.select(
        (game) => (game?.id, game?.dayNumber, _stage(game?.phase)),
      ),
    );
    return const WerewolfPassFlowState();
  }

  /// Oylamadan sonra oyun biterse (son sürgün ya da avcı atışı) açılmış
  /// sonuçlar kapanmasın diye `gameFinished`, oylama ile aynı aşama sayılır.
  static String? _stage(WerewolfPhase? phase) {
    switch (phase) {
      case WerewolfPhase.votingPhase:
      case WerewolfPhase.gameFinished:
        return 'voting';
      case null:
        return null;
      default:
        return phase.name;
    }
  }

  void dismissIntro() => state = state.copyWith(introSeen: true);

  /// Kilitli onay butonu tamamlandı: sırası gelen oyuncu ekranı açtı.
  void unlock(WerewolfGameState game) {
    state = state.copyWith(unlockedTurn: game.turnIndex);
  }

  void revealResults() => state = state.copyWith(resultsRevealed: true);
}

final werewolfPassFlowProvider =
    NotifierProvider<WerewolfPassFlowNotifier, WerewolfPassFlowState>(
  WerewolfPassFlowNotifier.new,
);
