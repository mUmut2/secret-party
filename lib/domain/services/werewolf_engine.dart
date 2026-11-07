import 'dart:math';

import '../models/player.dart';
import '../models/werewolf/werewolf_game_state.dart';
import '../models/werewolf/werewolf_player.dart';
import '../models/werewolf/werewolf_role.dart';
import '../models/werewolf/werewolf_settings.dart';

/// Bir oyuncunun kendi gece sırasında yapabileceği şey.
enum WerewolfNightAbility {
  /// Vampir: avlanacak kişiye oy verir (zorunlu).
  vampireHunt,

  /// Doktor: bir kişiyi korur (zorunlu).
  doctorProtect,

  /// Cadı: en az bir iksiri kaldıysa iyileştirir / zehirler (isteğe bağlı).
  witchPotions,

  /// Kâhin: tek sorgu hakkı duruyorsa bir rolü öğrenir (isteğe bağlı).
  seerInspect,

  /// Avcı: gece hamlesi yok; kurşunu elendiğinde kullanılır.
  hunterStandby,

  /// Köylü ya da hakkı bitmiş özel rol.
  none,
}

/// Vampir Köylü oyununun KURALLARINI içeren saf Dart sınıfı.
///
/// Flutter'a bağımlı değildir ve state tutmaz: her metot bir
/// [WerewolfGameState] alıp yenisini döndürür. Geçersiz hamleler (yanlış faz,
/// sırası olmayan oyuncu, ölü hedef, bitmiş hak) programlama hatasıdır ve
/// [StateError] / [ArgumentError] fırlatır; ekranlar bunlara izin vermez.
///
/// SIRALI TEK TELEFON: Gece ve oylamada telefon, fazın başında yaşayan HER
/// oyuncunun eline oturma sırasıyla geçer ([WerewolfGameState.turnOrder]).
/// Böylece telefonu kimin aldığından rolü anlaşılmaz.
///
/// Gece kuralları:
/// - Her vampir kendi sırasında gizlice bir hedef seçer; en çok seçilen kişi
///   saldırıya uğrar (eşitlikte kura).
/// - Doktor bir kişiyi korur (kendisi dahil); aynı kişiyi art arda iki gece
///   koruyamaz.
/// - Cadı tek kullanımlık iyileştirme iksirini bir kişiye verirse o kişi bu
///   gece vampir saldırısından kurtulur; tek kullanımlık zehri bir kişiyi
///   öldürür (doktor koruması zehri durdurmaz).
/// - Kâhin oyun boyunca TEK KEZ bir oyuncunun rolünü öğrenir.
/// - Avcının oyun boyunca tek kurşunu vardır; elendiği an isterse yaşayan
///   bir kişiyi vurur. Zafer kontrolü bu karardan SONRA yapılır.
///
/// Gündüz: yaşayan herkes sırayla gizli oy verir (kendisine veremez). En çok
/// oy alan sürgün edilir; eşitlikte ayara göre kimse elenmez ya da kura çekilir.
///
/// Zafer: yaşayan vampir yoksa Köylüler; yaşayan vampir sayısı yaşayan köylü
/// sayısına eşit ya da fazlaysa Vampirler kazanır.
class WerewolfEngine {
  const WerewolfEngine();

  /// Rolleri karıştırıp dağıtır ve oyunu `roleReveal` fazında kurar.
  WerewolfGameState createGame({
    required List<Player> players,
    required WerewolfSettings settings,
    required Random random,
    required String gameId,
  }) {
    final error = settings.validate(players.length);
    if (error != null) throw ArgumentError(error);

    final roles = settings.roleDeck(players.length)..shuffle(random);
    return WerewolfGameState(
      id: gameId,
      settings: settings,
      players: List.unmodifiable([
        for (var i = 0; i < players.length; i++)
          WerewolfPlayer(player: players[i], role: roles[i]),
      ]),
      phase: WerewolfPhase.roleReveal,
    );
  }

  // ---------------------------------------------------------------------------
  // Gece
  // ---------------------------------------------------------------------------

