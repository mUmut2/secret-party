import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/haptic_service.dart';
import '../../../data/repositories/spy_location_repository.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/spy/spy_game_state.dart';
import '../../../domain/models/spy/spy_settings.dart';
import '../../../domain/services/spy_engine.dart';

/// Aktif Ajan oyununu tutan ana Notifier (`null` = oyun yok).
///
/// Kuralları içermez; konum seçimi, rol dağıtımı, oy sayımı ve kazanma
/// şartları [SpyEngine]'dedir. Bu sınıf motoru çağırır, sonucu state'e yazar
/// ve dramatik anları dokunsal geri bildirimle hissettirir:
/// - Oy onayı: `mediumImpact` · Ajan yakalandı: `heavyImpact`
/// - Oyun sonu: `vibrate`
class SpyGameNotifier extends Notifier<SpyGameState?> {
  final Random _random = Random();

  @override
  SpyGameState? build() => null;

  SpyEngine get _engine => ref.read(spyEngineProvider);

  HapticService get _haptics => ref.read(hapticServiceProvider);

  /// Konumu seçer, rolleri dağıtır ve rol öğrenme aşamasına geçer.
  void startGame(List<Player> players, SpySettings settings) {
    state = _engine.createGame(
      players: players,
      settings: settings,
      locations: ref.read(spyLocationRepositoryProvider).locations,
      random: _random,
      gameId: 'spy_${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  /// Aynı oyuncular ve ayarlarla yeni oyun (yeni konum, yeni ajan).
  void restart() {
    final current = state;
    if (current == null) return;
    startGame(current.players.map((p) => p.player).toList(), current.settings);
  }

  void startRound() => _update(_engine.startRound);

  /// "Ajanım, Konumu Tahmin Edeceğim!"
  void startSpyGuess() {
    _update(_engine.startSpyGuess);
    _haptics.heavyImpact();
  }

  void guessLocation(String locationName) {
    _update((s) => _engine.guessLocation(s, locationName));
    _haptics.vibrate();
  }

  void startVoting() => _update(_engine.startVoting);

  /// Telefonu tutan seçmenin gizli oyu. Son oyda sayım otomatik yapılır.
  void castVote(String targetId) {
    final voter = state?.currentVoter;
    if (voter == null) return;
    _update((s) => _engine.castVote(s, voter.id, targetId));

    final next = state;
    if (next == null) return;
    if (next.isFinished) {
      _haptics.vibrate();
    } else if (next.phase == SpyPhase.spyGuessing) {
      _haptics.heavyImpact();
    } else {
      _haptics.mediumImpact();
    }
  }

  void quit() => state = null;

  void _update(SpyGameState Function(SpyGameState state) action) {
    final current = state;
    if (current == null) return;
    state = action(current);
  }
}

final spyEngineProvider = Provider<SpyEngine>((ref) => const SpyEngine());

final spyGameProvider = NotifierProvider<SpyGameNotifier, SpyGameState?>(
  SpyGameNotifier.new,
);
