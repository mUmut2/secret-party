import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/core/services/haptic_service.dart';
import 'package:party_game/core/theme/app_theme.dart';
import 'package:party_game/data/repositories/local_storage_repository.dart';
import 'package:party_game/data/repositories/seen_content_store.dart';
import 'package:party_game/features/settings/views/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Oyuncu Geçmişini Sil" oyuncu isimleriyle birlikte görülen içerik
/// geçmişini (tekrar önleme hafızası) de siler.
void main() {
  testWidgets('geçmiş silinince görülen kelime/kart geçmişi de silinir',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'player_history_v1': ['Ali'],
      'seen_content_v1': ['imposter:hayvanlar:Aslan', 'taboo:Pizza'],
    });
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        hapticServiceProvider.overrideWithValue(
          const HapticService(enabled: false),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(seenContentTrackerProvider).length, 2);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark, home: const SettingsScreen()),
      ),
    );
    await tester.pump();

    final tile = find.text('Oyuncu Geçmişini Sil');
    // Satırın altındaki öğeye kadar kaydır: satır tamamen ekranda olsun.
    await tester.scrollUntilVisible(find.text('Hakkında'), 200);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('EVET, SİL'));
    await tester.pumpAndSettle();

    expect(container.read(seenContentTrackerProvider).length, 0);
    expect(preferences.getStringList('seen_content_v1'), isNull);
    expect(preferences.getStringList('player_history_v1'), isNull);
    expect(find.text('Oyuncu ve içerik geçmişi silindi.'), findsOneWidget);
  });
}
