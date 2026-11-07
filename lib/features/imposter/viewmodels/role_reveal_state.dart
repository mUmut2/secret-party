/// Role Reveal (pass-and-play) ekranının durumu.
///
/// Oyuncu listesine / kelimeye referans tutmaz; onlar `gameSessionProvider`'da.
class RoleRevealState {
  const RoleRevealState({
    this.currentPlayerIndex = 0,
    this.isRevealed = false,
    this.allPlayersRevealed = false,
  });

  /// Sırası gelen oyuncunun listedeki index'i.
  final int currentPlayerIndex;

  /// true: rol ekranı açık, false: "telefonu ver" ekranı.
  final bool isRevealed;

  /// Tüm oyuncular rolünü gördü mü?
  final bool allPlayersRevealed;

  RoleRevealState copyWith({
    int? currentPlayerIndex,
    bool? isRevealed,
    bool? allPlayersRevealed,
  }) {
    return RoleRevealState(
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      isRevealed: isRevealed ?? this.isRevealed,
      allPlayersRevealed: allPlayersRevealed ?? this.allPlayersRevealed,
    );
  }
}
