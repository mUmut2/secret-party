# Yayıncı Rehberi — Secret Party

Bu belge uygulamayı **kendi Apple Developer (ve istersen Google Play)
hesabıyla yayınlayacak kişi** içindir. Kod mağazaya hazır; aşağıdakiler
yalnızca yayıncının verebileceği bilgiler ve hesap işlemleridir.

Uygulama: 5 parti oyunu (Imposter, Vampir Köylü, Tabu, Ajan, Tik Tak Bomba),
tamamen Türkçe, offline, reklamsız, hesap yok, **hiçbir veri toplamaz**.
Ayrıntılı denetim: `docs/YAYIN_DENETIMI.md`. Mağaza form cevapları ve
metinler: `docs/MAGAZA_BEYANLARI.md`.

## 1. Kurulum
```
flutter --version        # Xcode 26 ile derlemek için güncel kararlı sürüm önerilir
flutter pub get
flutter analyze          # 0 sorun beklenir
flutter test             # hepsi geçmeli (1 test app_info boşken "atlandı")
```

## 2. Kimliği ve yayıncı bilgilerini gir (zorunlu)
1. **Paket / bundle kimliği** (Android + iOS tek komutla; ilk yüklemeden sonra
   DEĞİŞTİRİLEMEZ):
   ```
   dart run tool/set_app_id.dart com.<adın>.secretparty
   ```
   `build.gradle.kts`, `MainActivity.kt` (klasörüyle) ve Xcode projesindeki
   tüm `PRODUCT_BUNDLE_IDENTIFIER` değerleri güncellenir.
2. **`lib/core/config/app_info.dart`** dosyasını doldur:
   - `developerName`: geliştirici / yayıncı adı (App Store'daki satıcı adıyla
     uyumlu olmalı; gizlilik politikasında "veri sorumlusu" olarak geçer)
   - `supportEmail`: destek ve KVKK başvuru e-postası
   - `privacyPolicyUrl`: politikanın web adresi (adım 3)
   - `privacyPolicyUpdatedAt`: yürürlük tarihi, örn. `'1 Kasım 2026'`
   - `appStoreUrl` / `playStoreUrl`: mağaza sayfası oluşunca (boşken
     "Uygulamayı Değerlendir" satırı gizlenir; sonraki güncellemede doldurulabilir)
3. Politikanın web sürümünü yeniden üret:
   ```
   dart run tool/generate_privacy_html.dart
   ```
4. `flutter test` → `release_readiness_test` artık **atlanmadan geçmeli**.
   Geçmiyorsa uygulama içinde `[E-POSTA ADRESİ]` gibi yer tutucular kalmış
   demektir (Apple 2.1 red sebebi).

## 3. Gizlilik politikasını yayınla (GitHub Pages)
1. github.com'da yeni **public** depo (örn. `secret-party-gizlilik`).
2. `docs/gizlilik-politikasi.html` → depoya `index.html` adıyla yükle.
3. Settings > Pages > "Deploy from a branch" > `main` / root > Save.
4. Adres `https://<kullanıcı>.github.io/secret-party-gizlilik/` olur; açılıyor
   mu kontrol et, `privacyPolicyUrl`'e ve mağaza formlarına yaz.
5. Politika metni değişirse adım 2.3'ü tekrarla, dosyayı yeniden yükle.

## 4. iOS (Mac + Xcode 26)
1. `ios/Runner.xcworkspace`'i aç > Runner > Signing & Capabilities > **Team**'i
   seç ("Automatically manage signing" açık).
2. **iPad kararı:** proje şu an iPhone + iPad (`TARGETED_DEVICE_FAMILY = 1,2`).
   Yalnızca iPhone istersen Xcode > Runner > General > Supported Destinations'tan
   iPad'i kaldır (o zaman iPad ekran görüntüsü gerekmez). Artı/eksi:
   `docs/YAYIN_DENETIMI.md` §4.
3. App Store Connect > My Apps > + > yeni uygulama (bundle id ile).
4. `flutter build ipa --release` → `build/ios/ipa/*.ipa`'yı Transporter ile
   yükle, ya da Xcode > Product > Archive > Distribute App.
5. TestFlight'ta gerçek cihazda dene (§6).
6. App Store Connect formları: `docs/MAGAZA_BEYANLARI.md` §1
   (App Privacy = "Data Not Collected", yaş derecelendirmesi, şifreleme = hayır,
   App Review notu hazır).
7. Ekran görüntüleri: en az iPhone 6.9"/6.7" sınıfı (1320×2868 veya 1290×2796);
   iPad destekleniyorsa 13" (2064×2752). Görüntülerde gerçek marka logosu /
   ünlü fotoğrafı kullanma.
8. Add for Review > Submit.

## 5. Android (isteğe bağlı)
1. İmza anahtarı (parolayı sen seç, **iki ayrı yere yedekle**):
   ```
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. `android/key.properties.example` → `android/key.properties` (git'e girmez).
3. `flutter build appbundle --release` → `build/app/outputs/bundle/release/app-release.aab`.
4. Kişisel Play hesabıysa: üretimden önce **12 test kullanıcısı / kesintisiz
   14 gün kapalı test** zorunlu. Formlar: `docs/MAGAZA_BEYANLARI.md` §2.

## 6. Gerçek cihaz test listesi
- [ ] Oyun sırasında ekran kararmıyor (5 oyun); menüde normal zaman aşımı.
- [ ] Ses ve titreşim: Ayarlar'dan kapatınca tamamen susuyor.
- [ ] Rol kartı açıkken uygulamayı arka plana al → kart kapanıyor.
- [ ] Tik Tak Bomba: arka planda fitil duruyor, dönünce devam ediyor.
- [ ] Geri hareketi: oyunda çıkış onayı, menüde bir üst ekran.
- [ ] Küçük telefon (iPhone SE) ve büyük telefon; iPad destekleniyorsa iPad.
- [ ] Sistem açık/koyu tema (uygulama hep koyu), en büyük yazı boyutu,
  "Hareketi Azalt" açık.
- [ ] Ayarlar > Gizlilik Politikası'nda yer tutucu kalmamış, Hakkında notu var.

## 7. Bilinen riskler (karar yayıncıda)
- Imposter "markalar" kategorisi (117 marka adı) ve "Tabu" oyun adı fikri
  haklar açısından risk taşır (Apple 5.2.1, 4.1(c)). Proje sahibi bu sürüm için
  içerikleri olduğu gibi bırakmayı seçti; inceleme itiraz ederse ilk
  yapılacaklar: "markalar" kategorisini `lib/data/content/imposter/imposter_categories.dart`
  haritasından çıkarmak (ardından `test/data/word_repository_test.dart`'taki
  "toplam 1500+" eşiğini 1350'ye indirmek) ve Tabu'nun ekrandaki adını
  değiştirmek.
- "Secret Party" adı için App Store'da ad çakışması kontrol edilmeli.
