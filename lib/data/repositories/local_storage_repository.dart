import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/turkish_text.dart';
import '../../domain/models/app_preferences.dart';

/// Cihazda kalıcı tutulan küçük verilere (oyuncu geçmişi, uygulama
/// tercihleri, oyun ayarları, görülen içerik geçmişi) erişimin TEK soyutlaması.
///
/// Tüketen kodlar verinin nerede saklandığını bilmez. Okuma senkrondur: veri
/// uygulama açılışında bir kez belleğe yüklenir, böylece ekranlar ilk karede
/// geçmişi gösterebilir. Yazma asenkrondur ve arayüzü bekletmez.
abstract class LocalStorageRepository {
  /// Geçmişte tutulacak en fazla isim sayısı. Daha eskiler silinir.
  static const int maxPlayerHistory = 24;

  /// Kayıtlı oyuncu isimleri; en son kullanılan en başta.
  List<String> loadPlayerHistory();

  /// Geçmişi verilen listeyle değiştirir (tekrarlar ve boşluklar temizlenir,
  /// liste [maxPlayerHistory] ile sınırlanır). Kaydedilen son hali döner.
  Future<List<String>> savePlayerHistory(List<String> names);

  /// İsimleri geçmişin en başına taşır (zaten varsa yeri güncellenir).
  /// Kaydedilen son hali döner.
  Future<List<String>> rememberPlayers(List<String> names);

  /// Tek bir ismi geçmişten siler (Türkçe büyük/küçük harf duyarsız).
  /// Kaydedilen son hali döner.
  Future<List<String>> forgetPlayer(String name);

  /// Tüm oyuncu geçmişini siler.
  Future<void> clearPlayerHistory();

  /// Kayıtlı uygulama tercihleri (kayıt yoksa varsayılanlar).
  AppPreferences loadPreferences();

  /// Uygulama tercihlerini kaydeder.
  Future<void> savePreferences(AppPreferences preferences);

  /// Kayıtlı Imposter oyun ayarları (HAM değerler).
  ///
  /// Kayıt yoksa ya da türü bozuksa ilgili alan `null` döner; değerin hâlâ
  /// geçerli olup olmadığına (örn. kategori kaldırılmış mı) çağıran karar
  /// verir. Okuma asla hata fırlatmaz.
  ImposterSettingsRecord loadImposterSettings();

  /// Imposter oyun ayarlarını kaydeder. [categoryId] `null` = "Karışık".
  Future<void> saveImposterSettings(ImposterSettingsRecord settings);

  /// Daha önce oynanan içerik anahtarları (kelime / kart / görev), en eski
  /// en başta. Kayıt yoksa ya da bozuksa boş liste döner; asla hata fırlatmaz.
  List<String> loadSeenContent();

  /// Görülen içerik anahtarlarını kaydeder.
  Future<void> saveSeenContent(List<String> keys);

  /// Kayıtlı Tik Tak Bomba ayarları (HAM değerler; bozuk alan `null`).
  BombSettingsRecord loadBombSettings();

  /// Tik Tak Bomba ayarlarını kaydeder. [categoryId] `null` = "Karışık".
  Future<void> saveBombSettings(BombSettingsRecord settings);
}

/// Tik Tak Bomba ayarlarının cihazda saklanan ham hali.
typedef BombSettingsRecord = ({
  String? fuse,
  int? rounds,
  String? categoryId,
});

/// Imposter oyun ayarlarının cihazda saklanan ham hali.
typedef ImposterSettingsRecord = ({
  String? categoryId,
  int? roundDurationSeconds,
  bool? giveImposterHint,
});

/// [LocalStorageRepository]'nin `shared_preferences` tabanlı uygulaması.
class SharedPreferencesStorageRepository implements LocalStorageRepository {
  SharedPreferencesStorageRepository(this._preferences);

  final SharedPreferences _preferences;

  /// Anahtarlar sürümlüdür: veri biçimi değişirse yeni anahtara geçilir,
  /// eski kayıtlar uygulamayı bozmaz.
  static const String _playerHistoryKey = 'player_history_v1';
  static const String _hapticsKey = 'pref_haptics_enabled_v1';
  static const String _soundKey = 'pref_sound_enabled_v1';
  static const String _imposterCategoryKey = 'imposter_category_v1';
  static const String _imposterDurationKey = 'imposter_duration_v1';
  static const String _imposterHintKey = 'imposter_hint_enabled_v1';
  static const String _seenContentKey = 'seen_content_v1';
  static const String _bombFuseKey = 'bomb_fuse_v1';
  static const String _bombRoundsKey = 'bomb_rounds_v1';
  static const String _bombCategoryKey = 'bomb_category_v1';

  @override
  List<String> loadPlayerHistory() {
    final stored = _preferences.getStringList(_playerHistoryKey);
    if (stored == null) return const [];
    // Elle bozulmuş / eski sürümden kalmış veriye karşı her okumada temizlenir.
    return List.unmodifiable(_normalize(stored));
  }

