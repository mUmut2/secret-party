import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../domain/services/game_engine_notifier.dart';
import 'round_state.dart';

/// Tur süresini yöneten Notifier.
///
/// Kalan süre "her saniye 1 azalt" ile değil, BİTİŞ ZAMANI üzerinden
/// hesaplanır. Timer gecikse veya uygulama arka plana alınsa bile sayaç
/// gerçek zamandan sapmaz. State sadece saniye değişince güncellenir.
///
/// Dokunsal geri bildirim de burada tetiklenir (ekranda değil): böylece
/// titreşim, ekran o an çizilmese bile süreyle birebir senkron kalır.
/// - Son 10 saniyede her saniye: `lightImpact` (kalp atışı)
/// - Süre bittiğinde: `vibrate`
class RoundNotifier extends Notifier<RoundState> {
  Timer? _ticker;
  DateTime? _endsAt;

  static const Duration _tickInterval = Duration(milliseconds: 250);

  @override
  RoundState build() {
    // Yeni oyun başlayınca (session id değişince) tur durumu sıfırlanır.
    ref.watch(gameSessionProvider.select((session) => session?.id));
    ref.onDispose(_cancelTicker);
    return const RoundState();
  }

  HapticService get _haptics => ref.read(hapticServiceProvider);

  /// Yeni bir tur başlatır. Önceki sayaç varsa iptal edilir.
  void start({int durationSeconds = RoundState.defaultDurationSeconds}) {
    _cancelTicker();
    _endsAt = DateTime.now().add(Duration(seconds: durationSeconds));
    state = RoundState(
      status: RoundStatus.running,
      totalSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
    );
    _ticker = Timer.periodic(_tickInterval, (_) => _onTick());
  }

  /// "Oylamaya Geç": süre dolmadan turu bitirir. Sadece tur çalışırken
  /// etki eder; çift dokunuş zararsızdır.
  void endEarly() {
    if (!state.isRunning) return;
    _cancelTicker();
    state = state.copyWith(status: RoundStatus.endedEarly);
  }

  /// Turu sessizce durdurur (oyundan çıkış). Titreşim / ses tetiklenmez.
  void stop() {
    _cancelTicker();
    if (state.isRunning) {
      state = state.copyWith(status: RoundStatus.endedEarly);
    }
  }

  void _onTick() {
    final endsAt = _endsAt;
    if (endsAt == null || !state.isRunning) return;

    final remainingMs = endsAt.difference(DateTime.now()).inMilliseconds;

    if (remainingMs <= 0) {
      _cancelTicker();
      state = state.copyWith(
        remainingSeconds: 0,
        status: RoundStatus.timeUp,
      );
      _haptics.vibrate();
      ref.read(audioServiceProvider).alert();
      return;
    }

    final remainingSeconds = (remainingMs / 1000).ceil();
    if (remainingSeconds != state.remainingSeconds) {
      state = state.copyWith(remainingSeconds: remainingSeconds);
      if (state.isFinalCountdown) {
        _haptics.lightImpact();
      }
    }
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}

final roundProvider = NotifierProvider<RoundNotifier, RoundState>(
  RoundNotifier.new,
);
