import 'dart:math';

import '../models/taboo_card.dart';
import '../models/taboo_match.dart';
import '../models/taboo_settings.dart';
import '../models/taboo_team.dart';

/// Tabu oyununun KURALLARINI içeren saf Dart sınıfı.
///
/// Flutter'a bağımlı değildir ve state tutmaz: her metot bir [TabooMatch]
/// alıp yenisini döndürür. Zamanlayıcı ve titreşim gibi yan etkiler
/// `TabooGameNotifier`'dadır. Rastgelelik dışarıdan verilir; testlerde
/// `Random(seed)` ile sonuç deterministiktir.
///
/// Kurallar:
/// - DOĞRU: +1 puan, yeni kart.
/// - TABU: −1 puan, yeni kart.
/// - PAS: puan değişmez, yeni kart; turda en fazla `passLimit` kez.
/// - Kazanma: her iki takım EŞİT sayıda tur oynadıktan sonra hedef skora
///   ulaşmış ve tek başına önde olan takım kazanır. Eşitlikte oyun devam eder.
///   Böylece ilk başlayan takım avantaj kazanmaz.
class TabooEngine {
  const TabooEngine();

  /// Yeni bir maç kurar. Sıra ilk takımdadır ve maç `ready` durumundadır.
  ///
  /// [isSeen] verilirse daha önceki maçlarda görülen kartlar destenin
  /// ALTINA, görülmemişler ÜSTÜNE (önce çekilecek şekilde) karıştırılır;
  /// böylece havuz tükenmeden aynı kart tekrar gelmez.
  ///
  /// Kart listesi boşsa [ArgumentError] fırlatır (programlama hatası).
  TabooMatch createMatch({
    required TabooSettings settings,
    required List<TabooCard> cards,
    required Random random,
    bool Function(TabooCard card)? isSeen,
  }) {
    if (cards.isEmpty) {
      throw ArgumentError('Tabu destesi boş olamaz.');
    }
    if (settings.roundDurationSeconds <= 0) {
      throw ArgumentError('Tur süresi sıfırdan büyük olmalı.');
    }
    if (settings.passLimit < 0) {
      throw ArgumentError('Pas limiti negatif olamaz.');
    }
    if (settings.targetScore <= 0) {
      throw ArgumentError('Hedef skor sıfırdan büyük olmalı.');
    }

    return TabooMatch(
      settings: settings,
      teams: [
        TabooTeam(id: 'team_a', name: settings.teamAName),
        TabooTeam(id: 'team_b', name: settings.teamBName),
      ],
      activeTeamIndex: 0,
      status: TabooGameStatus.ready,
      deck: List.unmodifiable(_buildDeck(cards, random, isSeen)),
      discardPile: const [],
      remainingSeconds: settings.roundDurationSeconds,
    );
  }

  /// Aktif takımın turunu başlatır: ilk kart çekilir, pas hakkı yenilenir,
  /// süre tam değerine döner. Sadece `ready` durumunda etki eder.
  TabooMatch startTurn(TabooMatch match, Random random) {
    if (match.status != TabooGameStatus.ready) return match;

    final draw = _draw(match, random);
    return match.copyWith(
      status: TabooGameStatus.inProgress,
      teams: _updateTeam(
        match.teams,
        match.activeTeamIndex,
        (team) => team.copyWith(passesLeft: match.settings.passLimit),
      ),
      currentCard: draw.card,
      deck: draw.deck,
      discardPile: draw.discardPile,
      remainingSeconds: match.settings.roundDurationSeconds,
      turnEntries: const [],
    );
  }

  /// DOĞRU: aktif takıma +1 puan, sıradaki kart.
  TabooMatch markCorrect(TabooMatch match, Random random) =>
      _resolveCard(match, random, TabooOutcome.correct, scoreDelta: 1);

  /// TABU: aktif takıma −1 puan, sıradaki kart.
  TabooMatch markTaboo(TabooMatch match, Random random) =>
      _resolveCard(match, random, TabooOutcome.taboo, scoreDelta: -1);

  /// PAS: puan değişmez, pas hakkı 1 azalır, sıradaki kart.
  /// Pas hakkı kalmadıysa maçı değiştirmeden döndürür.
  TabooMatch pass(TabooMatch match, Random random) {
    if (match.status != TabooGameStatus.inProgress) return match;
    if (!match.activeTeam.canPass) return match;

    final withPassUsed = match.copyWith(
      teams: _updateTeam(
        match.teams,
        match.activeTeamIndex,
        (team) => team.copyWith(passesLeft: team.passesLeft - 1),
      ),
    );
    return _resolveCard(withPassUsed, random, TabooOutcome.pass, scoreDelta: 0);
  }

