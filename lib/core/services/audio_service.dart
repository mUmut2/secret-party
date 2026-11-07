import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_preferences_notifier.dart';

/// Uygulamadaki TÜM ses efektlerinin tek merkezi.
///
/// Ek ses dosyası ya da paket gerektirmeden platformun kendi sistem seslerini
/// ([SystemSound]) kullanır; böylece uygulama boyutu büyümez ve sesler
/// cihazın ses/sessiz ayarlarına saygı gösterir. Kullanıcı Ayarlar'dan
/// kapatırsa ([enabled] `false`) hiçbir ses çalınmaz.
///
/// Not: Sistem sesleri platforma göre değişir (Android'de dokunma sesi
/// cihazın "dokunma sesleri" ayarı açıksa duyulur).
class AudioService {
  const AudioService({this.enabled = true});

  final bool enabled;

  /// Buton dokunuşu.
  void tap() => _play(SystemSoundType.click);

  /// Süre bitti / önemli uyarı.
  void alert() => _play(SystemSoundType.alert);

  void _play(SystemSoundType type) {
    if (!enabled) return;
    SystemSound.play(type).catchError((Object _) {
      // Ses bir süs; platform hatası oyunu asla etkilememeli.
    });
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final enabled = ref.watch(
    appPreferencesProvider.select((prefs) => prefs.soundEnabled),
  );
  return AudioService(enabled: enabled);
});
