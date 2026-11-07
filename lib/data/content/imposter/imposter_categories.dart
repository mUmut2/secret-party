import 'esyalar.dart';
import 'filmler.dart';
import 'hayvanlar.dart';
import 'imposter_word.dart';
import 'markalar.dart';
import 'mekanlar.dart';
import 'meslekler.dart';
import 'meyve_sebzeler.dart';
import 'ulkeler.dart';
import 'okul_ofis.dart';
import 'spor_dallari.dart';
import 'unluler.dart';
import 'yemekler.dart';

/// Kategori id → kelimeler (ekranda gösterim sırasıyla).
///
/// Kategori id'leri kullanıcıya gösterilen Türkçe adlardır (küçük harfle);
/// ekranda baş harfi büyütülür. Yeni kategori: ayrı bir dosya + buraya kayıt.
const Map<String, List<ImposterWord>> imposterWordsByCategory = {
  'hayvanlar': hayvanlarWords,
  'mekanlar': mekanlarWords,
  'filmler': filmlerWords,
  'yemekler': yemeklerWords,
  'meslekler': mesleklerWords,
  'ünlüler': unlulerWords,
  'meyve ve sebzeler': meyveSebzelerWords,
  'ülkeler': ulkelerWords,
  'eşyalar': esyalarWords,
  'spor dalları': sporDallariWords,
  'okul ve ofis': okulOfisWords,
  'markalar': markalarWords,
};
