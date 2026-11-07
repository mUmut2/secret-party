import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Sistem geri tuşunu (Android tuşu / iOS kenar kaydırma) mantıksal bir üst
/// ekrana yönlendirir.
///
/// Rotalar `context.go` ile değiştirildiği için yığında tek sayfa bulunur;
/// koruma olmadan geri tuşu uygulamayı doğrudan kapatırdı. Menü ve kurulum
/// ekranları bu sarmalayıcıyla [fallbackRoute]'a (örn. Oyun Seçimi) döner.
/// Oyun ekranları ise bunun yerine çıkış onayı sorar (`confirmExitGame`).
class AppBackGuard extends StatelessWidget {
  const AppBackGuard({
    super.key,
    required this.fallbackRoute,
    required this.child,
  });

  final String fallbackRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(fallbackRoute);
      },
      child: child,
    );
  }
}
