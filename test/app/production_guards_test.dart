import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/app/app_error_handling.dart';
import 'package:party_game/app/session_guard.dart';
import 'package:party_game/core/routing/app_router.dart';
import 'package:party_game/core/services/app_preferences_notifier.dart';
import 'package:party_game/core/services/audio_service.dart';
import 'package:party_game/core/services/haptic_service.dart';
import 'package:party_game/core/services/wakelock_service.dart';
import 'package:party_game/core/theme/app_theme.dart';
import 'package:party_game/data/repositories/local_storage_repository.dart';
import 'package:party_game/domain/models/player.dart';
import 'package:party_game/domain/models/spy/spy_settings.dart';
import 'package:party_game/domain/models/taboo_settings.dart';
import 'package:party_game/domain/services/game_engine_notifier.dart';
import 'package:party_game/features/imposter/viewmodels/round_notifier.dart';
import 'package:party_game/features/spy/viewmodels/spy_game_notifier.dart';
import 'package:party_game/features/spy/viewmodels/spy_timer_notifier.dart';
import 'package:party_game/features/taboo/viewmodels/taboo_game_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ekran açık tutma isteklerini kaydeden sahte servis.
class _RecordingWakelock extends WakelockService {
  final List<bool> calls = [];

  @override
  Future<void> setEnabled(bool enabled) async => calls.add(enabled);
}

void main() {
  final players = [
    for (final name in ['Ali', 'Ayşe', 'Can', 'Ece', 'Mert'])
      Player(id: name, name: name),
  ];

  Future<(ProviderContainer, _RecordingWakelock)> pumpApp(
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final wakelock = _RecordingWakelock();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        hapticServiceProvider.overrideWithValue(
          const HapticService(enabled: false),
        ),
        audioServiceProvider.overrideWithValue(
          const AudioService(enabled: false),
        ),
        wakelockServiceProvider.overrideWithValue(wakelock),
      ],
    );
    addTearDown(container.dispose);

    AppRouter.router.go(AppRouter.home);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: SessionGuard(
          router: AppRouter.router,
          child: MaterialApp.router(
            theme: AppTheme.dark,
            routerConfig: AppRouter.router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (container, wakelock);
  }

  testWidgets(
      'ana menüye dönülünce tüm oyunlar kapanır, sayaçlar durur ve ekran '
      'açık tutma bırakılır', (tester) async {
    final (c, wakelock) = await pumpApp(tester);

    // Üç oyunu da başlat: Imposter turu, Tabu turu, Ajan sayacı.
    c.read(gameSessionProvider.notifier)
      ..startGame(players)
      ..beginRound();
    c.read(roundProvider.notifier).start(durationSeconds: 60);
    c.read(tabooGameProvider.notifier)
      ..startGame(const TabooSettings())
      ..startTurn();
    c.read(spyGameProvider.notifier).startGame(players, const SpySettings());
    c.read(spyTimerProvider.notifier).start(360);

    AppRouter.router.go(AppRouter.round);
    await tester.pump(const Duration(seconds: 1));
    expect(wakelock.calls.last, isTrue, reason: 'Oyunda ekran açık kalmalı');

    AppRouter.router.go(AppRouter.home);
    await tester.pumpAndSettle();

    expect(wakelock.calls.last, isFalse, reason: 'Menüde ekran bırakılmalı');
    expect(c.read(gameSessionProvider), isNull);
    expect(c.read(roundProvider).isRunning, isFalse);
    expect(c.read(tabooGameProvider), isNull);
    expect(c.read(spyGameProvider), isNull);
    expect(c.read(spyTimerProvider).isRunning, isFalse);
  });

  testWidgets('kurulum ekranında oyun oturumu korunur, ekran bırakılır',
      (tester) async {
    final (c, wakelock) = await pumpApp(tester);
    c.read(spyGameProvider.notifier).startGame(players, const SpySettings());

    AppRouter.router.go(AppRouter.spySetup);
    await tester.pumpAndSettle();

    expect(wakelock.calls.last, isFalse);
    expect(c.read(spyGameProvider), isNotNull);
  });

  test('tercihler kaydedilir ve titreşim / ses servisleri kapanır', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(c.dispose);

    expect(c.read(hapticServiceProvider).enabled, isTrue);
    expect(c.read(audioServiceProvider).enabled, isTrue);

    c.read(appPreferencesProvider.notifier)
      ..setHapticsEnabled(false)
      ..setSoundEnabled(false);
    await pumpEventQueue();

    expect(c.read(hapticServiceProvider).enabled, isFalse);
    expect(c.read(audioServiceProvider).enabled, isFalse);

    // Yeniden açılışta (yeni container) tercih korunur.
    final reopened = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(reopened.dispose);
    expect(reopened.read(appPreferencesProvider).hapticsEnabled, isFalse);
    expect(reopened.read(appPreferencesProvider).soundEnabled, isFalse);
  });

  testWidgets('hata ekranı küçük telefonda dostça mesaj gösterir',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppErrorView(
        details: FlutterErrorDetails(exception: Exception('test')),
      ),
    );
    expect(find.text('Bir Şeyler Yanlış Gitti'), findsOneWidget);
    expect(find.text('ANA MENÜYE DÖN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
