import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../data/repositories/bomb_task_repository.dart';
import '../../../data/repositories/seen_content_store.dart';
import '../../../domain/models/bomb/bomb_game_state.dart';
import '../../../domain/models/bomb/bomb_settings.dart';
import '../../../domain/models/bomb/bomb_task.dart';
import '../../../domain/models/player.dart';
import '../../../domain/services/bomb_game_engine.dart';
import '../../../domain/services/seen_content_tracker.dart';

/// Şimdiki zaman kaynağı. Testlerde sahte saatle değiştirilir.
final bombClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Aktif Tik Tak Bomba oyununu ve gizli fitili yöneten Notifier
/// (`null` = oyun yok).
///
/// Kurallar [BombGameEngine]'dedir. Bu sınıf:
/// - gizli fitil süresini YALNIZCA kendi özel alanında tutar (state'te yok),
/// - fitili BİTİŞ ZAMANI üzerinden işletir; uygulama arka plana alınınca
///   [pause] ile durur, [resume] ile kaldığı yerden devam eder,
/// - tik sesini / titreşimini turun başından beri geçen süreye göre
///   hızlanan tempoyla çalar (kalan süreye göre değil),
/// - "GEÇİR"de çift dokunuşu kısa bir süre yok sayar.
///
/// Geri bildirim: tik `selectionClick` + dokunma sesi · geçir `lightImpact` ·
/// patlama `heavyImpact` + `vibrate` + uyarı sesi.
class BombGameNotifier extends Notifier<BombGameState?> {
  final Random _random = Random();

  Timer? _ticker;
  DateTime? _endsAt;
  Duration? _remainingWhilePaused;
  Duration _elapsedBeforeRun = Duration.zero;
  DateTime? _runStartedAt;
  DateTime? _nextTickAt;
  DateTime? _lastPassAt;
  int _pauseHolds = 0;

  static const Duration _checkInterval = Duration(milliseconds: 50);

  /// "GEÇİR" butonunda bu süre içindeki ikinci dokunuş yok sayılır.
  static const Duration passDebounce = Duration(milliseconds: 400);

  @override
  BombGameState? build() {
    ref.onDispose(_cancelTicker);
    return null;
  }

  BombGameEngine get _engine => ref.read(bombGameEngineProvider);

  HapticService get _haptics => ref.read(hapticServiceProvider);

  DateTime _now() => ref.read(bombClockProvider)();

  /// Fitil şu an duraklatılmış mı (uygulama arka planda)?
  bool get isPaused => _remainingWhilePaused != null;

  // --- Oyun akışı ---

