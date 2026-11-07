import '../../../core/utils/turkish_text.dart';

/// Tur süresini kısa Türkçe etiketle yazar: 60 → "1 dk", 90 → "1,5 dk",
/// 120 → "2 dk". Yarım dakikaya oturmayan değerler saniye olarak yazılır.
String durationLabel(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  if (rest == 0) return '$minutes dk';
  if (rest == 30) return '$minutes,5 dk';
  return '$seconds sn';
}

/// Kategori id'sini ekranda gösterilecek isme çevirir. `null` = "Karışık".
String categoryLabel(String? categoryId) {
  if (categoryId == null) return 'Karışık';
  return categoryId.capitalizeTr();
}
