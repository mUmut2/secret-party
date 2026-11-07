import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import 'spy_game_notifier.dart';

enum SpyTimerStatus { idle, running, finished }

/// Soru-cevap turu sayacının durumu.
class SpyTimerState {
  const SpyTimerState({
    this.status = SpyTimerStatus.idle,
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
  });

  /// Son kaç saniyede sayaç gerilim moduna (kırmızı + nabız) geçer.
  static const int finalCountdownSeconds = 30;

  final SpyTimerStatus status;
  final int totalSeconds;
  final int remainingSeconds;

  bool get isRunning => status == SpyTimerStatus.running;
  bool get isFinished => status == SpyTimerStatus.finished;

  bool get isFinalCountdown =>
      isRunning && remainingSeconds <= finalCountdownSeconds;

  /// 1.0 (tam süre) → 0.0 (bitti).
  double get progress =>
      totalSeconds <= 0 ? 1 : remainingSeconds / totalSeconds;
}

/// Ajan tur sayacı.
///
/// Diğer oyunlardaki sayaçlarla aynı yaklaşım: kalan süre BİTİŞ ZAMANINDAN
/// hesaplanır, uygulama arka plana alınsa bile kaymaz. Ajan modülüne özeldir.
/// - Son 10 saniyede her saniye `lightImpact` · Bitiş: `vibrate`
class SpyTimerNotifier extends Notifier<SpyTimerState> {
  Timer? _ticker;
  DateTime? _endsAt;

  static const Duration _tickInterval = Duration(milliseconds: 250);
  static const int _tickHapticSeconds = 10;

  @override
  SpyTimerState build() {
    // Yeni oyunda sayaç sıfırlanır.
    ref.watch(spyGameProvider.select((game) => game?.id));
    ref.onDispose(_cancel);
    _cancel();
    return const SpyTimerState();
  }

  HapticService get _haptics => ref.read(hapticServiceProvider);

  void start(int seconds) {
    if (state.isRunning) return;
    _cancel();
    _endsAt = DateTime.now().add(Duration(seconds: seconds));
    state = SpyTimerState(
      status: SpyTimerStatus.running,
      totalSeconds: seconds,
      remainingSeconds: seconds,
    );
    _ticker = Timer.periodic(_tickInterval, (_) => _onTick());
  }

  /// Ajan tahmin ettiğinde ya da oylamaya geçildiğinde sayaç durur.
  void stop() {
    _cancel();
    if (state.isRunning) {
      state = SpyTimerState(
        status: SpyTimerStatus.finished,
        totalSeconds: state.totalSeconds,
        remainingSeconds: state.remainingSeconds,
      );
    }
  }

  void _onTick() {
    final endsAt = _endsAt;
    if (endsAt == null || !state.isRunning) return;

    final remainingMs = endsAt.difference(DateTime.now()).inMilliseconds;
    if (remainingMs <= 0) {
      _cancel();
      state = SpyTimerState(
        status: SpyTimerStatus.finished,
        totalSeconds: state.totalSeconds,
      );
      _haptics.vibrate();
      ref.read(audioServiceProvider).alert();
      return;
    }

    final remaining = (remainingMs / 1000).ceil();
    if (remaining == state.remainingSeconds) return;
    state = SpyTimerState(
      status: SpyTimerStatus.running,
      totalSeconds: state.totalSeconds,
      remainingSeconds: remaining,
    );
    if (remaining <= _tickHapticSeconds) _haptics.lightImpact();
  }

  void _cancel() {
    _ticker?.cancel();
    _ticker = null;
  }
}

final spyTimerProvider = NotifierProvider<SpyTimerNotifier, SpyTimerState>(
  SpyTimerNotifier.new,
);
