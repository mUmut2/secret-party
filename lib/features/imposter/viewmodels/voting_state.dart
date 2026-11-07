/// Oylama ekranının okuduğu immutable state.
///
/// Tek telefon akışında grup ortak karar verdiği için tek bir
/// "seçilen şüpheli" tutulur.
class VotingState {
  const VotingState({this.selectedPlayerId});

  /// Seçilen şüphelinin id'si (`null` ise henüz kimse seçilmedi).
  final String? selectedPlayerId;

  bool get hasSelection => selectedPlayerId != null;
}
