import '../../../core/utils/turkish_text.dart';
import '../../../domain/models/bomb/bomb_settings.dart';
import '../../../domain/models/player.dart';

/// Tik Tak Bomba kurulum ekranının okuduğu immutable state.
class BombSetupState {
  const BombSetupState({
    this.players = const [],
    this.history = const [],
    this.settings = const BombSettings(),
    this.inputError,
  });

  static const int maxNameLength = 20;

  final List<Player> players;

  /// Cihazda kayıtlı geçmiş oyuncu isimleri (tüm oyunlarla ortak).
  final List<String> history;

  final BombSettings settings;

  /// Son isim ekleme denemesinin hatası (`null` ise hata yok).
  final String? inputError;

  int get playerCount => players.length;

  bool get canAddPlayer => players.length < BombSettings.maxPlayers;

  /// Oyuncu sayısı hatası (`null` ise oyun başlatılabilir).
  String? get setupError => BombSettings.validatePlayerCount(playerCount);

  bool get canStart => setupError == null;

  /// Henüz eklenmemiş geçmiş isimleri.
  List<String> get availableHistory {
    final active = players.map((p) => p.name.toLowerTr()).toSet();
    return history
        .where((name) => !active.contains(name.toLowerTr()))
        .toList(growable: false);
  }

  BombSetupState copyWith({
    List<Player>? players,
    List<String>? history,
    BombSettings? settings,
    String? inputError,
    bool clearInputError = false,
  }) {
    return BombSetupState(
      players: players ?? this.players,
      history: history ?? this.history,
      settings: settings ?? this.settings,
      inputError: clearInputError ? null : (inputError ?? this.inputError),
    );
  }
}