  /// Yeni bir gece başlatır: telefon yaşayan herkesin eline sırayla geçecek.
  WerewolfGameState startNight(WerewolfGameState state) {
    final fromReveal = state.phase == WerewolfPhase.roleReveal;
    final fromVote = state.phase == WerewolfPhase.votingPhase &&
        state.voteResolved &&
        !state.hasPendingHunterDecision;
    if (!fromReveal && !fromVote) {
      throw StateError('Gece şu fazda başlatılamaz: ${state.phase.name}');
    }

    return state.copyWith(
      phase: WerewolfPhase.nightPhase,
      dayNumber: state.dayNumber + 1,
      turnOrder: _aliveIds(state),
      turnIndex: 0,
      nightActions: const WerewolfNightActions(),
      players: _mapPlayers(
        state,
        (p) =>
            p.copyWith(isProtectedByDoctor: false, isTargetedByVampires: false),
      ),
      lastNightDeaths: const [],
      someoneSavedLastNight: false,
      votes: const {},
      voteResolved: false,
      voteTally: const {},
      voteWasTie: false,
      clearLastExiled: true,
    );
  }

  /// [player]'ın bu gece kendi sırasında yapabileceği şey.
  WerewolfNightAbility nightAbilityOf(
    WerewolfGameState state,
    WerewolfPlayer player,
  ) {
    switch (player.role) {
      case WerewolfRole.vampir:
        return WerewolfNightAbility.vampireHunt;
      case WerewolfRole.doktor:
        return WerewolfNightAbility.doctorProtect;
      case WerewolfRole.cadi:
        return state.witchHealAvailable || state.witchPoisonAvailable
            ? WerewolfNightAbility.witchPotions
            : WerewolfNightAbility.none;
      case WerewolfRole.kahin:
        // Hakkını bu gece kullandıysa sonucu görmeye devam eder.
        return state.seerAvailable || state.nightActions.seerInspectedId != null
            ? WerewolfNightAbility.seerInspect
            : WerewolfNightAbility.none;
      case WerewolfRole.avci:
        return WerewolfNightAbility.hunterStandby;
      case WerewolfRole.koylu:
        return WerewolfNightAbility.none;
    }
  }

  /// Vampirlerin seçebileceği hedefler: yaşayan köylü takımı.
  List<WerewolfPlayer> vampireTargetOptions(WerewolfGameState state) =>
      state.aliveVillagers;

  /// Doktorun koruyabileceği kişiler: dün gece koruduğu hariç tüm yaşayanlar.
  List<WerewolfPlayer> doctorOptions(WerewolfGameState state) =>
      state.alivePlayers
          .where((p) => p.id != state.lastDoctorProtectedId)
          .toList(growable: false);

  /// Cadının iyileştirebileceği kişiler: tüm yaşayanlar (kendisi dahil).
  List<WerewolfPlayer> witchHealOptions(WerewolfGameState state) =>
      state.alivePlayers;

  /// Cadının zehirleyebileceği kişiler: kendisi hariç tüm yaşayanlar.
  List<WerewolfPlayer> witchPoisonOptions(
    WerewolfGameState state,
    String witchId,
  ) =>
      state.alivePlayers.where((p) => p.id != witchId).toList(growable: false);

  /// Kâhinin sorgulayabileceği kişiler: kendisi hariç tüm yaşayanlar.
  List<WerewolfPlayer> seerOptions(WerewolfGameState state, String seerId) =>
      state.alivePlayers.where((p) => p.id != seerId).toList(growable: false);

  /// Vampir [vampireId]'nin gizli av oyu.
  WerewolfGameState vampireVote(
    WerewolfGameState state,
    String vampireId,
    String targetId,
  ) {
    _requireNightTurn(state, vampireId, WerewolfRole.vampir);
    if (!vampireTargetOptions(state).any((p) => p.id == targetId)) {
      throw ArgumentError('Geçersiz vampir hedefi: $targetId');
    }
    return state.copyWith(
      nightActions: state.nightActions.copyWith(
        vampireVotes: Map.unmodifiable({
          ...state.nightActions.vampireVotes,
          vampireId: targetId,
        }),
      ),
    );
  }

  WerewolfGameState doctorProtect(
    WerewolfGameState state,
    String doctorId,
    String targetId,
  ) {
    _requireNightTurn(state, doctorId, WerewolfRole.doktor);
    if (!doctorOptions(state).any((p) => p.id == targetId)) {
      throw ArgumentError('Geçersiz koruma hedefi: $targetId');
    }
    return state.copyWith(
      nightActions: state.nightActions.copyWith(doctorProtectedId: targetId),
      players: _mapPlayers(
        state,
        (p) => p.copyWith(isProtectedByDoctor: p.id == targetId),
      ),
    );
  }

