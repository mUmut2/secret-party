import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/werewolf/werewolf_game_state.dart';
import '../../../domain/models/werewolf/werewolf_settings.dart';
import '../../../domain/services/werewolf_engine.dart';

/// Aktif Vampir Köylü oyununu tutan ana Notifier (`null` = oyun yok).
///
/// Kuralları içermez; gece sonucu, oy sayımı, avcı kurşunu ve zafer
/// şartları [WerewolfEngine]'dedir. Gece ve oylama hamleleri her zaman
/// TELEFONU O AN TUTAN oyuncu adına yapılır (`currentTurnPlayer`).
///
/// Dokunsal geri bildirim:
/// - Gece hamlesi / oy onayı: `mediumImpact` · Kâhin sorgusu: `heavyImpact`
/// - Sabah ölüm haberi / sürgün / avcı atışı: `heavyImpact`
/// - Sakin gece: `lightImpact` · Oyun sonu: `vibrate`
class WerewolfGameNotifier extends Notifier<WerewolfGameState?> {
  final Random _random = Random();

  @override
  WerewolfGameState? build() => null;

  WerewolfEngine get _engine => ref.read(werewolfEngineProvider);

  HapticService get _haptics => ref.read(hapticServiceProvider);

  /// Rolleri dağıtır ve rol öğrenme fazına (`roleReveal`) geçer.
  void startGame(List<Player> players, WerewolfSettings settings) {
    state = _engine.createGame(
      players: players,
      settings: settings,
      random: _random,
      gameId: 'werewolf_${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  /// Aynı oyuncular ve ayarlarla, roller yeniden dağıtılarak yeni oyun.
  void restart() {
    final current = state;
    if (current == null) return;
    startGame(current.players.map((p) => p.player).toList(), current.settings);
  }

  // --- Gece ---

  void startNight() => _update(_engine.startNight);

  void vampireVote(String targetId) {
    _update((s) => _engine.vampireVote(s, _currentId(s), targetId));
    _haptics.mediumImpact();
  }

  void doctorProtect(String targetId) {
    _update((s) => _engine.doctorProtect(s, _currentId(s), targetId));
    _haptics.mediumImpact();
  }

  void witchAct({String? healTargetId, String? poisonTargetId}) {
    _update(
      (s) => _engine.witchAct(
        s,
        _currentId(s),
        healTargetId: healTargetId,
        poisonTargetId: poisonTargetId,
      ),
    );
    _haptics.mediumImpact();
  }

  void seerInspect(String targetId) {
    _update((s) => _engine.seerInspect(s, _currentId(s), targetId));
    _haptics.heavyImpact();
  }

  /// "Devam Et (Telefonu Sonrakine Ver)".
  void completeNightTurn() => _update(_engine.completeNightTurn);

  /// "Sabahı Getir": gecenin sonucu hesaplanır.
  void resolveNight() {
    _update((s) => _engine.resolveNight(s, _random));
    final next = state;
    if (next == null) return;
    if (next.lastNightDeaths.isEmpty) {
      _haptics.lightImpact();
    } else {
      _haptics.heavyImpact();
    }
    _vibrateIfFinished(next);
  }

  // --- Avcı ---

  void hunterShoot(String targetId) {
    _update((s) => _engine.hunterShoot(s, targetId));
    _haptics.heavyImpact();
    _vibrateIfFinished(state);
  }

  void hunterHoldFire() {
    _update(_engine.hunterHoldFire);
    _vibrateIfFinished(state);
  }

  // --- Gündüz oylaması ---

  void startVoting() => _update(_engine.startVoting);

  /// Telefonu tutan seçmenin gizli oyu. Son oyda sayım otomatik yapılır.
  void castVote(String targetId) {
    _update((s) => _engine.castVote(s, _currentId(s), targetId, _random));
    final next = state;
    if (next == null) return;
    if (next.voteResolved && next.lastExiledId != null) {
      _haptics.heavyImpact();
    } else {
      _haptics.mediumImpact();
    }
    _vibrateIfFinished(next);
  }

  /// Oyundan çıkış.
  void quit() => state = null;

  String _currentId(WerewolfGameState s) {
    final current = s.currentTurnPlayer;
    if (current == null) throw StateError('Telefon kimsede değil.');
    return current.id;
  }

  void _update(WerewolfGameState Function(WerewolfGameState state) action) {
    final current = state;
    if (current == null) return;
    state = action(current);
  }

  void _vibrateIfFinished(WerewolfGameState? next) {
    if (next?.isFinished ?? false) _haptics.vibrate();
  }
}

final werewolfEngineProvider = Provider<WerewolfEngine>((ref) {
  return const WerewolfEngine();
});

final werewolfGameProvider =
    NotifierProvider<WerewolfGameNotifier, WerewolfGameState?>(
  WerewolfGameNotifier.new,
);
