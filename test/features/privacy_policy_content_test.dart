import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/features/settings/data/privacy_policy_content.dart';

import '../../tool/privacy_policy_html.dart';

/// Gizlilik politikasının uygulama içi metni ile web sayfası
/// (docs/gizlilik-politikasi.html) birebir aynı olmalı ve mağazaların /
/// KVKK'nın beklediği başlıkları içermelidir.
void main() {
  final fullText = PrivacyPolicyContent.sections
      .map((section) => '${section.title}\n${section.body}')
      .join('\n');

  test('web sayfası uygulama içi metinle birebir aynı', () {
    final html = File('docs/gizlilik-politikasi.html')
        .readAsStringSync()
        .replaceAll('\r\n', '\n');
    expect(
      html,
      renderPrivacyPolicyHtml(),
      reason: 'Metin değişti: dart run tool/generate_privacy_html.dart',
    );
  });

  test('onaylanan ayar cümlesi "saklanan bilgiler" bölümünde', () {
    final stored = PrivacyPolicyContent.sections
        .firstWhere((s) => s.title.contains('Saklanan'));
    expect(
      stored.body,
      contains('Titreşim ve ses tercihleriniz ile oyun ayarlarınız '
          '(kategori, süre, ipucu tercihi; Tik Tak Bomba için fitil, tur '
          'sayısı ve kategori) de aynı şekilde yalnızca cihazınızda '
          'tutulur.'),
    );
    expect(
      stored.body,
      contains('Daha önce oynadığınız kelimeler ve kartlar, aynı içeriğin '
          'sık tekrar etmemesi için yalnızca cihazınızda tutulur; hiçbir '
          "yere gönderilmez ve 'Oyuncu Geçmişini Sil' ile silinebilir."),
    );
  });

  test('zorunlu başlıklar yer alır', () {
    for (final required in [
      'Veri Sorumlusu',
      'İletişim',
      'Saklama Süresi',
      'Oyuncu Geçmişini Sil',
      'kaldırdığınızda',
      '11. maddesi',
      'GDPR',
      '13 yaşından küçük',
      'üçüncü kişi',
      'Yürürlük',
    ]) {
      expect(fullText, contains(required), reason: required);
    }
  });
}