  /// Cadının bu geceki kararı. İkisi de boş bırakılabilir; ikisi birden
  /// de kullanılabilir.
  WerewolfGameState witchAct(
    WerewolfGameState state,
    String witchId, {
    String? healTargetId,
    String? poisonTargetId,
  }) {
    _requireNightTurn(state, witchId, WerewolfRole.cadi);
    if (healTargetId != null) {
      if (!state.witchHealAvailable) {
        throw StateError('İyileştirme iksiri zaten kullanıldı.');
      }
      if (!witchHealOptions(state).any((p) => p.id == healTargetId)) {
        throw ArgumentError('Geçersiz iyileştirme hedefi: $healTargetId');
      }
    }
    if (poisonTargetId != null) {
      if (!state.witchPoisonAvailable) {
        throw StateError('Zehir iksiri zaten kullanıldı.');
      }
      if (!witchPoisonOptions(state, witchId)
          .any((p) => p.id == poisonTargetId)) {
        throw ArgumentError('Geçersiz zehir hedefi: $poisonTargetId');
      }
    }
    return state.copyWith(
      nightActions: state.nightActions.copyWith(
        witchHealTargetId: healTargetId,
        witchPoisonTargetId: poisonTargetId,
      ),
    );
  }

  /// Kâhinin tek sorgusu. Hak HEMEN tükenir; sonuç
  /// `nightActions.seerInspectedId` üzerinden okunur.
  WerewolfGameState seerInspect(
    WerewolfGameState state,
    String seerId,
    String targetId,
  ) {
    _requireNightTurn(state, seerId, WerewolfRole.kahin);
    if (!state.seerAvailable) {
      throw StateError('Kâhin sorgu hakkını zaten kullandı.');
    }
    if (!seerOptions(state, seerId).any((p) => p.id == targetId)) {
      throw ArgumentError('Geçersiz sorgu hedefi: $targetId');
    }
    return state.copyWith(
      seerAvailable: false,
      nightActions: state.nightActions.copyWith(seerInspectedId: targetId),
    );
  }

  /// Sıradaki oyuncu işini bitirdi; telefon bir sonrakine geçer.
  ///
  /// Zorunlu hamleler (vampir oyu, doktor koruması) yapılmadan sıra geçmez.
  WerewolfGameState completeNightTurn(WerewolfGameState state) {
    _requirePhase(state, WerewolfPhase.nightPhase);
    final player = state.currentTurnPlayer;
    if (player == null) throw StateError('Gecenin tüm sıraları tamamlandı.');

    final actions = state.nightActions;
    if (player.role == WerewolfRole.vampir &&
        !actions.vampireVotes.containsKey(player.id)) {
      throw StateError('Vampir hedef seçmeden sırasını bitiremez.');
    }
    if (player.role == WerewolfRole.doktor &&
        actions.doctorProtectedId == null) {
      throw StateError('Doktor kimseyi korumadan sırasını bitiremez.');
    }
    return state.copyWith(turnIndex: state.turnIndex + 1);
  }

  /// Vampir oylarına göre bu gecenin saldırı hedefi (eşitlikte kura).
  String? vampireVictim(WerewolfGameState state, Random random) {
    final leaders = _leaders(_count(state.nightActions.vampireVotes.values));
    if (leaders.isEmpty) return null;
    return leaders.length == 1
        ? leaders.single
        : leaders[random.nextInt(leaders.length)];
  }

  /// Gecenin sonucunu hesaplar ve gündüze geçer. Herkes sırasını
  /// bitirmeden çağrılamaz.
  WerewolfGameState resolveNight(WerewolfGameState state, Random random) {
    _requirePhase(state, WerewolfPhase.nightPhase);
    if (!state.isTurnSequenceComplete) {
      throw StateError('Telefon henüz herkesin elinden geçmedi.');
    }
    final actions = state.nightActions;
    final victimId = vampireVictim(state, random);
    final saved = victimId != null &&
        (actions.doctorProtectedId == victimId ||
            actions.witchHealTargetId == victimId);

    final dying = <String, WerewolfDeathCause>{
      if (victimId != null && !saved) victimId: WerewolfDeathCause.vampires,
    };
    final poisonId = actions.witchPoisonTargetId;
    if (poisonId != null) {
      dying.putIfAbsent(poisonId, () => WerewolfDeathCause.poison);
    }

    final killed = _kill(state, dying);
    final afterNight = killed.copyWith(
      phase: WerewolfPhase.dayPhase,
      turnOrder: const [],
      turnIndex: 0,
      players: _mapPlayers(
        killed,
        (p) => p.copyWith(isTargetedByVampires: p.id == victimId),
      ),
      lastNightDeaths: List.unmodifiable(dying.keys),
      someoneSavedLastNight: saved,
      witchHealAvailable:
          state.witchHealAvailable && actions.witchHealTargetId == null,
      witchPoisonAvailable: state.witchPoisonAvailable && poisonId == null,
      lastDoctorProtectedId: actions.doctorProtectedId,
      clearLastDoctorProtected: actions.doctorProtectedId == null,
    );
    return _afterDeaths(afterNight, dying.keys);
  }

