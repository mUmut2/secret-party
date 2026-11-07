/// Content sisteminden gelen tek bir gizli kelime kaydı.
class SecretWordEntry {
  const SecretWordEntry({
    required this.category,
    required this.word,
    required this.hint,
  });

  final String category;
  final String word;

  /// Kelimeyle ilgili tek kelimelik ipucu (örn. Penguen → buz).
  ///
  /// Kelimenin kendisini ya da bir parçasını içermez; çok açık olmadan gerçek
  /// bir fikir verir. İçerik kuralları `word_repository_test.dart` ile
  /// otomatik denetlenir.
  final String hint;
}
