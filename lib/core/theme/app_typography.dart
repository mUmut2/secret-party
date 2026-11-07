import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Uygulama genelindeki TÜM metin stillerinin tek kaynağı.
/// Marka fontu seçilince sadece [_fontFamily] değişecek.
class AppTypography {
  AppTypography._();

  static const String? _fontFamily = null; // null = platform varsayılanı

  /// Ekran başlıkları.
  static const TextStyle display = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// Bölüm başlıkları.
  static const TextStyle headline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
  );

  /// Kart başlıkları, oyuncu isimleri.
  static const TextStyle title = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Ana gövde metni.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// İkincil / açıklayıcı gövde metni.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );

  /// Buton etiketleri, rozetler.
  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  /// Yardımcı küçük metin.
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.25,
    color: AppColors.textSecondary,
  );

  /// Oyunun doruk anları için (rol açıklama, "SÜRE BİTTİ!").
  static const TextStyle gameDisplay = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: 1.0,
    color: AppColors.textPrimary,
  );

  /// Geri sayım sayacı. `tabularFigures` sayesinde rakamlar sağa sola titremez.
  static const TextStyle timerDisplay = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 96,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -2.0,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