  // ---------------------------------------------------------------------------
  // Avcı
  // ---------------------------------------------------------------------------

  /// Avcının vurabileceği kişiler: kendisi hariç tüm yaşayanlar.
  List<WerewolfPlayer> hunterOptions(WerewolfGameState state) =>
      state.alivePlayers
          .where((p) => p.id != state.pendingHunterId)
          .toList(growable: false);

  /// Elenen avcı tek kurşununu kullanır; vurulan kişi anında elenir.
  WerewolfGameState hunterShoot(WerewolfGameState state, String targetId) {
    if (!state.hasPendingHunterDecision || !state.hunterBulletAvailable) {
      throw StateError('Kurşun kullanacak bir avcı yok.');
    }
    if (!hunterOptions(state).any((p) => p.id == targetId)) {
      throw ArgumentError('Geçersiz avcı hedefi: $targetId');
    }
    final shot = _kill(state, {targetId: WerewolfDeathCause.hunter}).copyWith(
      clearPendingHunter: true,
      hunterBulletAvailable: false,
    );
    return _finishIfWon(shot);
  }

  /// Elenen avcı kurşununu kullanmamayı seçer.
  WerewolfGameState hunterHoldFire(WerewolfGameState state) {
    if (!state.hasPendingHunterDecision) {
      throw StateError('Karar verecek bir avcı yok.');
    }
    return _finishIfWon(state.copyWith(clearPendingHunter: true));
  }

  // ---------------------------------------------------------------------------
  // Gündüz: bireysel gizli oylama
  // ---------------------------------------------------------------------------

  /// Bireysel oylama başlar: telefon yaşayan herkese sırayla verilecek.
  WerewolfGameState startVoting(WerewolfGameState state) {
    _requirePhase(state, WerewolfPhase.dayPhase);
    if (state.hasPendingHunterDecision) {
      throw StateError('Önce avcı kararını vermeli.');
    }
    return state.copyWith(
      phase: WerewolfPhase.votingPhase,
      turnOrder: _aliveIds(state),
      turnIndex: 0,
      votes: const {},
      voteResolved: false,
      voteTally: const {},
      voteWasTie: false,
      clearLastExiled: true,
    );
  }

  /// [voterId]'nin oy verebileceği kişiler: kendisi hariç tüm yaşayanlar.
  List<WerewolfPlayer> voteOptions(WerewolfGameState state, String voterId) =>
      state.alivePlayers.where((p) => p.id != voterId).toList(growable: false);

  /// Sıradaki seçmenin gizli oyu. Son oy da verilince oylar otomatik sayılır.
  WerewolfGameState castVote(
    WerewolfGameState state,
    String voterId,
    String targetId,
    Random random,
  ) {
    _requirePhase(state, WerewolfPhase.votingPhase);
    if (state.voteResolved) throw StateError('Oylama zaten sayıldı.');
    if (state.currentTurnPlayer?.id != voterId) {
      throw StateError('Oy sırası $voterId oyuncusunda değil.');
    }
    if (!voteOptions(state, voterId).any((p) => p.id == targetId)) {
      throw ArgumentError('Geçersiz oy: $targetId');
    }

    final voted = state.copyWith(
      votes: Map.unmodifiable({...state.votes, voterId: targetId}),
      turnIndex: state.turnIndex + 1,
    );
    return voted.isTurnSequenceComplete ? _tallyVotes(voted, random) : voted;
  }

