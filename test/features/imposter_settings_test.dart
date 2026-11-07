import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/core/services/haptic_service.dart';
import 'package:party_game/data/repositories/local_storage_repository.dart';
import 'package:party_game/domain/models/player.dart';
import 'package:party_game/domain/services/game_engine.dart';
import 'package:party_game/domain/services/game_engine_notifier.dart';
import 'package:party_game/features/settings/viewmodels/game_settings_notifier.dart';
import 'package:party_game/features/settings/viewmodels/game_settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Imposter ayarlarının (kategori, süre, ipucu) kalıcılığı ve "Aynı Ekiple
/// Tekrar Oyna"nın ayarları koruması.
void main() {
  final players = [
    for (final name in ['Ali', 'Ayşe', 'Can', 'Ece'])
      Player(id: name, name: name),
  ];

  Future<(ProviderContainer, SharedPreferences)> containerWith(
    Map<String, Object> stored,
  ) async {
    SharedPreferences.setMockInitialValues(stored);
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
    return (container, preferences);
  }

  /// Aynı cihaz hafızasıyla uygulamayı "yeniden açar".
  ProviderContainer reopen(SharedPreferences preferences) {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('Tekrar Oyna', () {
    test('kategori, süre ve ipucu tercihi korunur; kelime yeniden seçilir',
        () async {
      final (c, _) = await containerWith({});
      c.read(gameSessionProvider.notifier).startGame(
            players,
            categoryId: 'hayvanlar',
            roundDurationSeconds: 90,
            giveImposterHint: true,
          );
      final first = c.read(gameSessionProvider)!;

      c.read(gameSessionProvider.notifier).restartWithSamePlayers();
      final second = c.read(gameSessionProvider)!;

      expect(second.id, isNot(first.id));
      expect(second.selectedCategoryId, 'hayvanlar');
      expect(second.category, 'hayvanlar');
      expect(second.roundDurationSeconds, 90);
      expect(second.giveImposterHint, isTrue);
      expect(second.imposterHint, isNotNull);
    });

    test('ipucu kapalıyken tekrar oyunda da ipucu yok', () async {
      final (c, _) = await containerWith({});
      c.read(gameSessionProvider.notifier)
        ..startGame(players)
        ..restartWithSamePlayers();
      expect(c.read(gameSessionProvider)!.imposterHint, isNull);
      expect(c.read(gameSessionProvider)!.giveImposterHint, isFalse);
    });
  });

  group('ayar kalıcılığı', () {
    test('varsayılanlar: Karışık, 3 dk, ipucu KAPALI', () async {
      final (c, _) = await containerWith({});
      final settings = c.read(gameSettingsProvider);
      expect(settings.selectedCategoryId, isNull);
      expect(
        settings.roundDurationSeconds,
        GameEngine.defaultRoundDurationSeconds,
      );
      expect(settings.giveImposterHint, isFalse);
    });

    test('kaydedilen ayarlar yeniden açılışta yüklenir', () async {
      final (c, preferences) = await containerWith({});
      c.read(gameSettingsProvider.notifier)
        ..selectCategory('filmler')
        ..selectDuration(120)
        ..setGiveImposterHint(true);
      await pumpEventQueue();

      final settings = reopen(preferences).read(gameSettingsProvider);
      expect(settings.selectedCategoryId, 'filmler');
      expect(settings.roundDurationSeconds, 120);
      expect(settings.giveImposterHint, isTrue);
    });

    test('Karışık seçimi de kalıcıdır', () async {
      final (c, preferences) = await containerWith({});
      c.read(gameSettingsProvider.notifier)
        ..selectCategory('filmler')
        ..selectCategory(null);
      await pumpEventQueue();
      expect(reopen(preferences).read(gameSettingsProvider).isMixedCategory,
          isTrue);
    });

    test('artık var olmayan kategori ve listede olmayan süre varsayılana döner',
        () async {
      final (c, _) = await containerWith({
        'imposter_category_v1': 'kaldirilmis_kategori',
        'imposter_duration_v1': 999,
        'imposter_hint_enabled_v1': true,
      });
      final settings = c.read(gameSettingsProvider);
      expect(settings.selectedCategoryId, isNull);
      expect(
        settings.roundDurationSeconds,
        GameSettingsState.defaultRoundDurationSeconds,
      );
      // Geçerli olan değer korunur.
      expect(settings.giveImposterHint, isTrue);
    });

    test('yanlış türde kaydedilmiş (bozuk) değerler çökmeden varsayılana döner',
        () async {
      final (c, _) = await containerWith({
        'imposter_category_v1': 42,
        'imposter_duration_v1': 'üç dakika',
        'imposter_hint_enabled_v1': 'evet',
      });
      final settings = c.read(gameSettingsProvider);
      expect(settings.selectedCategoryId, isNull);
      expect(
        settings.roundDurationSeconds,
        GameSettingsState.defaultRoundDurationSeconds,
      );
      expect(settings.giveImposterHint, isFalse);
    });

    test('geçersiz seçimler yok sayılır ve kaydedilmez', () async {
      final (c, preferences) = await containerWith({});
      c.read(gameSettingsProvider.notifier)
        ..selectCategory('yok_boyle_kategori')
        ..selectDuration(7);
      await pumpEventQueue();
      final settings = reopen(preferences).read(gameSettingsProvider);
      expect(settings.selectedCategoryId, isNull);
      expect(
        settings.roundDurationSeconds,
        GameSettingsState.defaultRoundDurationSeconds,
      );
    });
  });
}
