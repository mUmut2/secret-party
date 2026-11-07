import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Ekranın zaman aşımıyla kararmasını engelleyen servis.
///
/// Parti oyunlarında telefon elden ele gezerken ya da sayaç işlerken ekranın
/// kararması akışı bozar. Oyun ekranlarına girilince açılır, ana menüye
/// dönülünce bırakılır (bkz. `SessionGuard`). Aynı duruma tekrar geçiş
/// istekleri yok sayılır; platform hatası oyunu etkilemez.
class WakelockService {
  bool? _enabled;

  Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) return;
    _enabled = enabled;
    try {
      await WakelockPlus.toggle(enable: enabled);
    } catch (error) {
      // Desteklenmeyen platform / test ortamı: ekran açık tutma isteğe bağlı.
      debugPrint('Ekran açık tutma ayarlanamadı: $error');
    }
  }
}

final wakelockServiceProvider = Provider<WakelockService>((ref) {
  return WakelockService();
});
