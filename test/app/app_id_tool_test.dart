import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/app_id.dart';

/// Yayıncının kullanacağı kimlik değiştirme aracı (tool/set_app_id.dart)
/// gerçek proje dosyalarında doğru satırları değiştirir.
void main() {
  const id = 'com.ornek.secretparty';

  test('kimlik doğrulaması', () {
    expect(validateAppId(id), isNull);
    expect(validateAppId('com.example.party'), isNotNull);
    expect(validateAppId('secretparty'), isNotNull);
    expect(validateAppId('com.Ornek.app'), isNotNull);
    expect(validateAppId('com.ornek.secret_party'), isNotNull);
  });

  test('Android namespace ve applicationId değişir', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final result = replaceGradleIds(gradle, id);
    expect(result, contains('namespace = "$id"'));
    expect(result, contains('applicationId = "$id"'));
    expect(result, isNot(contains('com.example')));
  });

  test('MainActivity paket satırı değişir', () {
    final source = Directory('android/app/src/main/kotlin')
        .listSync(recursive: true)
        .whereType<File>()
        .firstWhere((f) => f.path.endsWith('MainActivity.kt'))
        .readAsStringSync();
    expect(replaceKotlinPackage(source, id), startsWith('package $id'));
  });

  test('iOS uygulama ve test hedefleri değişir', () {
    final pbxproj =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final result = replaceBundleIds(pbxproj, id);
    expect(result, isNot(contains('com.example')));
    expect(
      RegExp('PRODUCT_BUNDLE_IDENTIFIER = $id;').allMatches(result).length,
      3,
    );
    expect(
      RegExp('PRODUCT_BUNDLE_IDENTIFIER = $id.RunnerTests;')
          .allMatches(result)
          .length,
      3,
    );
  });
}
