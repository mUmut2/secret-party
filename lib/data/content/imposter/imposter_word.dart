/// Imposter havuzundaki tek kayıt: gizli kelime ve tek kelimelik ipucu.
///
/// İçerik kuralları için bkz. `LocalWordRepository` ve
/// `test/data/word_repository_test.dart`.
class ImposterWord {
  const ImposterWord(this.word, this.hint);

  final String word;
  final String hint;
}
