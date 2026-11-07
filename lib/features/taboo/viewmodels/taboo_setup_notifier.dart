import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/taboo_settings.dart';
import 'taboo_setup_state.dart';

/// Tabu kurulum ayarlarını (takım isimleri, süre, pas limiti, hedef skor)
/// tutan Notifier.
///
/// Sadece listede sunulan seçenekler kabul edilir; böylece ekran dışından
/// gelen geçersiz bir değer oyun motoruna ulaşamaz.
class TabooSetupNotifier extends Notifier<TabooSetupState> {
  @override
  TabooSetupState build() => const TabooSetupState();

  void setTeamAName(String value) {
    state = state.copyWith(teamAInput: value);
  }

  void setTeamBName(String value) {
    state = state.copyWith(teamBInput: value);
  }

  void setRoundDuration(int seconds) {
    if (!TabooSettings.roundDurationOptions.contains(seconds)) return;
    state = state.copyWith(roundDurationSeconds: seconds);
  }

  void setPassLimit(int limit) {
    if (!TabooSettings.passLimitOptions.contains(limit)) return;
    state = state.copyWith(passLimit: limit);
  }

  void setTargetScore(int score) {
    if (!TabooSettings.targetScoreOptions.contains(score)) return;
    state = state.copyWith(targetScore: score);
  }
}

final tabooSetupProvider =
    NotifierProvider<TabooSetupNotifier, TabooSetupState>(
  TabooSetupNotifier.new,
);
