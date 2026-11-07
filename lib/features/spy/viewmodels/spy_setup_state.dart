import '../../../core/utils/turkish_text.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/spy/spy_settings.dart';

/// Ajan kurulum ekranının okuduğu immutable state.
class SpySetupState {
  const SpySetupState({
    this.players = const [],
    this.history = const [],
    this.settings = const SpySettings(),
    this.inputError,
  });

  static const int maxNameLength = 20;

  final List<Player> players;

  /// Cihazda kayıtlı geçmiş oyuncu isimleri (tüm oyunlarla ortak).
  final List<String> history;

  final SpySettings settings;

  /// Son isim ekleme denemesinin hatası (`null` ise hata yok).
  final String? inputError;

  int get playerCount => players.length;

  bool get canAddPlayer => players.length < SpySettings.maxPlayers;

  /// Ayar / oyuncu sayısı hatası (`null` ise oyun başlatılabilir).
  String? get setupError => settings.validate(playerCount);

  bool get canStart => setupError == null;

  /// İki ajan seçeneği bu oyuncu sayısında açılabilir mi?
  bool get canHaveTwoSpies => playerCount >= SpySettings.minPlayersForTwoSpies;

  /// Henüz eklenmemiş geçmiş isimleri.
  List<String> get availableHistory {
    final active = players.map((p) => p.name.toLowerTr()).toSet();
    return history
        .where((name) => !active.contains(name.toLowerTr()))
        .toList(growable: false);
  }

  SpySetupState copyWith({
    List<Player>? players,
    List<String>? history,
    SpySettings? settings,
    String? inputError,
    bool clearInputError = false,
  }) {
    return SpySetupState(
      players: players ?? this.players,
      history: history ?? this.history,
      settings: settings ?? this.settings,
      inputError: clearInputError ? null : (inputError ?? this.inputError),
    );
  }
}
