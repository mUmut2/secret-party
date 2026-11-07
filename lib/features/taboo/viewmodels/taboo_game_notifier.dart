import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../data/repositories/seen_content_store.dart';
import '../../../data/repositories/taboo_word_repository.dart';
import '../../../domain/models/taboo_match.dart';
import '../../../domain/models/taboo_card.dart';
import '../../../domain/models/taboo_settings.dart';
import '../../../domain/services/seen_content_tracker.dart';
import '../../../domain/services/taboo_engine.dart';

/// Aktif Tabu maçını yöneten Notifier (`null` = maç yok).
///
/// Kuralları kendisi içermez; puanlama, kart çekme ve kazanma [TabooEngine]
/// içindedir. Bu sınıf:
/// - tur zamanlayıcısını çalıştırır (bitiş zamanına göre, kaymaz),
/// - dokunsal geri bildirimi tetikler,
/// - sonucu state'e yazar.
///
/// Dokunsal geri bildirim:
/// - DOĞRU: `lightImpact` · TABU: `heavyImpact` · PAS: `selectionClick`
/// - Son 5 saniyede her saniye: `selectionClick` · Süre bitti: `vibrate`
class TabooGameNotifier extends Notifier<TabooMatch?> {
  Timer? _ticker;
  DateTime? _endsAt;
  final Random _random = Random();

  static const Duration _tickInterval = Duration(milliseconds: 250);

  /// Son kaç saniyede sayaç uyarı moduna geçer (renk + tik titreşimi).
  static const int finalCountdownSeconds = 5;

  @override
  TabooMatch? build() {
    ref.onDispose(_cancelTicker);
    return null;
  }

  TabooEngine get _engine => ref.read(tabooEngineProvider);

  HapticService get _haptics => ref.read(hapticServiceProvider);

  SeenContentTracker get _seen => ref.read(seenContentTrackerProvider);

  static String _keyOf(TabooCard card) =>
      SeenContentTracker.tabooKey(card.targetWord);

  /// Verilen ayarlarla yeni bir maç kurar (`ready` durumunda başlar).
  ///
  /// Daha önce görülmemiş kartlar önce gelir; seçili havuzun tamamı
  /// görüldüyse yalnızca bu havuzun geçmişi sıfırlanır.
  void startGame(TabooSettings settings) {
    _cancelTicker();
    final cards = ref.read(tabooWordRepositoryProvider).cards(
          categoryIds: settings.categoryIds,
          difficulty: settings.difficulty,
        );
    final seen = _seen..resetIfExhausted(cards, _keyOf);
    state = _engine.createMatch(
      settings: settings,
      cards: cards,
      random: _random,
      isSeen: (card) => seen.isSeen(_keyOf(card)),
    );
  }

  /// Ekrana gelen kartı "görüldü" olarak kaydeder.
  void _rememberCurrentCard() {
    final card = state?.currentCard;
    if (card != null) _seen.markSeen(_keyOf(card));
  }

  /// Aynı ayarlarla, skorları sıfırlayarak yeni maç başlatır.
  void restart() {
    final current = state;
    if (current == null) return;
    startGame(current.settings);
  }

  /// "Başla": aktif takımın turunu ve zamanlayıcıyı başlatır.
  void startTurn() {
    final current = state;
    if (current == null || current.status != TabooGameStatus.ready) return;

    state = _engine.startTurn(current, _random);
    _rememberCurrentCard();
    _endsAt = DateTime.now().add(
      Duration(seconds: current.settings.roundDurationSeconds),
    );
    _cancelTicker();
    _ticker = Timer.periodic(_tickInterval, (_) => _onTick());
  }

  /// DOĞRU (+1 skor).
  void markCorrect() {
    final current = state;
    if (current == null || current.status != TabooGameStatus.inProgress) {
      return;
    }
    _haptics.lightImpact();
    state = _engine.markCorrect(current, _random);
    _rememberCurrentCard();
  }

  /// TABU (−1 skor).
  void markTaboo() {
    final current = state;
    if (current == null || current.status != TabooGameStatus.inProgress) {
      return;
    }
    _haptics.heavyImpact();
    state = _engine.markTaboo(current, _random);
    _rememberCurrentCard();
  }

  /// PAS (pas hakkı varsa kartı değiştirir). Kart değiştiyse `true` döner.
  bool pass() {
    final current = state;
    if (current == null ||
        current.status != TabooGameStatus.inProgress ||
        !current.activeTeam.canPass) {
      return false;
    }
    _haptics.selectionClick();
    state = _engine.pass(current, _random);
    _rememberCurrentCard();
    return true;
  }

  /// Sonuç ekranındaki "Sırayı devret": sıradaki takım `ready` olur.
  void passTurnToNextTeam() {
    final current = state;
    if (current == null) return;
    state = _engine.passTurnToNextTeam(current);
  }

  /// Maçtan çıkış: zamanlayıcı durur, maç silinir.
  void quit() {
    _cancelTicker();
    state = null;
  }

  void _onTick() {
    final current = state;
    final endsAt = _endsAt;
    if (current == null ||
        endsAt == null ||
        current.status != TabooGameStatus.inProgress) {
      _cancelTicker();
      return;
    }

    final remainingMs = endsAt.difference(DateTime.now()).inMilliseconds;
    final remainingSeconds = remainingMs <= 0 ? 0 : (remainingMs / 1000).ceil();
    if (remainingSeconds == current.remainingSeconds) return;

    final next = _engine.tick(current, remainingSeconds);
    state = next;

    if (next.status != TabooGameStatus.inProgress) {
      _cancelTicker();
      _haptics.vibrate();
      ref.read(audioServiceProvider).alert();
    } else if (remainingSeconds <= finalCountdownSeconds) {
      _haptics.selectionClick();
    }
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}

final tabooEngineProvider = Provider<TabooEngine>((ref) {
  return const TabooEngine();
});

final tabooGameProvider = NotifierProvider<TabooGameNotifier, TabooMatch?>(
  TabooGameNotifier.new,
);
