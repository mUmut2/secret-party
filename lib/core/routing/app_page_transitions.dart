import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Neon Ink sayfa geçişleri.
///
/// Her geçiş bir "duygu" taşır; rota tanımları ekranın anlamına göre seçer:
/// - [fade]: sakin menü gezintisi (ana menü, oyun seçimi)
/// - [fadeUp]: "hazırlık" ekranları (oyuncu kurulumu): yumuşak belirip yükselir
/// - [tensionScale]: gerilim (rol gösterme): hızlı ve sert yakınlaşma
/// - [slideForward]: oyunun ilerlediği an (tur): sağdan hızlı kayma
/// - [rise]: yüzleşme (oylama): alttan yükselen panel hissi
/// - [dramatic]: büyük açıklama (sonuç): esneyerek büyüyen giriş
///
/// Sistemde "hareketi azalt" açıksa tüm geçişler [fade]'e düşer.
enum AppPageTransition {
  fade,
  fadeUp,
  tensionScale,
  slideForward,
  rise,
  dramatic
}

const double _fadeUpOffset = 0.04;
const double _tensionScaleStart = 1.08;
const double _slideForwardOffset = 0.25;
const double _riseOffset = 0.12;
const double _dramaticScaleStart = 0.85;

/// Rota sayfası üretir. Tüm `GoRoute.pageBuilder`'lar bunu kullanır, böylece
/// süre, eğri ve zemin rengi tek yerden tutarlı kalır.
CustomTransitionPage<void> buildTransitionPage({
  required GoRouterState state,
  required Widget child,
  required AppPageTransition transition,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    child: child,
    transitionDuration: _enterDuration(transition),
    reverseTransitionDuration: AppMotion.base,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Geçiş sırasında altta "beyaz" flaş görünmesin diye zemin hep koyu.
      final page = ColoredBox(color: AppColors.background, child: child);
      // Hareketi azalt açıksa kayma / ölçek yok; yalnızca yumuşak belirme.
      if (AppMotion.reduceMotion(context)) {
        return _buildTransition(AppPageTransition.fade, animation, page);
      }
      return _buildTransition(transition, animation, page);
    },
  );
}

Duration _enterDuration(AppPageTransition transition) {
  switch (transition) {
    case AppPageTransition.fade:
    case AppPageTransition.fadeUp:
      return AppMotion.slow;
    case AppPageTransition.tensionScale:
    case AppPageTransition.slideForward:
      // Gerilim anları kısa ve keskin.
      return AppMotion.base;
    case AppPageTransition.rise:
      return AppMotion.slow;
    case AppPageTransition.dramatic:
      return AppMotion.dramatic;
  }
}

Widget _buildTransition(
  AppPageTransition transition,
  Animation<double> animation,
  Widget child,
) {
  switch (transition) {
    case AppPageTransition.fade:
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: AppMotion.standardCurve,
        ),
        child: child,
      );

    case AppPageTransition.fadeUp:
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.standardCurve,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, _fadeUpOffset),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );

    case AppPageTransition.tensionScale:
      // Hafif büyükten normale "çarpma" + hızlı belirme: kameranın aniden
      // odaklanması gibi.
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: _tensionScaleStart, end: 1.0)
              .animate(curved),
          child: child,
        ),
      );

    case AppPageTransition.slideForward:
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(_slideForwardOffset, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );

    case AppPageTransition.rise:
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.standardCurve,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, _riseOffset),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );

    case AppPageTransition.dramatic:
      // Opaklık hızlı gelir, ölçek esneyerek oturur (elasticOut değer
      // 1.0'ı aşabilir; bu yüzden opaklıkta kullanılmaz).
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.4, curve: Curves.easeOut),
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: _dramaticScaleStart, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: AppMotion.dramaticCurve,
            ),
          ),
          child: child,
        ),
      );
  }
}