  WerewolfGameState _tallyVotes(WerewolfGameState state, Random random) {
    final tally = _count(state.votes.values);
    final leaders = _leaders(tally);
    final isTie = leaders.length > 1;

    String? exiledId;
    if (leaders.length == 1) {
      exiledId = leaders.single;
    } else if (isTie &&
        state.settings.tieBreak == WerewolfTieBreak.randomDraw) {
      exiledId = leaders[random.nextInt(leaders.length)];
    }

    final counted = state.copyWith(
      voteResolved: true,
      voteTally: Map.unmodifiable(tally),
      voteWasTie: isTie,
      lastExiledId: exiledId,
      clearLastExiled: exiledId == null,
    );
    if (exiledId == null) return counted;

    final exiled = _kill(counted, {exiledId: WerewolfDeathCause.exile});
    return _afterDeaths(exiled, [exiledId]);
  }

  // ---------------------------------------------------------------------------
  // Zafer
  // ---------------------------------------------------------------------------

  /// Kazanan taraf (oyun sürüyorsa `null`).
  WerewolfTeam? checkWinner(List<WerewolfPlayer> players) {
    final vampires = players.where((p) => p.isAlive && p.isVampire).length;
    final villagers = players.where((p) => p.isAlive && !p.isVampire).length;
    if (vampires == 0) return WerewolfTeam.villagers;
    if (vampires >= villagers) return WerewolfTeam.vampires;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Yardımcılar
  // ---------------------------------------------------------------------------

  /// Ölümlerden sonra: ölenlerden biri kurşunu duran avcıysa kararını bekle,
  /// değilse zaferi kontrol et.
  WerewolfGameState _afterDeaths(
    WerewolfGameState state,
    Iterable<String> deadIds,
  ) {
    final hunter = deadIds
        .map(state.playerById)
        .where((p) => p.role == WerewolfRole.avci)
        .firstOrNull;
    if (hunter != null &&
        state.hunterBulletAvailable &&
        state.alivePlayers.isNotEmpty) {
      return state.copyWith(pendingHunterId: hunter.id);
    }
    return _finishIfWon(state);
  }

  WerewolfGameState _finishIfWon(WerewolfGameState state) {
    final winner = checkWinner(state.players);
    if (winner == null) return state;
    return state.copyWith(phase: WerewolfPhase.gameFinished, winner: winner);
  }

  WerewolfGameState _kill(
    WerewolfGameState state,
    Map<String, WerewolfDeathCause> dying,
  ) {
    if (dying.isEmpty) return state;
    return state.copyWith(
      players: _mapPlayers(
        state,
        (p) => dying.containsKey(p.id) ? p.copyWith(isAlive: false) : p,
      ),
      deaths: List.unmodifiable([
        ...state.deaths,
        for (final entry in dying.entries)
          WerewolfDeath(
            playerId: entry.key,
            cause: entry.value,
            dayNumber: state.dayNumber,
          ),
      ]),
    );
  }

  Map<String, int> _count(Iterable<String> ids) {
    final counts = <String, int>{};
    for (final id in ids) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  /// En yüksek sayıya sahip id'ler (kura deterministik olsun diye sıralı).
  List<String> _leaders(Map<String, int> counts) {
    if (counts.isEmpty) return const [];
    final top = counts.values.reduce(max);
    return counts.entries
        .where((e) => e.value == top)
        .map((e) => e.key)
        .toList()
      ..sort();
  }

  List<String> _aliveIds(WerewolfGameState state) =>
      List.unmodifiable(state.alivePlayers.map((p) => p.id));

  List<WerewolfPlayer> _mapPlayers(
    WerewolfGameState state,
    WerewolfPlayer Function(WerewolfPlayer player) update,
  ) =>
      List.unmodifiable(state.players.map(update));

  void _requireNightTurn(
    WerewolfGameState state,
    String playerId,
    WerewolfRole role,
  ) {
    _requirePhase(state, WerewolfPhase.nightPhase);
    final current = state.currentTurnPlayer;
    if (current == null || current.id != playerId) {
      throw StateError('Gece sırası $playerId oyuncusunda değil.');
    }
    if (current.role != role) {
      throw StateError('${current.name} bir ${role.label} değil.');
    }
  }

  void _requirePhase(WerewolfGameState state, WerewolfPhase phase) {
    if (state.phase != phase) {
      throw StateError(
        'Bu hamle ${phase.name} fazında yapılır (şu an: ${state.phase.name}).',
      );
    }
  }
}
