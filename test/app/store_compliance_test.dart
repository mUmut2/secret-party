import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/app/app_viewport.dart';
import 'package:party_game/core/config/app_info.dart';
import 'package:party_game/core/services/haptic_service.dart';
import 'package:party_game/core/theme/app_motion.dart';
import 'package:party_game/core/theme/app_spacing.dart';
import 'package:party_game/core/theme/app_theme.dart';
import 'package:party_game/core/widgets/app_tap_target.dart';
import 'package:party_game/data/repositories/local_storage_repository.dart';
import 'package:party_game/features/home/views/home_screen.dart';
import 'package:party_game/features/settings/views/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mağaza incelemesi ve erişilebilirlik korumaları.
void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(375, 812),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          hapticServiceProvider.overrideWithValue(
            const HapticService(enabled: false),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => AppViewport(child: child!),
          home: screen,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('ana ekranda "Yakında" / kilitli oyun kartı yok', (tester) async {
    await pumpScreen(tester, const HomeScreen());
    expect(find.textContaining('Yakında'), findsNothing);
    expect(find.textContaining('yakında'), findsNothing);
  });

  testWidgets('bağlantı değerleri boşken ölü butonlar gösterilmez',
      (tester) async {
    await pumpScreen(tester, const SettingsScreen());
    await tester.scrollUntilVisible(find.text('Hakkında'), 200);
    expect(
      find.text('Uygulamayı Değerlendir'),
      AppInfo.playStoreUrl.isEmpty ? findsNothing : findsOneWidget,
    );
    expect(
      find.text('Geri Bildirim / İletişim'),
      AppInfo.supportEmail.isEmpty ? findsNothing : findsOneWidget,
    );
    expect(find.textContaining('hak sahiplerine aittir'), findsOneWidget);
  });

  testWidgets('tablette içerik azami genişlikte ortalanır', (tester) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      size: const Size(1024, 1366),
    );
    expect(tester.takeException(), isNull);
    final scaffold = tester.getRect(find.byType(Scaffold));
    expect(scaffold.width, AppLayout.maxContentWidth);
    expect(scaffold.center.dx, 512);
  });

  testWidgets('küçük dokunma hedefleri en az 48dp', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: AppTapTarget(
            semanticLabel: 'Sil',
            onTap: () {},
            child: const Icon(Icons.close, size: 16),
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(AppTapTarget));
    expect(size.width, greaterThanOrEqualTo(AppLayout.minTapTarget));
    expect(size.height, greaterThanOrEqualTo(AppLayout.minTapTarget));
  });

  testWidgets('hareketi azalt açıkken büyük animasyonlar anında biter',
      (tester) async {
    late Duration normal;
    late Duration reduced;
    await tester.pumpWidget(
      Column(
        children: [
          Builder(
            builder: (context) {
              normal = AppMotion.resolve(context, AppMotion.dramatic);
              return const SizedBox();
            },
          ),
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                reduced = AppMotion.resolve(context, AppMotion.dramatic);
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
    expect(normal, AppMotion.dramatic);
    expect(reduced, Duration.zero);
  });
}
