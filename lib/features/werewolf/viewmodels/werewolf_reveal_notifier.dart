import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import 'werewolf_game_notifier.dart';

/// Rol öğrenme (pass-and-play) ekranının durumu.
///
/// Her oyuncu için akış: KİLİTLİ geçiş ekranı ("Telefonu Ayşe'ye Ver") →
/// basılı tutarak rol kartı → "Rolümü Gördüm" → sıradaki oyuncunun kilitli
/// geçiş ekranı.
class WerewolfRevealState {
  const WerewolfRevealState({
    this.currentIndex = 0,
    this.isUnlocked = false,
    this.isPeeking = false,
    this.hasSeenRole = false,
    this.allRevealed = false,
  });

  /// Sırası gelen oyuncunun index'i.
  final int currentIndex;

  /// Sıradaki oyuncu kilitli onayı geçti mi?
  final bool isUnlocked;

  /// Oyuncu şu an karta basılı tutuyor mu (rol görünür mü)?
  final bool isPeeking;

  /// Rolünü en az bir kez gördü mü? Görmeden "Rolümü Gördüm" açılmaz.
  final bool hasSeenRole;

  final bool allRevealed;

  WerewolfRevealState copyWith({
    bool? isUnlocked,
    bool? isPeeking,
    bool? hasSeenRole,
    bool? allRevealed,
  }) {
    return WerewolfRevealState(
      currentIndex: currentIndex,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isPeeking: isPeeking ?? this.isPeeking,
      hasSeenRole: hasSeenRole ?? this.hasSeenRole,
      allRevealed: allRevealed ?? this.allRevealed,
    );
  }
}

/// Rol öğrenme akışını yönetir. Rol açıldığı an güçlü titreşim verir.
class WerewolfRevealNotifier extends Notifier<WerewolfRevealState> {
  @override
  WerewolfRevealState build() {
    // Yeni oyunda (id değişince) sıra baştan başlar.
    ref.watch(werewolfGameProvider.select((game) => game?.id));
    return const WerewolfRevealState();
  }

  /// Kilitli geçiş onayı tamamlandı.
  void unlock() {
    if (state.allRevealed) return;
    state = state.copyWith(isUnlocked: true);
  }

  /// Parmak karta bastı: rol görünür.
  void startPeek() {
    if (!state.isUnlocked || state.isPeeking || state.allRevealed) return;
    ref.read(hapticServiceProvider).heavyImpact();
    state = state.copyWith(isPeeking: true, hasSeenRole: true);
  }

  /// Parmak kalktı: rol tekrar gizlenir.
  void endPeek() {
    if (!state.isPeeking) return;
    state = state.copyWith(isPeeking: false);
  }

  /// "Rolümü Gördüm": sıradaki oyuncunun KİLİTLİ ekranına geçer.
  void confirmSeen({required int totalPlayers}) {
    if (!state.hasSeenRole || state.isPeeking) return;
    final isLast = state.currentIndex >= totalPlayers - 1;
    state = isLast
        ? state.copyWith(allRevealed: true, isUnlocked: false)
        : WerewolfRevealState(currentIndex: state.currentIndex + 1);
  }
}

final werewolfRevealProvider =
    NotifierProvider<WerewolfRevealNotifier, WerewolfRevealState>(
  WerewolfRevealNotifier.new,
);
