import '../../../domain/services/game_engine.dart';

/// Oyun başlamadan önce seçilen tercihler (immutable).
class GameSettingsState {
  const GameSettingsState({
    this.selectedCategoryId,
    this.roundDurationSeconds = defaultRoundDurationSeconds,
    this.giveImposterHint = false,
  });

  /// Seçilebilir tur süreleri (saniye).
  static const List<int> durationOptions = [60, 90, 120, 180];

  static const int defaultRoundDurationSeconds =
      GameEngine.defaultRoundDurationSeconds;

  /// Seçili kategori id'si. `null` ise "Karışık" (her oyunda rastgele kategori).
  final String? selectedCategoryId;

  /// Tur süresi (saniye).
  final int roundDurationSeconds;

  /// Imposter'a gizli kelimeyle ilgili tek kelimelik ipucu verilsin mi?
  /// Varsayılan KAPALI.
  final bool giveImposterHint;

  bool get isMixedCategory => selectedCategoryId == null;

  GameSettingsState copyWith({
    String? selectedCategoryId,
    bool clearCategory = false,
    int? roundDurationSeconds,
    bool? giveImposterHint,
  }) {
    return GameSettingsState(
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      roundDurationSeconds: roundDurationSeconds ?? this.roundDurationSeconds,
      giveImposterHint: giveImposterHint ?? this.giveImposterHint,
    );
  }
}
