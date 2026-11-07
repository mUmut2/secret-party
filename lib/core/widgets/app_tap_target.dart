import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Küçük ikon / metin bağlantıları için erişilebilir dokunma alanı.
///
/// Görsel öğe küçük kalsa da dokunulabilir alan en az
/// [AppLayout.minTapTarget] (48dp) olur; öğe bu alanın ortasında durur.
/// Üst öğe daha dar bir yükseklik dayatırsa (ör. sabit yükseklikli satır)
/// o yükseklik kullanılır, genişlik yine en az 48dp kalır.
/// Ekran okuyucu için [semanticLabel] ile düğme olarak duyurulur.
class AppTapTarget extends StatelessWidget {
  const AppTapTarget({
    super.key,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  final String semanticLabel;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppLayout.minTapTarget,
            minHeight: AppLayout.minTapTarget,
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }
}
