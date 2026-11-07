import 'taboo_card.dart';

/// Bir Tabu maçının kurulum ayarları (immutable).
class TabooSettings {
  const TabooSettings({
    this.teamAName = defaultTeamAName,
    this.teamBName = defaultTeamBName,
    this.roundDurationSeconds = defaultRoundDurationSeconds,
    this.passLimit = defaultPassLimit,
    this.targetScore = defaultTargetScore,
    this.categoryIds,
    this.difficulty,
  });

  static const String defaultTeamAName = 'Takım A';
  static const String defaultTeamBName = 'Takım B';

  static const int defaultRoundDurationSeconds = 60;
  static const int defaultPassLimit = 3;
  static const int defaultTargetScore = 20;

  /// Kurulum ekranında sunulan seçenekler.
  static const List<int> roundDurationOptions = [45, 60, 90, 120];
  static const List<int> passLimitOptions = [0, 1, 3, 5];
  static const List<int> targetScoreOptions = [10, 20, 30, 50];

  final String teamAName;
  final String teamBName;
  final int roundDurationSeconds;

  /// Bir turda kullanılabilecek en fazla pas sayısı.
  final int passLimit;

  /// Bu skora ulaşan (ve eşit turda önde olan) takım kazanır.
  final int targetScore;

  /// `null` ise tüm kategoriler.
  final Set<String>? categoryIds;

  /// `null` ise tüm zorluklar.
  final TabooDifficulty? difficulty;

  List<String> get teamNames => [teamAName, teamBName];

  TabooSettings copyWith({
    String? teamAName,
    String? teamBName,
    int? roundDurationSeconds,
    int? passLimit,
    int? targetScore,
  }) {
    return TabooSettings(
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      roundDurationSeconds: roundDurationSeconds ?? this.roundDurationSeconds,
      passLimit: passLimit ?? this.passLimit,
      targetScore: targetScore ?? this.targetScore,
      categoryIds: categoryIds,
      difficulty: difficulty,
    );
  }
}
