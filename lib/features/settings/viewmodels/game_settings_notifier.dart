import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/local_storage_repository.dart';
import '../../../domain/services/game_engine_notifier.dart';
import 'game_settings_state.dart';

/// Imposter oyun ayarlarını (kategori, tur süresi, Imposter'a ipucu) tutan
/// Notifier.
///
/// Ayarlar cihazda kalıcıdır (`LocalStorageRepository`): açılışta okunur,
/// her değişiklikte arka planda kaydedilir. Kayıtlı değer bozuk, eksik ya da
/// artık geçerli değilse (örn. kaldırılmış kategori, listede olmayan süre)
/// sessizce varsayılana dönülür; uygulama asla çökmez. Geçersiz seçimler de
/// sessizce yok sayılır.
class GameSettingsNotifier extends Notifier<GameSettingsState> {
  @override
  GameSettingsState build() {
    try {
      return _sanitize(
        ref.read(localStorageRepositoryProvider).loadImposterSettings(),
      );
    } on UnimplementedError {
      // Depolama henüz bağlanmamışsa (örn. izole widget testleri) varsayılan
      // ayarlarla devam edilir; uygulamada `main()` her zaman bağlar.
      return const GameSettingsState();
    }
  }

  /// Kategoriyi seçer. `null` = "Karışık".
  void selectCategory(String? categoryId) {
    if (categoryId != null && !_isKnownCategory(categoryId)) return;
    _save(
      state.copyWith(
        selectedCategoryId: categoryId,
        clearCategory: categoryId == null,
      ),
    );
  }

  /// Tur süresini seçer. Sadece [GameSettingsState.durationOptions]
  /// içindeki değerler kabul edilir.
  void selectDuration(int seconds) {
    if (!GameSettingsState.durationOptions.contains(seconds)) return;
    _save(state.copyWith(roundDurationSeconds: seconds));
  }

  /// "Imposter'a ipucu ver" anahtarı.
  void setGiveImposterHint(bool enabled) {
    _save(state.copyWith(giveImposterHint: enabled));
  }

  /// Kayıtlı ham değerleri doğrular; geçersiz olanı varsayılanla değiştirir.
  GameSettingsState _sanitize(ImposterSettingsRecord stored) {
    const defaults = GameSettingsState();
    final category = stored.categoryId;
    final duration = stored.roundDurationSeconds;
    return GameSettingsState(
      selectedCategoryId: category != null && _isKnownCategory(category)
          ? category
          : defaults.selectedCategoryId,
      roundDurationSeconds: duration != null &&
              GameSettingsState.durationOptions.contains(duration)
          ? duration
          : defaults.roundDurationSeconds,
      giveImposterHint: stored.giveImposterHint ?? defaults.giveImposterHint,
    );
  }

  bool _isKnownCategory(String categoryId) =>
      ref.read(wordRepositoryProvider).categoryIds.contains(categoryId);

  void _save(GameSettingsState next) {
    state = next;
    unawaited(
      ref.read(localStorageRepositoryProvider).saveImposterSettings((
        categoryId: next.selectedCategoryId,
        roundDurationSeconds: next.roundDurationSeconds,
        giveImposterHint: next.giveImposterHint,
      )).catchError((Object error) {
        debugPrint('Oyun ayarları kaydedilemedi: $error');
      }),
    );
  }
}

final gameSettingsProvider =
    NotifierProvider<GameSettingsNotifier, GameSettingsState>(
  GameSettingsNotifier.new,
);