  /// Zamanlayıcıdan gelen kalan süreyi işler. Süre sıfıra inerse turu bitirir.
  TabooMatch tick(TabooMatch match, int remainingSeconds) {
    if (match.status != TabooGameStatus.inProgress) return match;
    if (remainingSeconds <= 0) return endTurn(match);
    if (remainingSeconds == match.remainingSeconds) return match;
    return match.copyWith(remainingSeconds: remainingSeconds);
  }

  /// Turu bitirir. Ekrandaki kart gösterilmiş sayılır ve atılır.
  ///
  /// Kazanma koşulu sağlanırsa `gameFinished`, değilse `roundEnded` olur.
  TabooMatch endTurn(TabooMatch match) {
    if (match.status != TabooGameStatus.inProgress) return match;

    final current = match.currentCard;
    final completedTurns = match.completedTurns + 1;
    final winnerIndex =
        _findWinner(match.teams, match.settings, completedTurns);

    return match.copyWith(
      status: winnerIndex == null
          ? TabooGameStatus.roundEnded
          : TabooGameStatus.gameFinished,
      remainingSeconds: 0,
      completedTurns: completedTurns,
      discardPile: List.unmodifiable([
        ...match.discardPile,
        if (current != null) current,
      ]),
      clearCurrentCard: true,
      winnerIndex: winnerIndex,
    );
  }

  /// Sırayı diğer takıma devreder (`roundEnded → ready`).
  TabooMatch passTurnToNextTeam(TabooMatch match) {
    if (match.status != TabooGameStatus.roundEnded) return match;
    return match.copyWith(
      status: TabooGameStatus.ready,
      activeTeamIndex: match.nextTeamIndex,
      remainingSeconds: match.settings.roundDurationSeconds,
      turnEntries: const [],
    );
  }

  /// Karar verilen kartı tur özetine ekler, skoru günceller ve yeni kart çeker.
  TabooMatch _resolveCard(
    TabooMatch match,
    Random random,
    TabooOutcome outcome, {
    required int scoreDelta,
  }) {
    final card = match.currentCard;
    if (match.status != TabooGameStatus.inProgress || card == null) {
      return match;
    }

    final draw = _draw(match, random);
    return match.copyWith(
      teams: scoreDelta == 0
          ? match.teams
          : _updateTeam(
              match.teams,
              match.activeTeamIndex,
              (team) => team.copyWith(score: team.score + scoreDelta),
            ),
      turnEntries: List.unmodifiable([
        ...match.turnEntries,
        TabooTurnEntry(card: card, outcome: outcome),
      ]),
      currentCard: draw.card,
      deck: draw.deck,
      discardPile: draw.discardPile,
    );
  }

  /// Desteden yeni kart çeker; ekrandaki kart (varsa) atılır.
  ///
  /// Deste biterse atılan kartlar karıştırılıp yeni deste olur. Az önce
  /// gösterilen kart mümkünse hemen tekrar gelmez.
  ({TabooCard card, List<TabooCard> deck, List<TabooCard> discardPile}) _draw(
    TabooMatch match,
    Random random,
  ) {
    final previous = match.currentCard;
    var deck = [...match.deck];
    var discard = [...match.discardPile, if (previous != null) previous];

    if (deck.isEmpty) {
      deck = discard..shuffle(random);
      discard = [];
      // Desteden en son çekilecek kart sondadır; önceki kartla aynıysa
      // başa alınır ki aynı kart arka arkaya gelmesin.
      if (deck.length > 1 && deck.last == previous) {
        deck.insert(0, deck.removeLast());
      }
    }

    final card = deck.removeLast();
    return (
      card: card,
      deck: List.unmodifiable(deck),
      discardPile: List.unmodifiable(discard),
    );
  }

  /// Kartlar destenin SONUNDAN çekilir: görülmüşler başa, görülmemişler sona.
  List<TabooCard> _buildDeck(
    List<TabooCard> cards,
    Random random,
    bool Function(TabooCard card)? isSeen,
  ) {
    if (isSeen == null) return [...cards]..shuffle(random);
    final seen = [
      for (final card in cards)
        if (isSeen(card)) card,
    ]..shuffle(random);
    final unseen = [
      for (final card in cards)
        if (!isSeen(card)) card,
    ]..shuffle(random);
    return [...seen, ...unseen];
  }

  int? _findWinner(
    List<TabooTeam> teams,
    TabooSettings settings,
    int completedTurns,
  ) {
    // Tek sayıda tur oynandıysa ikinci takım henüz eşitleme şansını kullanmadı.
    if (completedTurns.isOdd) return null;

    final a = teams[0].score;
    final b = teams[1].score;
    if (a == b) return null;
    final leader = a > b ? 0 : 1;
    return teams[leader].score >= settings.targetScore ? leader : null;
  }

  List<TabooTeam> _updateTeam(
    List<TabooTeam> teams,
    int index,
    TabooTeam Function(TabooTeam team) update,
  ) {
    return List.unmodifiable([
      for (var i = 0; i < teams.length; i++)
        i == index ? update(teams[i]) : teams[i],
    ]);
  }
}
