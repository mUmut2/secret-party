import 'package:flutter/material.dart';

/// Gölge ve glow değerlerinin tek kaynağı.
///
/// Glow'lar bilinçli olarak hafif tutulur: vurgu verir ama "patlamaz".
class AppShadows {
  AppShadows._();

  /// Ekranlardaki tüm renkli parlamaların ortak yoğunluk çarpanı. Bir
  /// ekranın istediği alfa bununla çarpılır; parlamayı tek yerden ayarlamak
  /// için yalnızca bu değer değiştirilir.
  static const double glowIntensity = 0.5;

  /// [color] renginde, [alpha] × [glowIntensity] opaklıkta parlama rengi.
  static Color glow(Color color, double alpha) =>
      color.withValues(alpha: (alpha * glowIntensity).clamp(0.0, 1.0));

  /// Standart kart.
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Modal, dialog gibi en üst katman.
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x59000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  /// Lime glow (vurgulanan / seçili eleman).
  static const List<BoxShadow> glowPrimary = [
    BoxShadow(
      color: Color(0x33B5E352),
      blurRadius: 14,
      offset: Offset(0, 0),
    ),
  ];

  /// Fuşya glow.
  static const List<BoxShadow> glowSecondary = [
    BoxShadow(
      color: Color(0x33E8609F),
      blurRadius: 14,
      offset: Offset(0, 0),
    ),
  ];

  /// Kehribar glow (uyarı, pas vb.).
  static const List<BoxShadow> glowWarning = [
    BoxShadow(
      color: Color(0x33F0B955),
      blurRadius: 14,
      offset: Offset(0, 0),
    ),
  ];

  /// Mor gece glow'u (Vampir Köylü gece fazı).
  static const List<BoxShadow> glowNight = [
    BoxShadow(
      color: Color(0x339486EC),
      blurRadius: 16,
      offset: Offset(0, 0),
    ),
  ];

  /// Kırmızı glow (Imposter vb.).
  static const List<BoxShadow> glowError = [
    BoxShadow(
      color: Color(0x33E5586E),
      blurRadius: 14,
      offset: Offset(0, 0),
    ),
  ];
}
