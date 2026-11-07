import '../../../core/config/app_info.dart';

/// Gizlilik Politikası metninin TEK kaynağı.
///
/// Uygulama içi ekran (`PrivacyPolicyScreen`) bu metni gösterir; mağazalar için
/// web'de yayınlanan `docs/gizlilik-politikasi.html` dosyası da birebir aynı
/// metni içermelidir. `test/features/privacy_policy_content_test.dart` iki
/// metnin aynı kaldığını doğrular: burada bir cümle değişirse HTML de
/// güncellenmelidir.
///
/// Metin uygulamanın GERÇEK davranışını anlatır: kişisel veri toplanmaz,
/// hiçbir sunucuya veri gönderilmez, oyuncu isimleri ve ayarlar yalnızca
/// cihazda (SharedPreferences) tutulur. Uygulamaya analitik, reklam, hesap ya
/// da sunucu eklenirse bu metin ve mağaza beyanları güncellenmelidir.
class PrivacyPolicyContent {
  PrivacyPolicyContent._();

  static const String title = 'Gizlilik Politikası';

  static const String summary = 'Kişisel veri toplamıyoruz. Oyuncu isimleri '
      've ayarların yalnızca cihazında kalır.';

  /// [AppInfo] değerleri henüz doldurulmadıysa metinde görünen yer tutucular.
  /// HTML dosyasında da aynı yer tutucular bulunur.
  static const String developerPlaceholder = '[GELİŞTİRİCİ ADI]';
  static const String emailPlaceholder = '[E-POSTA ADRESİ]';
  static const String datePlaceholder = '[YÜRÜRLÜK TARİHİ]';

  static String get developer => AppInfo.developerName.isEmpty
      ? developerPlaceholder
      : AppInfo.developerName;

  static String get email =>
      AppInfo.supportEmail.isEmpty ? emailPlaceholder : AppInfo.supportEmail;

  static String get effectiveDate => AppInfo.privacyPolicyUpdatedAt.isEmpty
      ? datePlaceholder
      : AppInfo.privacyPolicyUpdatedAt;

  static String get lastUpdatedLine => 'Yürürlük tarihi: $effectiveDate';