  void startGame(List<Player> players, BombSettings settings) {
    _resetFuse();
    state = _engine.createGame(
      players: players,
      settings: settings,
      firstTask: _pickTask(settings.categoryId),
      random: _random,
      gameId: 'bomb_${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  /// Aynı oyuncular ve ayarlarla yeni oyun.
  void restart() {
    final current = state;
    if (current == null) return;
    startGame(current.players, current.settings);
  }

  /// "Başlat": fitil ateşlenir. Süre gizlidir ve her tur yeniden seçilir.
  void startRound() {
    final current = state;
    if (current == null || current.phase != BombPhase.ready) return;
    _resetFuse();
    final now = _now();
    final fuse = _engine.pickFuse(current.settings.fuse, _random);
    _endsAt = now.add(fuse);
    _runStartedAt = now;
    _nextTickAt = now.add(_engine.tickInterval(Duration.zero));
    state = _engine.startRound(current);
    _startTicker();
  }

  /// "GEÇİR": bomba sıradakine geçer. Geçtiyse `true` döner.
  bool passBomb() {
    final current = state;
    if (current == null || current.phase != BombPhase.ticking || isPaused) {
      return false;
    }
    final now = _now();
    final last = _lastPassAt;
    if (last != null && now.difference(last) < passDebounce) return false;
    _lastPassAt = now;
    _haptics.lightImpact();
    state = _engine.passBomb(current);
    return true;
  }

  /// Patlama ekranındaki "Sonraki Tur" / "Sonuçları Gör".
  void nextRound() {
    final current = state;
    if (current == null || current.phase != BombPhase.exploded) return;
    // Son turda yeni görev seçilmez (görülen geçmişi boşa harcanmasın).
    final task = current.isLastRound
        ? current.task
        : _pickTask(current.settings.categoryId);
    state = _engine.nextRound(current, task);
  }

  /// Oyundan çıkış: fitil durur, oyun silinir.
  void quit() {
    _resetFuse();
    state = null;
  }

  // --- Arka plan ---

  /// Fitili duraklatır: uygulama arka plana alındı (cepte patlamasın) ya da
  /// çıkış onayı açıldı.
  ///
  /// Duraklatmalar sayılır: her [pause] bir [resume] ile kapatılır ve fitil
  /// ancak tüm duraklatmalar kalkınca yeniden yanar (örn. çıkış penceresi
  /// açıkken uygulama arka plana gidip dönerse fitil yine bekler).
  void pause() {
    if (state?.phase != BombPhase.ticking) return;
    _pauseHolds++;
    if (_pauseHolds > 1) return;
    final endsAt = _endsAt;
    final runStartedAt = _runStartedAt;
    if (endsAt == null || runStartedAt == null) return;
    final now = _now();
    _cancelTicker();
    _remainingWhilePaused = endsAt.difference(now);
    _elapsedBeforeRun += now.difference(runStartedAt);
    _runStartedAt = null;
  }

  /// Bir duraklatmayı kaldırır; hiç kalmadıysa fitil kaldığı yerden devam
  /// eder.
  void resume() {
    if (_pauseHolds == 0) return;
    _pauseHolds--;
    if (_pauseHolds > 0) return;
    final remaining = _remainingWhilePaused;
    if (remaining == null || state?.phase != BombPhase.ticking) return;
    final now = _now();
    _remainingWhilePaused = null;
    _endsAt = now.add(remaining);
    _runStartedAt = now;
    _nextTickAt = now.add(_engine.tickInterval(_elapsedBeforeRun));
    _startTicker();
  }

  // --- Zamanlayıcı ---

  void _startTicker() {
    _cancelTicker();
    _ticker = Timer.periodic(_checkInterval, (_) => _onCheck());
  }

  void _onCheck() {
    final current = state;
    final endsAt = _endsAt;
    final runStartedAt = _runStartedAt;
    if (current == null ||
        current.phase != BombPhase.ticking ||
        endsAt == null ||
        runStartedAt == null) {
      _cancelTicker();
      return;
    }

    final now = _now();
    if (!now.isBefore(endsAt)) {
      _resetFuse();
      state = _engine.explode(current);
      _haptics
        ..heavyImpact()
        ..vibrate();
      ref.read(audioServiceProvider).alert();
      return;
    }

    final nextTickAt = _nextTickAt;
    if (nextTickAt != null && !now.isBefore(nextTickAt)) {
      _haptics.selectionClick();
      ref.read(audioServiceProvider).tap();
      ref.read(bombTickProvider.notifier).tick();
      final elapsed = _elapsedBeforeRun + now.difference(runStartedAt);
      _nextTickAt = now.add(_engine.tickInterval(elapsed));
    }
  }

  BombTask _pickTask(String? categoryId) {
    final tasks = ref.read(bombTaskRepositoryProvider).tasks(
          categoryId: categoryId,
        );
    return ref.read(seenContentTrackerProvider).pick(
          tasks,
          (task) => SeenContentTracker.bombKey(task.prompt),
          _random,
        );
  }

  void _resetFuse() {
    _cancelTicker();
    _endsAt = null;
    _remainingWhilePaused = null;
    _elapsedBeforeRun = Duration.zero;
    _runStartedAt = null;
    _nextTickAt = null;
    _lastPassAt = null;
    _pauseHolds = 0;
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}

/// Her tikte artan sayaç: bombanın nabız animasyonunu tetikler. Kalan süre
/// hakkında bilgi taşımaz.
class BombTickNotifier extends Notifier<int> {
  @override
  int build() {
    ref.watch(bombGameProvider.select((game) => game?.id));
    return 0;
  }

  void tick() => state++;
}

final bombGameEngineProvider = Provider<BombGameEngine>(
  (ref) => const BombGameEngine(),
);

final bombGameProvider = NotifierProvider<BombGameNotifier, BombGameState?>(
  BombGameNotifier.new,
);

final bombTickProvider = NotifierProvider<BombTickNotifier, int>(
  BombTickNotifier.new,
);
