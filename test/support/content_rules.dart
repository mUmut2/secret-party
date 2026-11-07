import 'package:party_game/core/utils/turkish_text.dart';

/// İçerik testlerinde (Imposter ipuçları, Tabu yasaklı kelimeleri) ortak
/// kullanılan Türkçe duyarlı karşılaştırma kuralları.
///
/// Karşılaştırmalar Türkçe büyük/küçük harf (I/ı, İ/i) ve şapkalı harf
/// (â, î, û) farkları gözetilerek yapılır.

/// Karşılaştırma için normalleştirir: Türkçe küçük harf, şapkasız.
String normalizeTr(String text) => text
    .toLowerTr()
    .replaceAll('â', 'a')
    .replaceAll('î', 'i')
    .replaceAll('û', 'u')
    .trim();

/// Metnin parçaları: harf dışı karakterlerden (boşluk, nokta, kesme, tire)
/// bölünmüş, en az 2 harfli parçalar.
List<String> partsOf(String text) => normalizeTr(text)
    .split(RegExp(r'[^a-zçğıöşü]+'))
    .where((part) => part.length >= 2)
    .toList();

/// Ortak kök sezgisi: ilk 4 harfi aynı olan (en az 4 harfli) sözcükler aynı
/// kökten türemiş sayılır (örn. "taksici" / "taksimetre").
const int rootLength = 4;

bool sharesRoot(String a, String b) =>
    a.length >= rootLength &&
    b.length >= rootLength &&
    a.substring(0, rootLength) == b.substring(0, rootLength);

/// [clue] (ipucu ya da yasaklı kelime) [word]'ü sızdırıyor mu?
///
/// Kelimenin herhangi bir parçası ipucunun herhangi bir parçasını içeriyorsa,
/// tersi geçerliyse ya da ikisi ortak kökten geliyorsa sızıntı sayılır.
bool leaks(String word, String clue) {
  final clueParts = partsOf(clue);
  final wholeClue = normalizeTr(clue);
  return partsOf(word).any(
    (part) =>
        wholeClue.contains(part) ||
        clueParts.any(
          (c) => c.contains(part) || part.contains(c) || sharesRoot(part, c),
        ),
  );
}
