/// Fitil uzunluğu: her turda gizli fitil süresi bu aralıktan rastgele seçilir.
enum BombFuse {
  short(label: 'Kısa', minSeconds: 15, maxSeconds: 30),
  medium(label: 'Orta', minSeconds: 25, maxSeconds: 50),
  long(label: 'Uzun', minSeconds: 40, maxSeconds: 70);

  const BombFuse({
    required this.label,
    required this.minSeconds,
    required this.maxSeconds,
  });

  /// Ekranda gösterilen Türkçe ad.
  final String label;
  final int minSeconds;
  final int maxSeconds;

  /// Kayıtlı addan çözümler; bilinmeyen / bozuk değerde `null`.
  static BombFuse? fromName(String? name) {
    for (final fuse in values) {
      if (fuse.name == name) return fuse;
    }
    return null;
  }
}

/// Tik Tak Bomba oyun ayarları.
class BombSettings {
  const BombSettings({
    this.fuse = BombFuse.medium,
    this.rounds = defaultRounds,
    this.categoryId,
  });

  static const int minPlayers = 3;
  static const int maxPlayers = 10;

  static const List<int> roundOptions = [5, 10, 15];
  static const int defaultRounds = 10;

  final BombFuse fuse;

  /// Toplam tur sayısı (bkz. [roundOptions]).
  final int rounds;

  /// Görev kategorisi; `null` = Karışık.
  final String? categoryId;

  /// Oyuncu sayısı hatası (`null` ise oyun başlatılabilir).
  static String? validatePlayerCount(int playerCount) {
    if (playerCount < minPlayers) {
      return 'En az $minPlayers oyuncu gerekli.';
    }
    if (playerCount > maxPlayers) {
      return 'En fazla $maxPlayers oyuncu olabilir.';
    }
    return null;
  }

  BombSettings copyWith({
    BombFuse? fuse,
    int? rounds,
    String? categoryId,
    bool clearCategory = false,
  }) {
    return BombSettings(
      fuse: fuse ?? this.fuse,
      rounds: rounds ?? this.rounds,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    );
  }
}
