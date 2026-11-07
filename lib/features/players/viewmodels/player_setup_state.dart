import '../../../core/utils/turkish_text.dart';
import '../../../domain/models/player.dart';

/// Player Setup ekranının okuduğu immutable state.
class PlayerSetupState {
  const PlayerSetupState({
    this.players = const [],
    this.history = const [],
    this.errorMessage,
  });

  /// Bu oyun için eklenmiş aktif oyuncular (ekleme sırasıyla).
  final List<Player> players;

  /// Cihazda kayıtlı, geçmiş oyunlardan hatırlanan isimler (en yeni başta).
  final List<String> history;

  /// Son işlemden kaynaklanan hata mesajı (`null` ise hata yok).
  final String? errorMessage;

  static const int minPlayers = 4;
  static const int maxPlayers = 10;

  bool get canAddPlayer => players.length < maxPlayers;

  bool get canStartGame =>
      players.length >= minPlayers && players.length <= maxPlayers;

  bool get isBelowMinimum => players.length < minPlayers;

  /// "Geçmişten Seç" listesinde gösterilecek isimler: geçmişte olup henüz
  /// aktif listeye eklenmemiş olanlar (Türkçe büyük/küçük harf duyarsız).
  List<String> get availableHistory {
    final activeNames = players.map((p) => p.name.toLowerTr()).toSet();
    return history
        .where((name) => !activeNames.contains(name.toLowerTr()))
        .toList(growable: false);
  }

  bool get hasAvailableHistory => availableHistory.isNotEmpty;

  PlayerSetupState copyWith({
    List<Player>? players,
    List<String>? history,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlayerSetupState(
      players: players ?? this.players,
      history: history ?? this.history,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