  static List<PolicySection> get sections => [
        const PolicySection(
          title: '1. Kısaca',
          body: '${AppInfo.appName} kişisel verilerinizi toplamaz, satmaz ve '
              'hiçbir üçüncü kişiyle paylaşmaz. Uygulama internet bağlantısı '
              'gerektirmez, hiçbir sunucuya veri göndermez ve sizi izlemez '
              '(takip, analitik, reklam veya çerez yoktur).',
        ),
        PolicySection(
          title: '2. Veri Sorumlusu ve İletişim',
          body: '${AppInfo.appName} uygulaması $developer tarafından '
              'geliştirilmiş ve yayınlanmıştır. Bu politika veya '
              'verilerinizle ilgili her türlü soru ve talebiniz için $email '
              'adresine e-posta gönderebilirsiniz.',
        ),
        const PolicySection(
          title: '3. Cihazınızda Saklanan Bilgiler',
          body: 'Oyuna eklediğiniz oyuncu isimleri, bir sonraki oyunda tekrar '
              'yazmanıza gerek kalmasın diye YALNIZCA cihazınızın yerel '
              'hafızasında saklanır. Titreşim ve ses tercihleriniz ile oyun '
              'ayarlarınız (kategori, süre, ipucu tercihi; Tik Tak Bomba için '
              'fitil, tur sayısı ve kategori) de aynı şekilde '
              'yalnızca cihazınızda tutulur. Daha önce oynadığınız kelimeler '
              've kartlar, aynı içeriğin sık tekrar etmemesi için yalnızca '
              "cihazınızda tutulur; hiçbir yere gönderilmez ve 'Oyuncu "
              "Geçmişini Sil' ile silinebilir. Tik Tak Bomba görevleri için de "
              'aynı kural geçerlidir. Bu bilgiler cihazınızdan dışarı '
              'çıkmaz; geliştirici dahil hiç kimse bunlara erişemez.',
        ),
        const PolicySection(
          title: '4. Toplanmayan ve Paylaşılmayan Veriler',
          body: 'Uygulama konum, rehber, fotoğraf, mikrofon, kamera, reklam '
              'kimliği veya cihaz kimliği gibi hiçbir bilgiye erişmez ve bu '
              'amaçla izin istemez. Hesap oluşturma, giriş yapma, analitik, '
              'çökme raporlama, çerez veya reklam bulunmamaktadır. Hiçbir veri '
              'üçüncü kişilere aktarılmaz veya satılmaz.',
        ),
        const PolicySection(
          title: '5. Saklama Süresi ve Silme',
          body: 'Cihazınızdaki bilgiler, siz silene kadar cihazınızda kalır. '
              'Kayıtlı oyuncu isimlerini istediğiniz an silebilirsiniz: oyuncu '
              'ekleme ekranlarındaki "Geçmişten Seç" listesinden tek tek ya da '
              'Ayarlar > Oyuncu Geçmişini Sil ile tamamen. Uygulamayı '
              'kaldırdığınızda cihazınızdaki tüm uygulama verileri (oyuncu '
              'isimleri, oynanan içerik geçmişi, tercihler ve oyun ayarları) '
              'da silinir.',
        ),
        const PolicySection(
          title: '6. Dış Bağlantılar',
          body: 'Uygulamada bulunan "Uygulamayı Değerlendir" ve "Geri Bildirim '
              '/ İletişim" seçenekleri sizi uygulama mağazasına veya e-posta '
              'uygulamanıza yönlendirir. Bu hizmetlerde paylaştığınız bilgiler '
              'ilgili hizmetin kendi gizlilik politikasına tabidir. Bize '
              'e-posta gönderirseniz e-posta adresiniz ve mesajınız yalnızca '
              'size yanıt vermek için kullanılır ve üçüncü kişilerle '
              'paylaşılmaz.',
        ),
        PolicySection(
          title: '7. KVKK ve GDPR Kapsamındaki Haklarınız',
          body:
              '6698 sayılı Kişisel Verilerin Korunması Kanunu\'nun (KVKK) 11. '
              'maddesi ve Avrupa Birliği Genel Veri Koruma Tüzüğü (GDPR) '
              'kapsamında; kişisel verilerinizin işlenip işlenmediğini öğrenme, '
              'işlenmişse bilgi talep etme, işlenme amacını öğrenme, yurt '
              'içinde veya yurt dışında aktarıldığı kişileri bilme, eksik veya '
              'yanlış işlenmişse düzeltilmesini, silinmesini veya yok '
              'edilmesini isteme, itiraz etme ve zarara uğramanız hâlinde '
              'zararın giderilmesini talep etme haklarına sahipsiniz. '
              'Uygulama kişisel veri toplamadığı için bu bilgilerin tam '
              'kontrolü zaten sizdedir. Başvurularınızı $email adresine '
              'iletebilirsiniz; başvurunuz en geç 30 gün içinde yanıtlanır. '
              'Ayrıca Kişisel Verileri Koruma Kurulu\'na veya bulunduğunuz '
              'ülkedeki veri koruma otoritesine şikâyette bulunma hakkınız '
              'saklıdır.',
        ),
        const PolicySection(
          title: '8. Çocuklar',
          body: 'Uygulama 13 yaşından küçük çocuklara yönelik değildir. '
              'Uygulama hiçbir kullanıcıdan, çocuklar dahil, kişisel veri '
              'toplamaz; oyuna eklenen oyuncu isimleri cihaz dışına çıkmaz.',
        ),
        PolicySection(
          title: '9. Değişiklikler ve Yürürlük',
          body: 'Bu politika güncellenirse yeni sürüm uygulama içinde ve web '
              'sayfasında yayınlanır, yürürlük tarihi değiştirilir. Bu sürüm '
              '$effectiveDate tarihinden itibaren geçerlidir.',
        ),
      ];
}

/// Politikanın tek bir başlıklı bölümü.
class PolicySection {
  const PolicySection({required this.title, required this.body});

  final String title;
  final String body;
}
