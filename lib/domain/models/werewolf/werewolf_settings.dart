import 'werewolf_role.dart';

/// Bir Vampir Köylü oyununun rol dağılımı ve kural ayarları (immutable).
class WerewolfSettings {
  const WerewolfSettings({
    required this.vampireCount,
    this.includeDoctor = true,
    this.includeWitch = true,
    this.includeSeer = true,
    this.includeHunter = false,
    this.tieBreak = WerewolfTieBreak.noElimination,
    this.discussionSeconds = defaultDiscussionSeconds,
    this.revealRoleOnDeath = true,
  });

  static const int minPlayers = 5;
  static const int maxPlayers = 16;

  static const int defaultDiscussionSeconds = 180;
  static const List<int> discussionOptions = [60, 120, 180, 300];

  /// Oyuncu sayısına göre önerilen dağılım:
  /// - Vampir: her 3 oyuncuya 1 (en az 1)
  /// - Doktor 5+ · Kâhin 6+ · Cadı 7+ · Avcı 8+ oyuncu
  ///
  /// Örn. 6 oyuncu → 2 Vampir, Doktor, Kâhin, 2 Köylü.
  factory WerewolfSettings.recommended(
    int playerCount, {
    WerewolfTieBreak tieBreak = WerewolfTieBreak.noElimination,
    int discussionSeconds = defaultDiscussionSeconds,
    bool revealRoleOnDeath = true,
  }) {
    final vampires = (playerCount ~/ 3).clamp(1, maxVampiresFor(playerCount));
    return WerewolfSettings(
      vampireCount: vampires,
      includeDoctor: playerCount >= 5,
      includeSeer: playerCount >= 6,
      includeWitch: playerCount >= 7,
      includeHunter: playerCount >= 8,
      tieBreak: tieBreak,
      discussionSeconds: discussionSeconds,
      revealRoleOnDeath: revealRoleOnDeath,
    );
  }

  final int vampireCount;
  final bool includeDoctor;
  final bool includeWitch;
  final bool includeSeer;
  final bool includeHunter;

  /// Gündüz oylamasında eşitlik olursa ne yapılacağı.
  final WerewolfTieBreak tieBreak;

  /// Gündüz tartışma süresi (saniye).
  final int discussionSeconds;

  /// Ölen / sürgün edilen oyuncunun rolü herkese açıklansın mı?
  final bool revealRoleOnDeath;

  /// Oyun başında vampirler köylülerden az olmalı (aksi halde oyun
  /// başlamadan biter): 2 × vampir < oyuncu sayısı.
  static int maxVampiresFor(int playerCount) =>
      playerCount < 3 ? 1 : (playerCount - 1) ~/ 2;

  int get specialRoleCount =>
      (includeDoctor ? 1 : 0) +
      (includeWitch ? 1 : 0) +
      (includeSeer ? 1 : 0) +
      (includeHunter ? 1 : 0);

  /// Verilen oyuncu sayısında kaç düz köylü olacağı (negatifse geçersiz).
  int villagerCountFor(int playerCount) =>
      playerCount - vampireCount - specialRoleCount;

  /// Dağılım geçersizse Türkçe hata mesajı, geçerliyse `null`.
  String? validate(int playerCount) {
    if (playerCount < minPlayers) {
      return 'Vampir Köylü için en az $minPlayers oyuncu gerekiyor.';
    }
    if (playerCount > maxPlayers) {
      return 'En fazla $maxPlayers oyuncu oynayabilir.';
    }
    if (vampireCount < 1) {
      return 'En az 1 vampir olmalı.';
    }
    if (vampireCount > maxVampiresFor(playerCount)) {
      return 'Vampirler köylülerden az olmalı '
          '(en fazla ${maxVampiresFor(playerCount)}).';
    }
    if (villagerCountFor(playerCount) < 0) {
      return 'Roller oyuncu sayısını aşıyor. Vampir ya da özel rol azaltın.';
    }
    return null;
  }

  /// Oyuncu sayısı kadar rolden oluşan (karıştırılmamış) deste.
  List<WerewolfRole> roleDeck(int playerCount) {
    return [
      for (var i = 0; i < vampireCount; i++) WerewolfRole.vampir,
      if (includeDoctor) WerewolfRole.doktor,
      if (includeWitch) WerewolfRole.cadi,
      if (includeSeer) WerewolfRole.kahin,
      if (includeHunter) WerewolfRole.avci,
      for (var i = 0; i < villagerCountFor(playerCount); i++)
        WerewolfRole.koylu,
    ];
  }

  WerewolfSettings copyWith({
    int? vampireCount,
    bool? includeDoctor,
    bool? includeWitch,
    bool? includeSeer,
    bool? includeHunter,
    WerewolfTieBreak? tieBreak,
    int? discussionSeconds,
    bool? revealRoleOnDeath,
  }) {
    return WerewolfSettings(
      vampireCount: vampireCount ?? this.vampireCount,
      includeDoctor: includeDoctor ?? this.includeDoctor,
      includeWitch: includeWitch ?? this.includeWitch,
      includeSeer: includeSeer ?? this.includeSeer,
      includeHunter: includeHunter ?? this.includeHunter,
      tieBreak: tieBreak ?? this.tieBreak,
      discussionSeconds: discussionSeconds ?? this.discussionSeconds,
      revealRoleOnDeath: revealRoleOnDeath ?? this.revealRoleOnDeath,
    );
  }
}
