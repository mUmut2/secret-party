import '../../../core/utils/turkish_text.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/werewolf/werewolf_settings.dart';

/// Vampir Köylü kurulum ekranının okuduğu immutable state.
class WerewolfSetupState {
  const WerewolfSetupState({
    this.players = const [],
    this.history = const [],
    this.settings = const WerewolfSettings(vampireCount: 1),
    this.autoBalance = true,
    this.inputError,
  });

  static const int maxNameLength = 20;

  final List<Player> players;

  /// Cihazda kayıtlı geçmiş oyuncu isimleri (tüm oyunlarla ortak).
  final List<String> history;

  final WerewolfSettings settings;

  /// `true` iken rol dağılımı oyuncu sayısına göre otomatik hesaplanır.
  /// Kullanıcı bir rolü elle değiştirince `false` olur.
  final bool autoBalance;

  /// Son isim ekleme denemesinin hatası (`null` ise hata yok).
  final String? inputError;

  int get playerCount => players.length;

  bool get canAddPlayer => players.length < WerewolfSettings.maxPlayers;

  /// Rol dağılımı / oyuncu sayısı hatası (`null` ise oyun başlatılabilir).
  String? get setupError => settings.validate(playerCount);

  bool get canStart => setupError == null;

  int get villagerCount => settings.villagerCountFor(playerCount);

  int get maxVampires => WerewolfSettings.maxVampiresFor(playerCount);

  /// Henüz eklenmemiş geçmiş isimleri.
  List<String> get availableHistory {
    final active = players.map((p) => p.name.toLowerTr()).toSet();
    return history
        .where((name) => !active.contains(name.toLowerTr()))
        .toList(growable: false);
  }

  WerewolfSetupState copyWith({
    List<Player>? players,
    List<String>? history,
    WerewolfSettings? settings,
    bool? autoBalance,
    String? inputError,
    bool clearInputError = false,
  }) {
    return WerewolfSetupState(
      players: players ?? this.players,
      history: history ?? this.history,
      settings: settings ?? this.settings,
      autoBalance: autoBalance ?? this.autoBalance,
      inputError: clearInputError ? null : (inputError ?? this.inputError),
    );
  }
}
