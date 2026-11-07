/// Uygulama kimliğini (Android `applicationId`/`namespace`, iOS bundle id)
/// değiştiren saf dönüşümler. Komut satırı: `tool/set_app_id.dart`.
library;

/// Android paket adı / iOS bundle id için kabul edilen biçim: en az iki
/// bölüm, her bölüm küçük harfle başlar, yalnızca küçük harf, rakam ve `_`.
/// (iOS'ta `_` kabul edilmediği için bundle id'de `_` kullanılmaz.)
final RegExp appIdPattern = RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$');

/// Kimlik geçerli değilse Türkçe hata mesajı, geçerliyse `null`.
String? validateAppId(String id) {
  if (!appIdPattern.hasMatch(id)) {
    return 'Geçersiz kimlik: "$id". Örnek: com.adsoyad.secretparty '
        '(küçük harf, rakam, noktayla ayrılmış en az iki bölüm, alt çizgi yok).';
  }
  if (id.startsWith('com.example.')) {
    return 'com.example ile başlayan kimlik mağazalarda kabul edilmez.';
  }
  return null;
}

/// `android/app/build.gradle.kts` içindeki `namespace` ve `applicationId`.
String replaceGradleIds(String gradle, String id) => gradle
    .replaceAllMapped(
      RegExp(r'namespace = "[^"]+"'),
      (_) => 'namespace = "$id"',
    )
    .replaceAllMapped(
      RegExp(r'applicationId = "[^"]+"'),
      (_) => 'applicationId = "$id"',
    );

/// `MainActivity.kt` içindeki `package` satırı.
String replaceKotlinPackage(String source, String id) => source.replaceFirst(
      RegExp(r'^package [\w.]+', multiLine: true),
      'package $id',
    );

/// Xcode projesindeki tüm `PRODUCT_BUNDLE_IDENTIFIER` değerleri: uygulama
/// hedefi [id], test hedefi `[id].RunnerTests` olur.
String replaceBundleIds(String pbxproj, String id) => pbxproj.replaceAllMapped(
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);'),
      (match) => match.group(1)!.trim().endsWith('.RunnerTests')
          ? 'PRODUCT_BUNDLE_IDENTIFIER = $id.RunnerTests;'
          : 'PRODUCT_BUNDLE_IDENTIFIER = $id;',
    );
