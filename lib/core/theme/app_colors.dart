import 'package:flutter/material.dart';

/// PRIMITIVE LAYER: ham renk değerleri (dosya dışından erişilemez).
/// Widget'lar sadece aşağıdaki [AppColors] üzerinden renk kullanır.
class _RawColors {
  _RawColors._();

  // Neon Ink: imza vurgu renkleri. İlk sürümdeki tam doygun neon tonlar,
  // göz yormasın diye biraz yumuşatıldı (kimlik aynı, parlama daha az).
  static const Color _limePrimary = Color(0xFFB5E352);
  static const Color _limePrimaryDark = Color(0xFF98C23A);
  static const Color _fuchsiaSecondary = Color(0xFFE8609F);
  static const Color _cyanTertiary = Color(0xFF56CFE1);

  // Nötr zeminler
  static const Color _background = Color(0xFF0B0B12);
  static const Color _surface = Color(0xFF17171F);
  static const Color _surfaceElevated = Color(0xFF20202B);

  // Durum renkleri
  static const Color _success = Color(0xFF58D39B);
  static const Color _error = Color(0xFFE5586E);
  static const Color _warning = Color(0xFFF0B955);

  // Imposter rol kartı zemini: parlak kırmızı yerine koyu kırmızı.
  static const Color _deepRed = Color(0xFF7A2433);

  // Metin
  static const Color _textPrimary = Color(0xFFF5F5FA);
  static const Color _textSecondary = Color(0xFF9A9AB0);
  static const Color _textDisabled = Color(0xFF54546A);

  // Ayraç
  static const Color _divider = Color(0xFF2A2A38);

  // Gece paleti (Vampir Köylü gece fazı)
  static const Color _nightBackground = Color(0xFF070914);
  static const Color _nightSurface = Color(0xFF121633);
  static const Color _nightViolet = Color(0xFF9486EC);
  static const Color _nightIndigo = Color(0xFF6A78E0);
}

/// SEMANTIC LAYER: uygulamanın tek gerçek renk kaynağı.
class AppColors {
  AppColors._();

  /// Ana imza rengi (lime). Büyük zeminlerde değil, vurgu noktalarında kullanılır.
  static const Color primary = _RawColors._limePrimary;
  static const Color primaryPressed = _RawColors._limePrimaryDark;

  static const Color secondary = _RawColors._fuchsiaSecondary;
  static const Color tertiary = _RawColors._cyanTertiary;

  static const Color background = _RawColors._background;
  static const Color surface = _RawColors._surface;
  static const Color surfaceElevated = _RawColors._surfaceElevated;

  static const Color success = _RawColors._success;
  static const Color error = _RawColors._error;
  static const Color warning = _RawColors._warning;

  /// Imposter rol kartının zemini (koyu kırmızı). Üzerindeki beyaz metin
  /// 9:1, lime buton 6.6:1 kontrastlıdır.
  static const Color imposterReveal = _RawColors._deepRed;

  static const Color textPrimary = _RawColors._textPrimary;
  static const Color textSecondary = _RawColors._textSecondary;
  static const Color textDisabled = _RawColors._textDisabled;

  /// Lime / kehribar gibi açık zeminler üzerindeki koyu metin ve ikon rengi.
  static const Color onPrimary = Color(0xFF0B0B12);

  static const Color divider = _RawColors._divider;

  static const Color transparent = Color(0x00000000);

  /// Modal arkası / geçiş ekranları için karartma (%60 siyah).
  static const Color overlay = Color(0x99000000);

  // --- Gece paleti: SADECE gece temalı ekranlar (Vampir Köylü gece fazı) ---

  /// Gece ekranlarının zemini (lacivert-siyah).
  static const Color nightBackground = _RawColors._nightBackground;

  /// Gece ekranlarındaki kart / panel zemini (koyu lacivert).
  static const Color nightSurface = _RawColors._nightSurface;

  /// Gece vurgu rengi (mor). Lime'ın gece karşılığı.
  static const Color nightAccent = _RawColors._nightViolet;

  /// İkincil gece vurgusu (çivit).
  static const Color nightSecondary = _RawColors._nightIndigo;
}
