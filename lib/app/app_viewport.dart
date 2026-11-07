import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Kullanıcının sistemde seçtiği yazı boyutu bu aralıkta tutulur.
///
/// Erişilebilirlik için büyütme desteklenir; ancak oyun kartları ve sayaçlar
/// tek ekrana sığmak zorunda olduğundan aşırı büyütme sınırlandırılır.
const double _minTextScale = 0.85;
const double _maxTextScale = 1.3;

/// Uygulamanın görünür alanı: tüm rotaları (diyaloglar ve alt paneller dahil)
/// saran ortak çerçeve.
///
/// - Sistem yazı boyutunu [_minTextScale]–[_maxTextScale] aralığında tutar.
/// - Tablet / geniş ekranda içeriği [AppLayout.maxContentWidth] genişliğinde
///   ortalar; kenarlarda uygulama zemini görünür. Alt ağaç `MediaQuery`
///   genişliğini de bu sınırla görür, böylece arayüz aşırı gerilmez.
class AppViewport extends StatelessWidget {
  const AppViewport({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = math.min(mediaQuery.size.width, AppLayout.maxContentWidth);
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: SizedBox(
          width: width,
          child: MediaQuery(
            data: mediaQuery.copyWith(
              size: Size(width, mediaQuery.size.height),
              textScaler: mediaQuery.textScaler.clamp(
                minScaleFactor: _minTextScale,
                maxScaleFactor: _maxTextScale,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
