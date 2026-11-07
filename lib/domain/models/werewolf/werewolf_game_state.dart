import 'werewolf_player.dart';
import 'werewolf_role.dart';
import 'werewolf_settings.dart';

/// Vampir Köylü oyununun fazları.
///
/// Akış: `setup → roleReveal → nightPhase → dayPhase → votingPhase →
/// nightPhase → …` ve herhangi bir ölümden sonra `gameFinished`.
enum WerewolfPhase {
  setup,
  roleReveal,
  nightPhase,
  dayPhase,
  votingPhase,
  gameFinished,
}

/// Bir oyuncunun oyundan çıkış nedeni.
enum WerewolfDeathCause {
  vampires('Vampirler tarafından avlandı'),
  poison('Cadı tarafından zehirlendi'),
  exile('Köy oylamasıyla sürgün edildi'),
  hunter('Avcının kurşunuyla vuruldu');

  const WerewolfDeathCause(this.label);

  final String label;
}

/// Oyun boyunca yaşanan tek bir ölüm kaydı.
class WerewolfDeath {
  const WerewolfDeath({
    required this.playerId,
    required this.cause,
    required this.dayNumber,
  });

  final String playerId;
  final WerewolfDeathCause cause;

  /// Ölümün yaşandığı gün/gece numarası (1'den başlar).
  final int dayNumber;
}

/// İçinde bulunulan gecede rollerin verdiği gizli kararlar.
class WerewolfNightActions {
  const WerewolfNightActions({
    this.vampireVotes = const {},
    this.doctorProtectedId,
    this.witchHealTargetId,
    this.witchPoisonTargetId,
    this.seerInspectedId,
  });

  /// Vampir id → seçtiği hedef id. Kurban, en çok seçilen kişidir.
  final Map<String, String> vampireVotes;
  final String? doctorProtectedId;

  /// Cadının iyileştirme iksirini verdiği kişi.
  final String? witchHealTargetId;
  final String? witchPoisonTargetId;

  /// Kâhinin bu gece rolünü sorguladığı kişi.
  final String? seerInspectedId;

  WerewolfNightActions copyWith({
    Map<String, String>? vampireVotes,
    String? doctorProtectedId,
    String? witchHealTargetId,
    String? witchPoisonTargetId,
    String? seerInspectedId,
  }) {
    return WerewolfNightActions(
      vampireVotes: vampireVotes ?? this.vampireVotes,
      doctorProtectedId: doctorProtectedId ?? this.doctorProtectedId,
      witchHealTargetId: witchHealTargetId ?? this.witchHealTargetId,
      witchPoisonTargetId: witchPoisonTargetId ?? this.witchPoisonTargetId,
      seerInspectedId: seerInspectedId ?? this.seerInspectedId,
    );
  }
}

/// Bir Vampir Köylü oyununun TÜM durumunu tutan immutable model.
///
/// Kuralları içermez; geçişler `WerewolfEngine` tarafından üretilir.
///
/// Gece ve oylama "sıralı tek telefon" ile oynanır: [turnOrder] o fazın
/// başında yaşayan oyunculardır, [turnIndex] telefonun kimde olduğudur.
class WerewolfGameState {
  const WerewolfGameState({
    required this.id,
    required this.settings,
    required this.players,
    required this.phase,
    this.dayNumber = 0,
    this.turnOrder = const [],
    this.turnIndex = 0,
    this.nightActions = const WerewolfNightActions(),
    this.witchHealAvailable = true,
    this.witchPoisonAvailable = true,
    this.seerAvailable = true,
    this.hunterBulletAvailable = true,
    this.lastDoctorProtectedId,
    this.lastNightDeaths = const [],
    this.someoneSavedLastNight = false,
    this.votes = const {},
    this.voteResolved = false,
    this.voteTally = const {},
    this.voteWasTie = false,
    this.lastExiledId,
    this.pendingHunterId,
    this.deaths = const [],
    this.winner,
  });

  /// Her yeni oyunda değişir; ekran akışları bunu izleyerek sıfırlanır.
  final String id;

  final WerewolfSettings settings;
  final List<WerewolfPlayer> players;
  final WerewolfPhase phase;

  /// Gece/gün numarası (ilk gece 1). Gece N'den sonra gün N gelir.
  final int dayNumber;

  /// Bu gecede / oylamada telefonun sırayla geçeceği oyuncular.
  final List<String> turnOrder;

  /// Telefonun şu an kimde olduğu ([turnOrder] içindeki index).
  final int turnIndex;

  final WerewolfNightActions nightActions;

  /// Oyun boyunca TEK kullanımlık haklar.
  final bool witchHealAvailable;
  final bool witchPoisonAvailable;
  final bool seerAvailable;
  final bool hunterBulletAvailable;

  /// Doktorun bir önceki gece koruduğu kişi (art arda koruma yasak).
  final String? lastDoctorProtectedId;

  /// Son gecede ölenlerin id'leri (gündüz duyurusu için).
  final List<String> lastNightDeaths;

  /// Son gece vampir saldırısı engellendi mi? (Kimin kurtardığı açıklanmaz.)
  final bool someoneSavedLastNight;

