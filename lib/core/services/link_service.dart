import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Dış bağlantıları (mağaza sayfası, e-posta) açar.
///
/// Boş bağlantıların butonları arayüzde hiç gösterilmez (bkz. `AppInfo`).
/// Yine de bağlantı açılamazsa (boş adres ya da cihazda açabilecek bir
/// uygulama yoksa) kullanıcıya Türkçe, nazik bir mesaj gösterilir; uygulama
/// asla hata vermez.
class LinkService {
  LinkService._();

  static const String _failedMessage =
      'Bağlantı açılamadı. Lütfen daha sonra deneyin.';

  static Future<void> open(BuildContext context, String url) async {
    if (url.isEmpty) {
      _showMessage(context, _failedMessage);
      return;
    }
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (error) {
      debugPrint('Bağlantı açılamadı: $error');
    }
    if (!opened && context.mounted) {
      _showMessage(context, _failedMessage);
    }
  }

  /// Geri bildirim e-postası taslağı açar.
  static Future<void> email(
    BuildContext context, {
    required String address,
    required String subject,
  }) {
    final url = address.isEmpty
        ? ''
        : Uri(
            scheme: 'mailto',
            path: address,
            query: 'subject=${Uri.encodeComponent(subject)}',
          ).toString();
    return open(context, url);
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          content: Text(message, style: AppTypography.bodyMedium),
        ),
      );
  }
}
