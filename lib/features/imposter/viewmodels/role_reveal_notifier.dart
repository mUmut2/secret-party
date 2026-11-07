import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../domain/services/game_engine_notifier.dart';
import 'role_reveal_state.dart';

/// Pass-and-play sırasını ve ekranın gizli/açık durumunu yönetir.
///
/// Rol açılırken güçlü bir titreşim (`heavyImpact`) verir: telefonu tutan
/// kişi ekrana bakmadan bile rolünün açıldığını hisseder.
class RoleRevealNotifier extends Notifier<RoleRevealState> {
  @override
  RoleRevealState build() {
    // Yeni oyun başlayınca (session id değişince) sıra baştan başlar.
    ref.watch(gameSessionProvider.select((session) => session?.id));
    return const RoleRevealState();
  }

  /// "Ben [Oyuncu]" butonu: o anki oyuncunun rolünü açar.
  ///
  /// Rol zaten açıksa (çift dokunuş) hiçbir şey yapmaz; titreşim de tekrar
  /// tetiklenmez.
  void revealCurrentPlayer() {
    if (state.isRevealed || state.allPlayersRevealed) return;
    ref.read(hapticServiceProvider).heavyImpact();
    state = state.copyWith(isRevealed: true);
  }

  /// Gizlilik: uygulama ön plandan çıkınca (arka plana alma, gelen çağrı,
  /// bildirim paneli) açık rol kartı kapatılır. Sıra aynı oyuncuda kalır;
  /// kartını yeniden açabilir. İşletim sisteminin uygulama değiştiricide
  /// gösterdiği ekran görüntüsünde gizli bilgi görünmez.
  void conceal() {
    if (!state.isRevealed) return;
    state = state.copyWith(isRevealed: false);
  }

  /// "Anladım, Gizle" butonu: sıradaki oyuncuya geçer ya da herkesi bitirir.
  void hideAndAdvance({required int totalPlayers}) {
    if (!state.isRevealed) return;

    final isLastPlayer = state.currentPlayerIndex >= totalPlayers - 1;

    if (isLastPlayer) {
      state = state.copyWith(isRevealed: false, allPlayersRevealed: true);
    } else {
      state = state.copyWith(
        currentPlayerIndex: state.currentPlayerIndex + 1,
        isRevealed: false,
      );
    }
  }
}

final roleRevealProvider =
    NotifierProvider<RoleRevealNotifier, RoleRevealState>(
  RoleRevealNotifier.new,
);
