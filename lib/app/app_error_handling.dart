import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/routing/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

/// Global hata yakalama (Error Boundary).
///
/// - Flutter çerçeve hataları ([FlutterError.onError]) ve yakalanmamış
///   asenkron hatalar ([PlatformDispatcher.onError]) kaydedilir; uygulama
///   kapanmaz.
/// - Bir ekran çizilirken hata oluşursa kırmızı hata ekranı yerine
///   kullanıcı dostu "Bir Şeyler Yanlış Gitti" ekranı gösterilir
///   ([ErrorWidget.builder]).
///
/// İleride bir çökme raporlama servisi (örn. Crashlytics) eklenecekse
/// yalnızca [report] metodunun içi değişir.
class AppErrorHandling {
  AppErrorHandling._();

  static void install() {
    FlutterError.onError = (details) {
      // Geliştirmede ayrıntılı çıktı konsola basılır.
      FlutterError.presentError(details);
      report(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack);
      // true: hata ele alındı, uygulama kapanmasın.
      return true;
    };

    ErrorWidget.builder = (details) => AppErrorView(details: details);
  }

  /// Hata kaydı. Kişisel veri içermez; yalnızca hata türü ve yığın izi.
  static void report(Object error, StackTrace? stack) {
    debugPrint('Beklenmeyen hata: $error');
    if (stack != null && kDebugMode) debugPrintStack(stackTrace: stack);
  }
}

/// Ekran çizilirken oluşan hatalarda gösterilen dostça hata görünümü.
///
/// Hata ağacın küçük bir parçasında oluşursa (ör. tek bir kart) yalnızca o
/// alanı kaplar; bu yüzden dar alanlarda sade bir ikon gösterilir.
/// Bağımlılıkları bilinçli olarak en aza indirilmiştir: hatalı bir ağacın
/// içinde de güvenle çizilebilmelidir.
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.details});

  final FlutterErrorDetails details;

  static const double _compactThreshold = 220;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: AppColors.background,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < _compactThreshold ||
                constraints.maxWidth < _compactThreshold;
            if (compact) {
              return const Center(
                child: Icon(Icons.error_outline, color: AppColors.warning),
              );
            }
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sentiment_dissatisfied,
                        size: AppSpacing.xxxl,
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      const Text(
                        'Bir Şeyler Yanlış Gitti',
                        textAlign: TextAlign.center,
                        style: AppTypography.headline,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      const Text(
                        'Beklenmeyen bir hata oluştu. Ana menüye dönüp '
                        'yeniden deneyebilirsin. Oyuncu listen cihazında '
                        'güvende.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium,
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: AppSpacing.m),
                        Text(
                          details.exceptionAsString(),
                          textAlign: TextAlign.center,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.l),
                      GestureDetector(
                        onTap: () => AppRouter.router.go(AppRouter.home),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.l,
                            vertical: AppSpacing.m,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.m),
                          ),
                          child: Text(
                            'ANA MENÜYE DÖN',
                            style: AppTypography.label.copyWith(
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
