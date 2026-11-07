import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/data/repositories/local_storage_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferencesStorageRepository> createRepository([
    Map<String, Object> initialValues = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initialValues);
    return SharedPreferencesStorageRepository(
      await SharedPreferences.getInstance(),
    );
  }

  test('ilk açılışta geçmiş boştur', () async {
    final repository = await createRepository();
    expect(repository.loadPlayerHistory(), isEmpty);
  });

  test('kaydedilen isimler tekrar okunur', () async {
    final repository = await createRepository();
    await repository.savePlayerHistory(['Ayşe', 'Burak']);
    expect(repository.loadPlayerHistory(), ['Ayşe', 'Burak']);
  });

  test('hatırlanan isimler en başa taşınır, tekrar oluşmaz', () async {
    final repository = await createRepository();
    await repository.savePlayerHistory(['Ayşe', 'Burak', 'Cem']);

    final result = await repository.rememberPlayers(['cem', 'Deniz']);

    expect(result, ['cem', 'Deniz', 'Ayşe', 'Burak']);
    expect(repository.loadPlayerHistory(), result);
  });

  test('Türkçe büyük/küçük harf duyarsız tekrar eler', () async {
    final repository = await createRepository();
    final result =
        await repository.savePlayerHistory(['IŞIK', 'ışık', 'İpek', 'ipek']);
    expect(result, ['IŞIK', 'İpek']);
  });

  test('boş isimler ve boşluklar temizlenir', () async {
    final repository = await createRepository();
    final result = await repository.savePlayerHistory(['  Ayşe  ', '', '   ']);
    expect(result, ['Ayşe']);
  });

  test('geçmiş en fazla sınır kadar isim tutar', () async {
    final repository = await createRepository();
    final names = List.generate(
      LocalStorageRepository.maxPlayerHistory + 5,
      (i) => 'Oyuncu $i',
    );
    final result = await repository.savePlayerHistory(names);
    expect(result, hasLength(LocalStorageRepository.maxPlayerHistory));
    expect(result.first, 'Oyuncu 0');
  });

  test('tek isim silinir, diğerleri kalır', () async {
    final repository = await createRepository();
    await repository.savePlayerHistory(['Ayşe', 'Burak']);
    final result = await repository.forgetPlayer('AYŞE');
    expect(result, ['Burak']);
  });

  test('tüm geçmiş temizlenir', () async {
    final repository = await createRepository();
    await repository.savePlayerHistory(['Ayşe']);
    await repository.clearPlayerHistory();
    expect(repository.loadPlayerHistory(), isEmpty);
  });

  group('görülen içerik geçmişi', () {
    test('kayıt yoksa boş, kaydedilen okunur', () async {
      final repository = await createRepository();
      expect(repository.loadSeenContent(), isEmpty);
      await repository.saveSeenContent(['imposter:hayvanlar:Aslan']);
      expect(repository.loadSeenContent(), ['imposter:hayvanlar:Aslan']);
    });

    test('bozuk (yanlış türde) kayıtta sessizce boş başlar', () async {
      final repository = await createRepository({'seen_content_v1': 42});
      expect(repository.loadSeenContent(), isEmpty);
    });

    test('boş liste kaydı siler', () async {
      final repository = await createRepository({
        'seen_content_v1': ['taboo:Pizza'],
      });
      await repository.saveSeenContent(const []);
      expect(repository.loadSeenContent(), isEmpty);
    });
  });
}