  /// Bugünün gizli oyları: seçmen id → oy verdiği kişi id.
  final Map<String, String> votes;

  /// Bugünün oylaması sayıldı mı?
  final bool voteResolved;

  /// Sayım sonucu: oyuncu id → aldığı oy (yalnızca oy alanlar).
  final Map<String, int> voteTally;

  /// En çok oyu birden fazla kişi aldı mı?
  final bool voteWasTie;

  /// Bugün sürgün edilen oyuncu (`null`: kimse sürgün edilmedi).
  final String? lastExiledId;

  /// Elenen ve kurşun kararını vermesi gereken avcının id'si.
  final String? pendingHunterId;

  /// Oyun boyunca yaşanan tüm ölümler (sırasıyla).
  final List<WerewolfDeath> deaths;

  /// Kazanan taraf (oyun bitmediyse `null`).
  final WerewolfTeam? winner;

  // --- Yardımcı okuyucular ---

  List<WerewolfPlayer> get alivePlayers =>
      players.where((p) => p.isAlive).toList(growable: false);

  List<WerewolfPlayer> get aliveVampires =>
      players.where((p) => p.isAlive && p.isVampire).toList(growable: false);

  List<WerewolfPlayer> get aliveVillagers =>
      players.where((p) => p.isAlive && !p.isVampire).toList(growable: false);

  bool get isFinished => phase == WerewolfPhase.gameFinished;

  bool get hasPendingHunterDecision => pendingHunterId != null;

  /// Sıradaki herkes telefonu aldı mı (gece / oylama bitti mi)?
  bool get isTurnSequenceComplete => turnIndex >= turnOrder.length;

  /// Telefonun şu an verilmesi gereken oyuncu.
  WerewolfPlayer? get currentTurnPlayer =>
      isTurnSequenceComplete ? null : playerById(turnOrder[turnIndex]);

  /// Ondan sonra telefonu alacak oyuncu (sonuncuysa `null`).
  WerewolfPlayer? get nextTurnPlayer => turnIndex + 1 < turnOrder.length
      ? playerById(turnOrder[turnIndex + 1])
      : null;

  WerewolfPlayer playerById(String id) => players.firstWhere((p) => p.id == id);

  WerewolfPlayer? tryPlayerById(String? id) {
    if (id == null) return null;
    return players.where((p) => p.id == id).firstOrNull;
  }

  /// Oyuncunun ölüm kaydı (hayattaysa `null`).
  WerewolfDeath? deathOf(String playerId) =>
      deaths.where((d) => d.playerId == playerId).firstOrNull;

  WerewolfGameState copyWith({
    List<WerewolfPlayer>? players,
    WerewolfPhase? phase,
    int? dayNumber,
    List<String>? turnOrder,
    int? turnIndex,
    WerewolfNightActions? nightActions,
    bool? witchHealAvailable,
    bool? witchPoisonAvailable,
    bool? seerAvailable,
    bool? hunterBulletAvailable,
    String? lastDoctorProtectedId,
    bool clearLastDoctorProtected = false,
    List<String>? lastNightDeaths,
    bool? someoneSavedLastNight,
    Map<String, String>? votes,
    bool? voteResolved,
    Map<String, int>? voteTally,
    bool? voteWasTie,
    String? lastExiledId,
    bool clearLastExiled = false,
    String? pendingHunterId,
    bool clearPendingHunter = false,
    List<WerewolfDeath>? deaths,
    WerewolfTeam? winner,
  }) {
    return WerewolfGameState(
      id: id,
      settings: settings,
      players: players ?? this.players,
      phase: phase ?? this.phase,
      dayNumber: dayNumber ?? this.dayNumber,
      turnOrder: turnOrder ?? this.turnOrder,
      turnIndex: turnIndex ?? this.turnIndex,
      nightActions: nightActions ?? this.nightActions,
      witchHealAvailable: witchHealAvailable ?? this.witchHealAvailable,
      witchPoisonAvailable: witchPoisonAvailable ?? this.witchPoisonAvailable,
      seerAvailable: seerAvailable ?? this.seerAvailable,
      hunterBulletAvailable:
          hunterBulletAvailable ?? this.hunterBulletAvailable,
      lastDoctorProtectedId: clearLastDoctorProtected
          ? null
          : (lastDoctorProtectedId ?? this.lastDoctorProtectedId),
      lastNightDeaths: lastNightDeaths ?? this.lastNightDeaths,
      someoneSavedLastNight:
          someoneSavedLastNight ?? this.someoneSavedLastNight,
      votes: votes ?? this.votes,
      voteResolved: voteResolved ?? this.voteResolved,
      voteTally: voteTally ?? this.voteTally,
      voteWasTie: voteWasTie ?? this.voteWasTie,
      lastExiledId:
          clearLastExiled ? null : (lastExiledId ?? this.lastExiledId),
      pendingHunterId:
          clearPendingHunter ? null : (pendingHunterId ?? this.pendingHunterId),
      deaths: deaths ?? this.deaths,
      winner: winner ?? this.winner,
    );
  }
}
