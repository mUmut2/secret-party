import '../../../core/utils/turkish_text.dart';
import '../../../domain/models/taboo_settings.dart';

/// Tabu kurulum ekranının okuduğu immutable state.
///
/// Takım isimleri ekranda yazıldığı haliyle (ham) tutulur; boş bırakılan
/// isim oyun başlarken varsayılan ada ("Takım A" / "Takım B") döner.
class TabooSetupState {
  const TabooSetupState({
    this.teamAInput = '',
    this.teamBInput = '',
    this.roundDurationSeconds = TabooSettings.defaultRoundDurationSeconds,
    this.passLimit = TabooSettings.defaultPassLimit,
    this.targetScore = TabooSettings.defaultTargetScore,
  });

  static const int maxTeamNameLength = 20;

  final String teamAInput;
  final String teamBInput;
  final int roundDurationSeconds;
  final int passLimit;
  final int targetScore;

  /// Boşsa varsayılan, değilse kırpılmış isim.
  String get resolvedTeamAName => _resolve(
        teamAInput,
        TabooSettings.defaultTeamAName,
      );

  String get resolvedTeamBName => _resolve(
        teamBInput,
        TabooSettings.defaultTeamBName,
      );

  /// Doğrulama hatası (`null` ise ayarlar geçerli).
  String? get errorMessage {
    if (teamAInput.trim().length > maxTeamNameLength ||
        teamBInput.trim().length > maxTeamNameLength) {
      return 'Takım adı en fazla $maxTeamNameLength karakter olabilir.';
    }
    if (resolvedTeamAName.toLowerTr() == resolvedTeamBName.toLowerTr()) {
      return 'İki takımın adı farklı olmalı.';
    }
    return null;
  }

  bool get canStart => errorMessage == null;

  /// Oyun motoruna verilecek nihai ayarlar.
  TabooSettings toSettings() => TabooSettings(
        teamAName: resolvedTeamAName,
        teamBName: resolvedTeamBName,
        roundDurationSeconds: roundDurationSeconds,
        passLimit: passLimit,
        targetScore: targetScore,
      );

  TabooSetupState copyWith({
    String? teamAInput,
    String? teamBInput,
    int? roundDurationSeconds,
    int? passLimit,
    int? targetScore,
  }) {
    return TabooSetupState(
      teamAInput: teamAInput ?? this.teamAInput,
      teamBInput: teamBInput ?? this.teamBInput,
      roundDurationSeconds: roundDurationSeconds ?? this.roundDurationSeconds,
      passLimit: passLimit ?? this.passLimit,
      targetScore: targetScore ?? this.targetScore,
    );
  }

  static String _resolve(String input, String fallback) {
    final trimmed = input.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
