import 'dart:math';

import '../models/player.dart';
import '../models/spy/spy_game_state.dart';
import '../models/spy/spy_location.dart';
import '../models/spy/spy_player.dart';
import '../models/spy/spy_settings.dart';

/// Ajan (Spyfall) oyununun KURALLARINI içeren saf Dart sınıfı.
///
/// Flutter'a bağımlı değildir ve state tutmaz: her metot bir [SpyGameState]
/// alıp yenisini döndürür. Geçersiz hamleler [StateError] / [ArgumentError]
/// fırlatır; ekranlar bunlara izin vermez.
///
/// Kurallar:
/// - Rastgele bir konum seçilir. Ajan(lar) dışındaki herkes bu konumdan
///   BENZERSİZ bir rol alır. Ajan konumu bilmez.
/// - Ajan oyunu istediği an durdurup konumu tahmin edebilir:
///   doğruysa Ajan, yanlışsa Masumlar kazanır.
/// - Oylamada herkes sırayla gizli oy verir (kendine veremez):
///   - Masum biri en çok oyu alırsa ya da eşitlik olursa ajan bulunamamış
///     sayılır → Ajan kazanır.
///   - Ajan en çok oyu alırsa yakalanır ve SON ŞANS olarak konumu tahmin
///     eder: doğruysa yine Ajan, yanlışsa Masumlar kazanır.
/// - İki ajanlı oyunda ajanlar birbirini bilmez ama aynı takımdadır.
class SpyEngine {
  const SpyEngine();

  /// Konumu seçer, ajanları belirler, rolleri dağıtır ve oyunu
  /// `roleReveal` aşamasında kurar.
  SpyGameState createGame({
    required List<Player> players,
    required SpySettings settings,
    required List<SpyLocation> locations,
    required Random random,
    required String gameId,
  }) {
    final error = settings.validate(players.length);
    if (error != null) throw ArgumentError(error);
    if (locations.isEmpty) throw ArgumentError('Konum listesi boş olamaz.');

    final location = locations[random.nextInt(locations.length)];
    final innocentCount = players.length - settings.spyCount;
    if (location.roles.length < innocentCount) {
      throw ArgumentError(
        '${location.name} konumunda yeterli rol yok '
        '(${location.roles.length} < $innocentCount).',
      );
    }

    final spyIndexes = (List.generate(players.length, (i) => i)
          ..shuffle(random))
        .take(settings.spyCount)
        .toSet();
    final roles = [...location.roles]..shuffle(random);

    var roleCursor = 0;
    final spyPlayers = [
      for (var i = 0; i < players.length; i++)
        spyIndexes.contains(i)
            ? SpyPlayer(player: players[i], isSpy: true)
            : SpyPlayer(
                player: players[i],
                isSpy: false,
                roleName: roles[roleCursor++],
              ),
    ];

    return SpyGameState(
      id: gameId,
      settings: settings,
      players: List.unmodifiable(spyPlayers),
      location: location,
      allLocations: List.unmodifiable(locations),
      firstAskerId: players[random.nextInt(players.length)].id,
      phase: SpyPhase.roleReveal,
    );
  }

  /// Herkes rolünü öğrendi: soru-cevap turu başlar.
  SpyGameState startRound(SpyGameState state) {
    _requirePhase(state, SpyPhase.roleReveal);
    return state.copyWith(phase: SpyPhase.inProgress);
  }

  /// Ajan oyunu durdurup konumu tahmin etmek istiyor.
  SpyGameState startSpyGuess(SpyGameState state) {
    _requirePhase(state, SpyPhase.inProgress);
    return state.copyWith(
      phase: SpyPhase.spyGuessing,
      guessReason: SpyGuessReason.voluntary,
    );
  }

  /// Ajanın konum tahmini; oyunu bitirir.
  SpyGameState guessLocation(SpyGameState state, String locationName) {
    _requirePhase(state, SpyPhase.spyGuessing);
    if (!state.allLocations.any((l) => l.name == locationName)) {
      throw ArgumentError('Bilinmeyen konum: $locationName');
    }

    final correct = locationName == state.location.name;
    final caught = state.guessReason == SpyGuessReason.caughtByVote;
    final SpyOutcome outcome;
    if (caught) {
      outcome = correct
          ? SpyOutcome.caughtButGuessedCorrectly
          : SpyOutcome.caughtAndGuessedWrong;
    } else {
      outcome =
          correct ? SpyOutcome.spyGuessedCorrectly : SpyOutcome.spyGuessedWrong;
    }

    return state.copyWith(
      phase: SpyPhase.gameFinished,
      guessedLocationName: locationName,
      outcome: outcome,
    );
  }

  /// Bireysel gizli oylama başlar: telefon herkese oturma sırasıyla verilir.
  SpyGameState startVoting(SpyGameState state) {
    _requirePhase(state, SpyPhase.inProgress);
    return state.copyWith(
      phase: SpyPhase.voting,
      turnOrder: List.unmodifiable(state.players.map((p) => p.id)),
      turnIndex: 0,
      votes: const {},
      voteTally: const {},
    );
  }

  /// [voterId]'nin oy verebileceği kişiler: kendisi hariç herkes.
  List<SpyPlayer> voteOptions(SpyGameState state, String voterId) =>
      state.players.where((p) => p.id != voterId).toList(growable: false);

  /// Sıradaki seçmenin gizli oyu. Son oyda sayım otomatik yapılır.
  SpyGameState castVote(SpyGameState state, String voterId, String targetId) {
    _requirePhase(state, SpyPhase.voting);
    if (state.currentVoter?.id != voterId) {
      throw StateError('Oy sırası $voterId oyuncusunda değil.');
    }
    if (!voteOptions(state, voterId).any((p) => p.id == targetId)) {
      throw ArgumentError('Geçersiz oy: $targetId');
    }

    final voted = state.copyWith(
      votes: Map.unmodifiable({...state.votes, voterId: targetId}),
      turnIndex: state.turnIndex + 1,
    );
    return voted.isVoteComplete ? _tally(voted) : voted;
  }

  SpyGameState _tally(SpyGameState state) {
    final tally = <String, int>{};
    for (final id in state.votes.values) {
      tally[id] = (tally[id] ?? 0) + 1;
    }
    final top = tally.values.reduce(max);
    final leaders = tally.entries.where((e) => e.value == top).toList();
    final counted = state.copyWith(voteTally: Map.unmodifiable(tally));

    if (leaders.length > 1) {
      return counted.copyWith(
        phase: SpyPhase.gameFinished,
        outcome: SpyOutcome.voteTie,
      );
    }

    final accusedId = leaders.single.key;
    final accused = state.playerById(accusedId);
    if (!accused.isSpy) {
      return counted.copyWith(
        phase: SpyPhase.gameFinished,
        accusedId: accusedId,
        outcome: SpyOutcome.innocentAccused,
      );
    }
    // Ajan yakalandı: son şans olarak konumu tahmin edecek.
    return counted.copyWith(
      phase: SpyPhase.spyGuessing,
      accusedId: accusedId,
      guessReason: SpyGuessReason.caughtByVote,
    );
  }

  void _requirePhase(SpyGameState state, SpyPhase phase) {
    if (state.phase != phase) {
      throw StateError(
        'Bu hamle ${phase.name} aşamasında yapılır '
        '(şu an: ${state.phase.name}).',
      );
    }
  }
}
