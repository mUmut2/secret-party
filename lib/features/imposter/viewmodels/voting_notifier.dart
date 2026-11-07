import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../domain/services/game_engine_notifier.dart';
import 'voting_state.dart';

/// Şüpheli seçimini yöneten Notifier.
///
/// Sadece "grup kimi seçti?" sorusunu tutar. Seçilen kişinin Imposter olup
/// olmadığı gibi kurallar burada değil, `GameEngine`'de hesaplanır.
class VotingNotifier extends Notifier<VotingState> {
  @override
  VotingState build() {
    // Yeni oyun başlayınca (session id değişince) önceki seçim temizlenir.
    // Oylama sonucu işlenince id değişmediği için bu satır tetiklenmez.
    ref.watch(gameSessionProvider.select((session) => session?.id));
    return const VotingState();
  }

  /// Oyuncuyu şüpheli olarak işaretler (aynı anda tek şüpheli olabilir).
  void selectPlayer(String playerId) {
    if (state.selectedPlayerId == playerId) return;
    ref.read(hapticServiceProvider).selectionClick();
    state = VotingState(selectedPlayerId: playerId);
  }

  void clearSelection() {
    state = const VotingState();
  }

  /// Seçili şüpheliyi oyun motoruna bildirir ve oyunu bitirir.
  ///
  /// Oy kaydedildiyse `true`, seçim yoksa veya aktif oturum yoksa `false`
  /// döner. Ekran yalnızca `true` ise sonuç ekranına geçer. Kayıt anı güçlü
  /// bir titreşimle (`heavyImpact`) hissettirilir.
  bool confirmVote() {
    final selectedId = state.selectedPlayerId;
    if (selectedId == null) return false;
    final recorded =
        ref.read(gameSessionProvider.notifier).submitVote(selectedId);
    if (recorded) {
      ref.read(hapticServiceProvider).heavyImpact();
    }
    return recorded;
  }
}

final votingProvider = NotifierProvider<VotingNotifier, VotingState>(
  VotingNotifier.new,
);
