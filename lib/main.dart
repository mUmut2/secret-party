import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_error_handling.dart';
import 'app/party_game_app.dart';
import 'data/repositories/local_storage_repository.dart';

Future<void> main() async {
  // Yakalanmamış asenkron hatalar da kaydedilir; uygulama kapanmaz.
  runZonedGuarded<Future<void>>(
    () async {
      // Yayın sürümünde konsola hiçbir kayıt yazılmaz (debugPrint dahil).
      if (kReleaseMode) debugPrint = (String? message, {int? wrapWidth}) {};

      WidgetsFlutterBinding.ensureInitialized();
      AppErrorHandling.install();

      // Parti oyunlarında telefon elden ele gezerken ekran yatay dönüp
      // arayüzü bozmasın: uygulama dikey moda sabitlenir.
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      // Kalıcı veriler ilk kareden önce bir kez yüklenir; sonrasında tüm
      // okumalar senkron yapılır (bkz. `sharedPreferencesProvider`).
      final preferences = await SharedPreferences.getInstance();

      runApp(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
          child: const PartyGameApp(),
        ),
      );
    },
    AppErrorHandling.report,
  );
}
