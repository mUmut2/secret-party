import 'package:flutter/material.dart';

/// Animasyon süre ve eğrilerinin tek kaynağı.
///
/// - [fast]: buton basma gibi küçük geri bildirimler
/// - [base]: kart seçimi, standart geçişler
/// - [slow]: ekran / zemin geçişleri
/// - [dramatic]: SADECE büyük anlar (rol açıklama, süre bitti)
///
/// Sistemde "hareketi azalt / animasyonları kaldır" açıksa büyük hareketler
/// [resolve] ile anında tamamlanır.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration dramatic = Duration(milliseconds: 550);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve dramaticCurve = Curves.elasticOut;

  /// Kullanıcı hareketi azaltmak istiyor mu? (iOS "Hareketi Azalt",
  /// Android "Animasyonları kaldır")
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Hareketi azalt açıksa [Duration.zero], değilse [duration].
  static Duration resolve(BuildContext context, Duration duration) =>
      reduceMotion(context) ? Duration.zero : duration;
}
