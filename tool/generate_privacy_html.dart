import 'dart:io';

import 'privacy_policy_html.dart';

/// Gizlilik politikası web sayfasını uygulama içi metinden yeniden üretir.
///
/// `lib/core/config/app_info.dart` içindeki geliştirici adı, e-posta ve tarih
/// doldurulduktan sonra çalıştırın:
///   dart run tool/generate_privacy_html.dart
void main() {
  final file = File('docs/gizlilik-politikasi.html');
  file.writeAsStringSync(renderPrivacyPolicyHtml());
  stdout.writeln('${file.path} güncellendi.');
}
