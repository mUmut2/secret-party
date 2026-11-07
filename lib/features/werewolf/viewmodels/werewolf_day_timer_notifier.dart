import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import 'werewolf_game_notifier.dart';

enum DayTimerStatus { idle, running, finished }

/// Gündüz tartışma sayacının durumu.
class WerewolfDayTimerState {
  const WerewolfDayTimerState({
    this.status = DayTimerStatus.idle,
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
  });

  /// Son kaç saniyede sayaç uyarı moduna geçer.
  static const int finalCountdownSeconds = 10;

  final DayTimerStatus status;
  final int totalSeconds;
  final int remainingSeconds;

  bool get isRunning => status == DayTimerStatus.running;
  bool get isFinished => status == DayTimerStatus.finished;

  bool get isFinalCountdown =>
      isRunning && remainingSeconds <= finalCountdownSeconds;

  /// 1.0 (tam süre) → 0.0 (bitti).
  double get progress =>
      totalSeconds <= 0 ? 1 : remainingSeconds / totalSeconds;
}

/// Gündüz tartışma sayacı.
///
/// Imposter tur sayacıyla aynı yaklaşım: kalan süre BİTİŞ ZAMANINDAN
/// hesaplanır, uygulama arka plana alınsa bile kaymaz. Vampir Köylü modülüne
/// özeldir; Imposter'ın `roundProvider`'ına bağımlı değildir.
/// - Son 10 saniyede her saniye `lightImpact` · Bitiş: `vibrate`
class WerewolfDayTimerNotifier extends Notifier<WerewolfDayTimerState> {
  Timer? _ticker;
  DateTime? _endsAt;

  static const Duration _tickInterval = Duration(milliseconds: 250);

  @override
  WerewolfDayTimerState build() {
    // Her yeni günde sayaç sıfırlanır.
    ref.watch(
      werewolfGameProvider.select((game) => (game?.id, game?.dayNumber)),
    );
    ref.onDispose(_cancel);
    _cancel();
    return const WerewolfDayTimerState();
  }

  HapticService get _haptics => ref.read(hapticServiceProvider);

  void start(int seconds) {
    if (state.isRunning) return;
    _cancel();
    _endsAt = DateTime.now().add(Duration(seconds: seconds));
    state = WerewolfDayTimerState(
      status: DayTimerStatus.running,
      totalSeconds: seconds,
      remainingSeconds: seconds,
    );
    _ticker = Timer.periodic(_tickInterval, (_) => _onTick());
  }

  /// Oylamaya erken geçilirse sayaç durur.
  void stop() {
    _cancel();
    if (state.isRunning) {
      state = WerewolfDayTimerState(
        status: DayTimerStatus.finished,
        totalSeconds: state.totalSeconds,
      );
    }
  }

  void _onTick() {
    final endsAt = _endsAt;
    if (endsAt == null || !state.isRunning) return;

    final remainingMs = endsAt.difference(DateTime.now()).inMilliseconds;
    if (remainingMs <= 0) {
      _cancel();
      state = WerewolfDayTimerState(
        status: DayTimerStatus.finished,
        totalSeconds: state.totalSeconds,
      );
      _haptics.vibrate();
      ref.read(audioServiceProvider).alert();
      return;
    }

    final remaining = (remainingMs / 1000).ceil();
    if (remaining == state.remainingSeconds) return;
    state = WerewolfDayTimerState(
      status: DayTimerStatus.running,
      totalSeconds: state.totalSeconds,
      remainingSeconds: remaining,
    );
    if (state.isFinalCountdown) _haptics.lightImpact();
  }

  void _cancel() {
    _ticker?.cancel();
    _ticker = null;
  }
}

final werewolfDayTimerProvider =
    NotifierProvider<WerewolfDayTimerNotifier, WerewolfDayTimerState>(
  WerewolfDayTimerNotifier.new,
);
