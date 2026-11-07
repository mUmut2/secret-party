import 'dart:async';
import 'dart:collection';
import 'dart:math';

/// Görülen içerik anahtarlarının kalıcı deposu (soyutlama).
///
/// Uygulamada `LocalStorageRepository` üzerinden cihazda saklanır; testlerde
/// [InMemorySeenContentStore] verilir.
abstract class SeenContentStore {
  /// Kayıtlı anahtarlar, en eski en başta. Kayıt yoksa ya da bozuksa boş.
  List<String> load();

  /// Anahtar listesini (en eski en başta) kaydeder.
  Future<void> save(List<String> keys);
}

/// Bellekte tutulan depo (testler için).
class InMemorySeenContentStore implements SeenContentStore {
  InMemorySeenContentStore([List<String> initial = const []])
      : keys = [...initial];

  List<String> keys;

  @override
  List<String> load() => List.unmodifiable(keys);

  @override
  Future<void> save(List<String> keys) async => this.keys = [...keys];
}

/// "Daha önce görülenler" hafızası: aynı kelime / kart / görev, seçilen havuz
/// tükenmeden tekrar gelmesin.
///
/// Saf Dart'tır; rastgelelik dışarıdan verilir. Anahtarlar oyuna göre önekli
/// tutulur (bkz. [imposterKey], [tabooKey], [bombKey]); böylece tek depo tüm
/// oyunlara hizmet eder ve oyunlar birbirinin geçmişini etkilemez.
///
/// Kurallar:
/// - [pick] havuzdaki GÖRÜLMEMİŞ kayıtlar arasından rastgele seçer ve seçileni
///   görüldü olarak işaretler.
/// - Havuzun tamamı görüldüyse YALNIZCA o havuzun anahtarları sıfırlanır
///   (diğer kategorilerin / oyunların geçmişi korunur) ve seçim sürer.
/// - Kayıt en fazla [maxEntries] anahtar tutar; aşılırsa en eskiler atılır.
/// - Depo yazması arka planda yapılır; başarısız olursa oyun etkilenmez.
class SeenContentTracker {
  SeenContentTracker(this._store, {this.maxEntries = defaultMaxEntries}) {
    for (final key in _store.load()) {
      if (key.isNotEmpty) _seen.add(key);
    }
    _trim();
  }

  static const int defaultMaxEntries = 3000;

  final SeenContentStore _store;
  final int maxEntries;

  /// Ekleme sırasını koruyan küme: en eski en başta.
  final LinkedHashSet<String> _seen = LinkedHashSet<String>();

  static String imposterKey(String categoryId, String word) =>
      'imposter:$categoryId:$word';

  static String tabooKey(String targetWord) => 'taboo:$targetWord';

  static String bombKey(String prompt) => 'bomb:$prompt';

  /// Kayıtlı anahtar sayısı.
  int get length => _seen.length;

  bool isSeen(String key) => _seen.contains(key);

  /// Havuzdaki görülmemiş kayıtlar (havuz sırası korunur).
  List<T> unseenOf<T>(Iterable<T> pool, String Function(T item) keyOf) => [
        for (final item in pool)
          if (!_seen.contains(keyOf(item))) item,
      ];

  /// Havuzun tamamı görüldüyse havuzun anahtarlarını sıfırlar. Sıfırlama
  /// yapıldıysa `true` döner. Boş havuzda bir şey yapmaz.
  bool resetIfExhausted<T>(Iterable<T> pool, String Function(T item) keyOf) {
    final keys = pool.map(keyOf).toList();
    if (keys.isEmpty || !keys.every(_seen.contains)) return false;
    _seen.removeAll(keys);
    _persist();
    return true;
  }

  /// Havuzdan görülmemiş bir kaydı rastgele seçer ve görüldü işaretler.
  ///
  /// Boş havuz [ArgumentError] fırlatır (programlama hatası).
  T pick<T>(List<T> pool, String Function(T item) keyOf, Random random) {
    if (pool.isEmpty) {
      throw ArgumentError('Seçim yapılacak havuz boş.');
    }
    resetIfExhausted(pool, keyOf);
    final candidates = unseenOf(pool, keyOf);
    final picked = candidates[random.nextInt(candidates.length)];
    markSeen(keyOf(picked));
    return picked;
  }

  /// Anahtarı en yeni görülen olarak kaydeder.
  void markSeen(String key) {
    if (key.isEmpty) return;
    _seen
      ..remove(key)
      ..add(key);
    _trim();
    _persist();
  }

  /// Tüm görülen içerik geçmişini siler.
  void clear() {
    _seen.clear();
    _persist();
  }

  void _trim() {
    while (_seen.length > maxEntries) {
      _seen.remove(_seen.first);
    }
  }

  void _persist() {
    unawaited(
      _store.save(List.unmodifiable(_seen)).catchError((Object _) {
        // Geçmiş bir kolaylık; yazma hatası oyunu asla etkilememeli.
      }),
    );
  }
}