  @override
  Future<List<String>> savePlayerHistory(List<String> names) async {
    final normalized = _normalize(names);
    await _preferences.setStringList(_playerHistoryKey, normalized);
    return List.unmodifiable(normalized);
  }

  @override
  Future<List<String>> rememberPlayers(List<String> names) {
    return savePlayerHistory([...names, ...loadPlayerHistory()]);
  }

  @override
  Future<List<String>> forgetPlayer(String name) {
    final key = name.trim().toLowerTr();
    return savePlayerHistory(
      loadPlayerHistory().where((n) => n.toLowerTr() != key).toList(),
    );
  }

  @override
  Future<void> clearPlayerHistory() async {
    await _preferences.remove(_playerHistoryKey);
  }

  @override
  AppPreferences loadPreferences() {
    const defaults = AppPreferences();
    return AppPreferences(
      hapticsEnabled:
          _preferences.getBool(_hapticsKey) ?? defaults.hapticsEnabled,
      soundEnabled: _preferences.getBool(_soundKey) ?? defaults.soundEnabled,
    );
  }

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    await _preferences.setBool(_hapticsKey, preferences.hapticsEnabled);
    await _preferences.setBool(_soundKey, preferences.soundEnabled);
  }

  @override
  ImposterSettingsRecord loadImposterSettings() {
    return (
      categoryId: _read(() => _preferences.getString(_imposterCategoryKey)),
      roundDurationSeconds:
          _read(() => _preferences.getInt(_imposterDurationKey)),
      giveImposterHint: _read(() => _preferences.getBool(_imposterHintKey)),
    );
  }

  @override
  Future<void> saveImposterSettings(ImposterSettingsRecord settings) async {
    final categoryId = settings.categoryId;
    if (categoryId == null) {
      await _preferences.remove(_imposterCategoryKey);
    } else {
      await _preferences.setString(_imposterCategoryKey, categoryId);
    }
    final duration = settings.roundDurationSeconds;
    if (duration != null) {
      await _preferences.setInt(_imposterDurationKey, duration);
    }
    final hint = settings.giveImposterHint;
    if (hint != null) {
      await _preferences.setBool(_imposterHintKey, hint);
    }
  }

  @override
  List<String> loadSeenContent() {
    final stored = _read(() => _preferences.getStringList(_seenContentKey));
    if (stored == null) return const [];
    return List.unmodifiable(stored.where((key) => key.isNotEmpty));
  }

  @override
  Future<void> saveSeenContent(List<String> keys) async {
    if (keys.isEmpty) {
      await _preferences.remove(_seenContentKey);
    } else {
      await _preferences.setStringList(_seenContentKey, keys);
    }
  }

  @override
  BombSettingsRecord loadBombSettings() {
    return (
      fuse: _read(() => _preferences.getString(_bombFuseKey)),
      rounds: _read(() => _preferences.getInt(_bombRoundsKey)),
      categoryId: _read(() => _preferences.getString(_bombCategoryKey)),
    );
  }

  @override
  Future<void> saveBombSettings(BombSettingsRecord settings) async {
    final fuse = settings.fuse;
    if (fuse != null) await _preferences.setString(_bombFuseKey, fuse);
    final rounds = settings.rounds;
    if (rounds != null) await _preferences.setInt(_bombRoundsKey, rounds);
    final categoryId = settings.categoryId;
    if (categoryId == null) {
      await _preferences.remove(_bombCategoryKey);
    } else {
      await _preferences.setString(_bombCategoryKey, categoryId);
    }
  }

  /// Değeri okur; anahtar başka türde kaydedilmişse (bozuk / eski sürüm)
  /// hata fırlatmak yerine `null` döner.
  T? _read<T>(T? Function() read) {
    try {
      return read();
    } on Object {
      return null;
    }
  }

  /// Boş isimleri atar, baştaki/sondaki boşlukları kırpar, tekrarları
  /// (Türkçe büyük/küçük harf duyarsız) ilk görüleni koruyarak eler ve
  /// listeyi en fazla [LocalStorageRepository.maxPlayerHistory] ile sınırlar.
  List<String> _normalize(Iterable<String> names) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in names) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      if (!seen.add(name.toLowerTr())) continue;
      result.add(name);
      if (result.length == LocalStorageRepository.maxPlayerHistory) break;
    }
    return result;
  }
}

/// Uygulama açılışında `main()` içinde yüklenen [SharedPreferences] örneği.
///
/// Kasıtlı olarak `ProviderScope.overrides` ile doldurulur; böylece tüm
/// okumalar senkron olur. Override edilmezse açık bir hata fırlatır.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider main() içinde override edilmelidir.',
  );
});

final localStorageRepositoryProvider = Provider<LocalStorageRepository>((ref) {
  return SharedPreferencesStorageRepository(
    ref.watch(sharedPreferencesProvider),
  );
});
