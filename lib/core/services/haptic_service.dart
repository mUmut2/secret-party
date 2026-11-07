import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_preferences_notifier.dart';

/// Uygulamadaki TÜM dokunsal geri bildirimlerin tek merkezi.
///
/// Flutter'ın [HapticFeedback] sınıfını sarmalar. Ekranlar ve Notifier'lar
/// doğrudan [HapticFeedback] çağırmaz; bu sayede:
/// - titreşimler tek bir yerden kapatılabilir ([enabled], Ayarlar ekranı),
/// - testlerde servis sahte bir uygulamayla değiştirilebilir,
/// - hangi anın hangi şiddette hissettirildiği tutarlı kalır.
///
/// Platform çağrıları "ateşle ve unut" şeklindedir: geri bildirim desteklenmeyen
/// cihazlarda (web, masaüstü, titreşim motoru olmayan telefonlar) sessizce hiçbir
/// şey olmaz, akış asla bekletilmez veya hata fırlatmaz.
class HapticService {
  const HapticService({this.enabled = true});

  /// `false` ise hiçbir titreşim tetiklenmez.
  final bool enabled;

  /// Kart veya seçenek seçimi gibi en hafif "tık".
  void selectionClick() => _fire(HapticFeedback.selectionClick);

  /// Standart buton dokunuşu.
  void lightImpact() => _fire(HapticFeedback.lightImpact);

  /// Orta şiddet: önemli ama dramatik olmayan anlar.
  void mediumImpact() => _fire(HapticFeedback.mediumImpact);

  /// Güçlü vuruş: rol açıklama, oylama kararı gibi dramatik anlar.
  void heavyImpact() => _fire(HapticFeedback.heavyImpact);

  /// Uzun titreşim: süre bitti gibi herkesin fark etmesi gereken uyarılar.
  void vibrate() => _fire(HapticFeedback.vibrate);

  void _fire(Future<void> Function() feedback) {
    if (!enabled) return;
    feedback().catchError((Object _) {
      // Geri bildirim bir süs; platform hatası oyunu asla etkilememeli.
    });
  }
}

/// Kullanıcı Ayarlar'dan titreşimi kapatırsa servis devre dışı kalır.
final hapticServiceProvider = Provider<HapticService>((ref) {
  final enabled = ref.watch(
    appPreferencesProvider.select((prefs) => prefs.hapticsEnabled),
  );
  return HapticService(enabled: enabled);
});
