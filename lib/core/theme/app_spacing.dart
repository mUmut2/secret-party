/// Boşluk (padding, margin, gap) değerlerinin tek kaynağı (8pt grid).
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Köşe yuvarlaklığı değerlerinin tek kaynağı.
class AppRadius {
  AppRadius._();

  /// Küçük rozet, chip.
  static const double s = 8;

  /// Buton, input alanı.
  static const double m = 16;

  /// Standart kart.
  static const double l = 24;

  /// Büyük panel, bottom sheet.
  static const double xl = 32;

  /// Avatar, hap şeklindeki öğeler.
  static const double full = 999;
}

/// Yerleşim ölçülerinin tek kaynağı.
class AppLayout {
  AppLayout._();

  /// Tablet / geniş ekranda içeriğin azami genişliği; içerik ortalanır.
  static const double maxContentWidth = 600;

  /// Dokunulabilir öğelerin asgari boyutu (Material 48dp, Apple 44pt).
  static const double minTapTarget = 48;
}
