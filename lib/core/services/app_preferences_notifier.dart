import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/local_storage_repository.dart';
import '../../domain/models/app_preferences.dart';

/// Uygulama geneli tercihleri (titreşim, ses efektleri) tutan Notifier.
///
/// Açılışta cihazdan senkron okunur, her değişiklikte arka planda kaydedilir.
/// `HapticService` ve `AudioService` bu tercihleri izler; anahtar kapatıldığı
/// an tüm oyunlarda titreşim / ses kesilir.
class AppPreferencesNotifier extends Notifier<AppPreferences> {
  @override
  AppPreferences build() {
    try {
      return ref.read(localStorageRepositoryProvider).loadPreferences();
    } on UnimplementedError {
      // Depolama henüz bağlanmamışsa (örn. izole widget testleri) varsayılan
      // tercihlerle devam edilir; uygulamada `main()` her zaman bağlar.
      return const AppPreferences();
    }
  }

  void setHapticsEnabled(bool enabled) =>
      _save(state.copyWith(hapticsEnabled: enabled));

  void setSoundEnabled(bool enabled) =>
      _save(state.copyWith(soundEnabled: enabled));

  void _save(AppPreferences next) {
    state = next;
    unawaited(
      ref
          .read(localStorageRepositoryProvider)
          .savePreferences(next)
          .catchError((Object error) {
        debugPrint('Tercihler kaydedilemedi: $error');
      }),
    );
  }
}

final appPreferencesProvider =
    NotifierProvider<AppPreferencesNotifier, AppPreferences>(
  AppPreferencesNotifier.new,
);
