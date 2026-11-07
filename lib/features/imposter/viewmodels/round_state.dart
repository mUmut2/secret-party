/// Bir oyun turunun (ipucu aşamasının) yaşam döngüsü.
///
/// - [idle]: tur başlamadı
/// - [running]: süre akıyor
/// - [timeUp]: süre kendiliğinden bitti
/// - [endedEarly]: oyuncular "Oylamaya Geç" dedi
enum RoundStatus { idle, running, timeUp, endedEarly }

/// Round ekranının okuduğu immutable state.
class RoundState {
  const RoundState({
    this.status = RoundStatus.idle,
    this.totalSeconds = defaultDurationSeconds,
    this.remainingSeconds = defaultDurationSeconds,
  });

  /// Varsayılan tur süresi (3 dakika). İleride ayarlardan gelecek.
  static const int defaultDurationSeconds = 180;

  /// Son kaç saniyede "gerilim modu" devreye girer.
  static const int finalCountdownSeconds = 10;

  final RoundStatus status;
  final int totalSeconds;
  final int remainingSeconds;

  bool get isRunning => status == RoundStatus.running;

  bool get isFinished =>
      status == RoundStatus.timeUp || status == RoundStatus.endedEarly;

  bool get isFinalCountdown =>
      isRunning && remainingSeconds <= finalCountdownSeconds;

  /// 1.0 (tam süre) → 0.0 (süre bitti).
  double get progress =>
      totalSeconds <= 0 ? 0 : remainingSeconds / totalSeconds;

  RoundState copyWith({
    RoundStatus? status,
    int? totalSeconds,
    int? remainingSeconds,
  }) {
    return RoundState(
      status: status ?? this.status,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}
