/// Uygulamanın mağaza, iletişim ve yasal bilgilerinin TEK kaynağı.
///
/// YAYIN ÖNCESİ (bkz. docs/YAYIN_KONTROL_LISTESI.md):
/// - [developerName] ve [supportEmail]: Gizlilik Politikası'ndaki veri
///   sorumlusu / iletişim bilgisi. Boşken uygulama içi politikada
///   "belirtilecek" yazar; yayın öncesi doldurulmalıdır.
/// - [playStoreUrl] / [appStoreUrl]: boşken Ayarlar'daki "Uygulamayı
///   Değerlendir" satırı GİZLENİR (ölü buton gösterilmez).
/// - [supportEmail] boşken "Geri Bildirim / İletişim" satırı GİZLENİR.
/// - [privacyPolicyUrl]: docs/gizlilik-politikasi.html'in yayınlandığı web
///   adresi (mağaza formlarına da yazılır).
///
/// `test/app/release_readiness_test.dart` bu değerler doldurulana kadar
/// "atlandı" (skip) olarak raporlanır.
class AppInfo {
  AppInfo._();

  static const String appName = 'Secret Party';

  /// Geliştiricinin (veri sorumlusunun) adı soyadı veya ticari unvanı.
  static const String developerName = '';

  /// Google Play sayfası, örn. https://play.google.com/store/apps/details?id=...
  static const String playStoreUrl = '';

  /// App Store sayfası, örn. https://apps.apple.com/app/id...
  /// Değerlendirme ekranını doğrudan açmak için sonuna
  /// `?action=write-review` eklenebilir.
  static const String appStoreUrl = '';

  /// Destek / geri bildirim / KVKK başvuru e-posta adresi.
  static const String supportEmail = '';

  /// Gizlilik politikasının web adresi (mağaza başvurusu için).
  static const String privacyPolicyUrl = '';

  /// Gizlilik politikasının yürürlük (son güncellenme) tarihi.
  static const String privacyPolicyUpdatedAt = '';
}
