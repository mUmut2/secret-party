/// Dart'ın varsayılan büyük harf dönüşümü Türkçe i/ı kurallarını bilmez
/// ("gizle" → "GIZLE" olur, doğrusu "GİZLE"). Bu extension bunu düzeltir.
extension TurkishCase on String {
  /// Tüm metni Türkçe kurallarıyla büyük harfe çevirir.
  String toUpperTr() => replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

  /// Tüm metni Türkçe kurallarıyla küçük harfe çevirir ("IŞIK" → "ışık",
  /// "İPEK" → "ipek"). Büyük/küçük harf duyarsız karşılaştırmalarda kullanılır.
  String toLowerTr() => replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

  /// Özel isme yönelme hâli ekini kesme işaretiyle ekler (ünlü uyumuna göre):
  /// "Ali" → "Ali'ye", "Can" → "Can'a", "Ayşe" → "Ayşe'ye", "Umut" → "Umut'a".
  /// İsimde ünlü yoksa (örn. kısaltma) "e" uyumu varsayılır.
  String withDativeSuffix() {
    final name = trim();
    if (name.isEmpty) return name;

    const backVowels = 'aıouAIOU';
    const frontVowels = 'eiöüEİÖÜ';
    const allVowels = '$backVowels$frontVowels';

    var lastVowel = '';
    for (var i = name.length - 1; i >= 0; i--) {
      if (allVowels.contains(name[i])) {
        lastVowel = name[i];
        break;
      }
    }
    final suffixVowel =
        backVowels.contains(lastVowel) && lastVowel.isNotEmpty ? 'a' : 'e';
    final endsWithVowel = allVowels.contains(name[name.length - 1]);
    return "$name'${endsWithVowel ? 'y' : ''}$suffixVowel";
  }

  /// Sadece ilk harfi Türkçe kurallarıyla büyük yapar ("filmler" → "Filmler",
  /// "ilginç" → "İlginç").
  String capitalizeTr() {
    if (isEmpty) return this;
    final first = this[0];
    final upperFirst = first == 'i'
        ? 'İ'
        : first == 'ı'
            ? 'I'
            : first.toUpperCase();
    return upperFirst + substring(1);
  }
}
