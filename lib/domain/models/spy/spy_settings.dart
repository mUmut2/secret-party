/// Bir Ajan oyununun kurulum ayarları (immutable).
class SpySettings {
  const SpySettings({
    this.spyCount = 1,
    this.discussionSeconds = defaultDiscussionSeconds,
  });

  static const int minPlayers = 3;

  /// Her konumda 8 rol vardır; 9 oyuncuda (1 ajan) her masum benzersiz rol
  /// alabilir.
  static const int maxPlayers = 9;

  /// İki ajanlı oyun için gereken en az oyuncu.
  static const int minPlayersForTwoSpies = 6;

  static const List<int> spyCountOptions = [1, 2];

  static const int defaultDiscussionSeconds = 480;
  static const List<int> discussionOptions = [360, 480, 600];

  /// Oyundaki ajan sayısı (1 ya da 2).
  final int spyCount;

  /// Soru-cevap turunun süresi (saniye).
  final int discussionSeconds;

  /// Ayarlar oyuncu sayısıyla geçersizse Türkçe hata, geçerliyse `null`.
  String? validate(int playerCount) {
    if (playerCount < minPlayers) {
      return 'Ajan için en az $minPlayers oyuncu gerekiyor.';
    }
    if (playerCount > maxPlayers) {
      return 'En fazla $maxPlayers oyuncu oynayabilir.';
    }
    if (!spyCountOptions.contains(spyCount)) {
      return 'Ajan sayısı 1 ya da 2 olmalı.';
    }
    if (spyCount == 2 && playerCount < minPlayersForTwoSpies) {
      return 'İki ajan için en az $minPlayersForTwoSpies oyuncu gerekiyor.';
    }
    return null;
  }

  SpySettings copyWith({int? spyCount, int? discussionSeconds}) {
    return SpySettings(
      spyCount: spyCount ?? this.spyCount,
      discussionSeconds: discussionSeconds ?? this.discussionSeconds,
    );
  }
}
