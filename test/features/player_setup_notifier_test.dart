import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/core/services/haptic_service.dart';
import 'package:party_game/data/repositories/local_storage_repository.dart';
import 'package:party_game/features/players/viewmodels/player_setup_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<(ProviderContainer, SharedPreferences)> createContainer([
    List<String> history = const [],
  ]) async {
    SharedPreferences.setMockInitialValues({'player_history_v1': history});
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

  test('açılışta kayıtlı geçmiş yüklenir', () async {
    final (container, _) = await createContainer(['Ayşe', 'Burak']);
    expect(container.read(playerSetupProvider).history, ['Ayşe', 'Burak']);
  });

  test('geçmişten seçilen isim aktif listeye eklenir ve listeden düşer',
      () async {
    final (container, _) = await createContainer(['Ayşe', 'Burak']);
    final added =
        container.read(playerSetupProvider.notifier).addFromHistory('Ayşe');

    final state = container.read(playerSetupProvider);
    expect(added, isTrue);
    expect(state.players.map((p) => p.name), ['Ayşe']);
    expect(state.availableHistory, ['Burak']);
  });

  test('elle eklenen isim geçmişe kaydedilir', () async {
    final (container, preferences) = await createContainer(['Ayşe']);
    container.read(playerSetupProvider.notifier).addPlayer('Cem');
    await pumpEventQueue();

    expect(container.read(playerSetupProvider).history, ['Cem', 'Ayşe']);
    expect(preferences.getStringList('player_history_v1'), ['Cem', 'Ayşe']);
  });

  test('aynı isim farklı harf büyüklüğüyle iki kez eklenemez', () async {
    final (container, _) = await createContainer();
    final notifier = container.read(playerSetupProvider.notifier);

    expect(notifier.addPlayer('Işık'), isTrue);
    expect(notifier.addPlayer('IŞIK'), isFalse);
    expect(
      container.read(playerSetupProvider).errorMessage,
      'Bu isim zaten eklendi.',
    );
  });

  test('geçmişten silinen isim kalıcı olarak kaldırılır', () async {
    final (container, preferences) = await createContainer(['Ayşe', 'Burak']);
    container.read(playerSetupProvider.notifier).forgetFromHistory('Ayşe');
    await pumpEventQueue();

    expect(container.read(playerSetupProvider).history, ['Burak']);
    expect(preferences.getStringList('player_history_v1'), ['Burak']);
  });

  test('oyun başlarken kadro ekleme sırasıyla geçmişin başına taşınır',
      () async {
    final (container, preferences) = await createContainer(['Eski', 'Burak']);
    final notifier = container.read(playerSetupProvider.notifier)
      ..addPlayer('Ayşe')
      ..addPlayer('Burak');
    notifier.rememberCurrentPlayers();
    await pumpEventQueue();

    expect(
      preferences.getStringList('player_history_v1'),
      ['Ayşe', 'Burak', 'Eski'],
    );
  });
}
