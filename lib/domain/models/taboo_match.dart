import 'taboo_card.dart';
import 'taboo_settings.dart';
import 'taboo_team.dart';

/// Tabu maçının aşaması.
///
/// - [ready]: tur başlamadı; anlatıcı telefonu alıp "Başla"ya basacak
/// - [inProgress]: süre akıyor, kartlar anlatılıyor
/// - [roundEnded]: süre bitti; tur özeti gösteriliyor, sıra devredilecek
/// - [gameFinished]: bir takım kazandı
enum TabooGameStatus { ready, inProgress, roundEnded, gameFinished }

/// Bir kart için verilen karar.
enum TabooOutcome { correct, taboo, pass }

/// Tur özeti için tek bir kart kaydı.
class TabooTurnEntry {
  const TabooTurnEntry({required this.card, required this.outcome});

  final TabooCard card;
  final TabooOutcome outcome;
}

/// Bir Tabu maçının TÜM durumunu tutan immutable model.
///
/// Kuralları içermez; geçişler `TabooEngine` tarafından üretilir.
class TabooMatch {
  const TabooMatch({
    required this.settings,
    required this.teams,
    required this.activeTeamIndex,
    required this.status,
    required this.deck,
    required this.discardPile,
    required this.remainingSeconds,
    this.currentCard,
    this.completedTurns = 0,
    this.turnEntries = const [],
    this.winnerIndex,
  });

  final TabooSettings settings;

  /// Her zaman tam 2 takım.
  final List<TabooTeam> teams;

  /// Sırası gelen (anlatan) takımın index'i.
  final int activeTeamIndex;

  final TabooGameStatus status;

  /// Henüz çekilmemiş kartlar (sıradaki en sonda).
  final List<TabooCard> deck;

  /// Bu döngüde gösterilmiş kartlar. Deste bitince karıştırılıp desteye döner.
  final List<TabooCard> discardPile;

  /// Ekranda anlatılan kart (`ready` durumunda `null`).
  final TabooCard? currentCard;

  /// Aktif turda kalan süre (saniye).
  final int remainingSeconds;

  /// Tamamlanan tur sayısı (iki takımın toplamı).
  final int completedTurns;

  /// Aktif / son turda verilen kararlar (tur özeti için).
  final List<TabooTurnEntry> turnEntries;

  /// Kazanan takımın index'i (oyun bitmediyse `null`).
  final int? winnerIndex;

  TabooTeam get activeTeam => teams[activeTeamIndex];

  int get nextTeamIndex => 1 - activeTeamIndex;

  TabooTeam get nextTeam => teams[nextTeamIndex];

  TabooTeam? get winner {
    final index = winnerIndex;
    return index == null ? null : teams[index];
  }

  /// 1'den başlayan tur numarası (her iki takımın birer turu = 1 tur).
  int get roundNumber => completedTurns ~/ 2 + 1;

  int countOf(TabooOutcome outcome) =>
      turnEntries.where((e) => e.outcome == outcome).length;

  /// Aktif turda kazanılan net puan (doğrular − tabular).
  int get turnPoints =>
      countOf(TabooOutcome.correct) - countOf(TabooOutcome.taboo);

  TabooMatch copyWith({
    List<TabooTeam>? teams,
    int? activeTeamIndex,
    TabooGameStatus? status,
    List<TabooCard>? deck,
    List<TabooCard>? discardPile,
    TabooCard? currentCard,
    bool clearCurrentCard = false,
    int? remainingSeconds,
    int? completedTurns,
    List<TabooTurnEntry>? turnEntries,
    int? winnerIndex,
  }) {
    return TabooMatch(
      settings: settings,
      teams: teams ?? this.teams,
      activeTeamIndex: activeTeamIndex ?? this.activeTeamIndex,
      status: status ?? this.status,
      deck: deck ?? this.deck,
      discardPile: discardPile ?? this.discardPile,
      currentCard: clearCurrentCard ? null : (currentCard ?? this.currentCard),
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      completedTurns: completedTurns ?? this.completedTurns,
      turnEntries: turnEntries ?? this.turnEntries,
      winnerIndex: winnerIndex ?? this.winnerIndex,
    );
  }
}
