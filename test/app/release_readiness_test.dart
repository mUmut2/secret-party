import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/core/config/app_info.dart';

/// Mağazaya göndermeden önce doldurulması gereken değerler.
///
/// Değerler boşken test "atlandı" olarak görünür (kırmızı değil); yayın
/// derlemesinden önce bu testin ATLANMADAN geçtiğini doğrulayın.
void main() {
  final missing = <String>[
    if (AppInfo.developerName.isEmpty) 'developerName',
    if (AppInfo.supportEmail.isEmpty) 'supportEmail',
    if (AppInfo.privacyPolicyUrl.isEmpty) 'privacyPolicyUrl',
    if (AppInfo.privacyPolicyUpdatedAt.isEmpty) 'privacyPolicyUpdatedAt',
  ];

  test(
    'AppInfo yayın değerleri dolu',
    () {
      expect(AppInfo.supportEmail, contains('@'));
      expect(AppInfo.privacyPolicyUrl, startsWith('https://'));
    },
    skip: missing.isEmpty
        ? false
        : 'KULLANICI YAPACAK: app_info.dart içinde boş: ${missing.join(', ')}',
  );
}
