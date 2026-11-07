# Yayın Denetimi (güncelleme: 20 Ekim 2026)

İlk denetim 18 Ekim'de yapıldı; bu sürüm sonradan eklenen Tik Tak Bomba,
tekrar önleme, genişletilmiş Imposter havuzu ve yeni Tabu yapısına göre
yeniden kontrol edildi.

Durumlar: **TAMAM** (uygun) · **DÜZELTİLDİ** (kodda düzeltildi) ·
**YAYINCI YAPACAK** (Apple hesabı sahibi) ·
**DOĞRULANMALI** (resmi kaynakla kesinleştirilemedi / hesap gerektiriyor).
Hukuki tavsiye değildir; KVKK ve fikri haklar için bir uzmana danışmanı öneririm.

## 1. Placeholder ve ölü içerik (Apple 2.1(a))

> Apple 2.1(a): gönderim "nihai sürüm" olmalı; yer tutucu metin, boş web
> siteleri ve geçici içerik temizlenmeli.

| Madde | Durum | Not |
|---|---|---|
| "Yakında" oyun kartı / bölümü | DÜZELTİLDİ | Kaldırıldı; `store_compliance_test` ana ekranda "Yakında" olmadığını denetler. ("Pek Yakında" bir film adıdır, Imposter içeriği) |
| Boş mağaza URL'si / e-posta yüzünden ölü buton | DÜZELTİLDİ | Değer boşken "Uygulamayı Değerlendir" ve "Geri Bildirim" satırları gizlenir |
| Gizlilik politikasında yer tutucu (`[GELİŞTİRİCİ ADI]`, `[E-POSTA ADRESİ]`, `[YÜRÜRLÜK TARİHİ]`) | YAYINCI YAPACAK | `app_info.dart` doldurulunca kaybolur. **Doldurulmadan gönderilirse 2.1 red riski.** `release_readiness_test` boşken "atlandı" gösterir |
| TODO / lorem / debug / test metni | TAMAM | `lib/` içinde kullanıcıya görünen yok |
| Tabu destesi | DÜZELTİLDİ | 569 kart; her kategoride en az 50 (test). İlk hedef olan 1000 kart sonraki sürümlere bırakıldı |

## 2. Release hijyeni

| Madde | Durum | Not |
|---|---|---|
| `print` / `debugPrint` | TAMAM | Projede `print(` yok; `kReleaseMode`'da `debugPrint` susturuluyor |
| GoRouter `debugLogDiagnostics` | TAMAM | `kDebugMode`'a bağlı |
| Hata ekranında teknik detay | TAMAM | İstisna metni yalnızca debug'da |
| Android `debuggable` | TAMAM | Release'te varsayılan `false` |
| Sürüm / derleme | TAMAM | `1.0.0+1`; her yüklemede `+N` artmalı |

## 3. Android

| Madde | Durum | Not |
|---|---|---|
| `applicationId` / `namespace` | YAYINCI YAPACAK | Hâlâ `com.example.party_game`. `dart run tool/set_app_id.dart <kimlik>` Android + iOS'u tek seferde değiştirir (test edildi; `com.example` reddedilir) |
| targetSdk / compileSdk | TAMAM | Flutter 3.35.7: 36 / 36 (minSdk 24). Play: 31 Ağu 2026'dan beri yeni uygulama ve güncellemeler API 36 hedeflemeli (resmi sayfa, doğrulandı) |
| AAB / 64-bit | TAMAM | `flutter build appbundle`; arm64-v8a + armeabi-v7a + x86_64 |
| İmzalama | TAMAM + KULLANICI YAPACAK | `android/key.properties` okunur; yoksa debug imzası (Play'e yüklenemez). `key.properties`, `*.jks`, `*.keystore` `.gitignore`'da, git'te yok (`git check-ignore` ile doğrulandı) |
| Birleşik manifest izinleri | TAMAM | Yalnızca AndroidX'in iç izni `…DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. INTERNET yalnızca debug/profile manifestinde. Yerel dosyalar ilk denetimden beri değişmedi; yeni oyunlar izin eklemedi |
| Sembol ayıklama uyarısı | KULLANICI YAPACAK | Android cmdline-tools eksik (bkz. kontrol listesi) |

## 4. iOS

| Madde | Durum | Not |
|---|---|---|
| Bundle id | YAYINCI YAPACAK | `com.example.partyGame` (+ `.RunnerTests`); aynı araçla değişir |
| Signing | KULLANICI YAPACAK | `CODE_SIGN_STYLE = Automatic`, `DEVELOPMENT_TEAM` yok: Xcode'da kendi takımını seçmelisin (Mac gerekir) |
| `PrivacyInfo.xcprivacy` | TAMAM | İzleme yok, toplanan veri yok, UserDefaults `CA92.1`; Xcode Resources'a kayıtlı |
| `ITSAppUsesNonExemptEncryption` | TAMAM | `false` |
| Minimum iOS | TAMAM | 13.0 (Apple: 9 Eyl 2026'dan itibaren en az iOS 13) |
| Gereksiz izin açıklaması | TAMAM | Hiç `NS…UsageDescription` yok |
| 1024×1024 ikon | TAMAM | PNG renk tipi RGB, alfa yok |
| LaunchScreen | TAMAM | `LaunchScreen.storyboard` |
| iPad | YAYINCI YAPACAK | Şu an `TARGETED_DEVICE_FAMILY = "1,2"` + `UIRequiresFullScreen`. Ayrıntı aşağıda |
| Xcode 26 / iOS 26 SDK | DOĞRULANMALI | Apple 28 Nis 2026'dan beri zorunlu (resmi). Bir üçüncü taraf kaynağa göre Flutter 3.32+ Xcode 26'yı destekliyor; proje 3.35.7. Flutter'ın resmi notlarından teyit et, mümkünse güncel kararlı sürüme yükselt. Bu makine Windows, iOS derlemesi denenemedi |

### iPad: v1'de yalnızca iPhone mu?
- **Yalnızca iPhone (`1`)** — artı: iPad 13" ekran görüntüsü gerekmez, iPad'e özel
  inceleme yükü azalır, `UIRequiresFullScreen` ihtiyacı kalkar. Eksi: iPad'de
  "iPhone uygulaması" olarak ölçekli açılır, iPad'de öne çıkmaz. Apple iPhone
  uygulamalarını iPad'de de test eder; arayüz zaten 600 px ile ortalanıyor.
- **iPhone + iPad (`1,2`, mevcut)** — artı: daha geniş kitle. Eksi: en az bir
  13" iPad ekran görüntüsü zorunlu; yalnızca dikey yönelim çoklu görev
  kurallarıyla çatışabilir (`UIRequiresFullScreen`'in iPadOS 26'da kullanımdan
  kaldırıldığı bildiriliyor — DOĞRULANMALI).
- **Öneri:** v1 yalnızca iPhone.

## 5. Gizlilik

| Madde | Durum | Not |
|---|---|---|
| Kod ↔ politika tutarlılığı | TAMAM | Cihazda saklanan anahtarlar: oyuncu geçmişi, titreşim/ses, Imposter kategori/süre/ipucu, Tik Tak Bomba fitil/tur/kategori, görülen içerik geçmişi (`seen_content_v1`, ≤3000). Hepsi politikanın 3. bölümünde. Ağ kodu yok |
| Silme yolu | TAMAM | "Oyuncu Geçmişini Sil" oyuncu ve görülen içerik geçmişini birlikte siler (test var) |
| Web sürümü | TAMAM | `docs/gizlilik-politikasi.html`, uygulama içi metinle birebir aynı (test denetler); `dart run tool/generate_privacy_html.dart` ile yeniden üretilir |
| Yayın adresi | YAYINCI YAPACAK | GitHub Pages (adımlar `docs/YAYINCI_REHBERI.md`) |

## 6. Fikri haklar (Apple 5.2.1, 4.1(c), 2.3.7)

> 5.2.1: Ticari marka ve telifli eserler gibi korunan üçüncü taraf materyalini
> izinsiz kullanmayın. 4.1(c): Başka bir geliştiricinin marka veya ürün adını
> uygulamanızın adında ya da ikonunda onaysız kullanamazsınız. 2.3.7: Meta
> veriyi marka adlarıyla doldurmayın.

| İçerik | Risk | Öneri |
|---|---|---|
| Imposter "markalar" kategorisi (117 marka adı: Apple, Nike, Lego…) | **ORTA-YÜKSEK** | 5.2.1'in en doğrudan dokunduğu yer. Proje sahibi bu sürümde tutmayı seçti; inceleme itiraz ederse kaldırma adımı `docs/YAYINCI_REHBERI.md` §7'de |
| Imposter "ünlüler" (141 gerçek kişi, görsel yok) | ORTA | Görsel/benzerlik yok, yalnızca ad; yine de yaşayan kişiler için kişilik hakkı riski var. Seçenek: tut / yalnızca tarihî kişileri bırak / kaldır |
| Imposter "filmler" (152 film adı, Disney/Marvel dahil) | DÜŞÜK | Adlar oyun içinde metin olarak geçiyor; logo, afiş, karakter görseli yok. Tutulabilir |
| "Tabu" oyun adı | **ORTA-YÜKSEK** | Hasbro'nun "Taboo" oyunu Türkiye'de "Tabu" adıyla satılıyor. Proje sahibi adı korudu; yayıncıya not edildi |
| "Tik Tak Bomba" oyun adı | DÜŞÜK-ORTA | Piatnik'in "Tick Tack Bumm" kutu oyununa benziyor — DOĞRULANMALI (marka araması) |
| "Imposter" | DÜŞÜK | Genel İngilizce kelime |
| "Secret Party" uygulama adı | DOĞRULANMALI | Genel bir ifade; App Store / Play / TÜRKPATENT'te arama yapılmalı |
| Tik Tak Bomba görevleri ("Bir araba markası söyle") | DÜŞÜK | Belirli marka adı geçmiyor |
| Ayarlar > Hakkında yasal notu | TAMAM | "Film, dizi, ünlü ve marka adları yalnızca oyun içeriği olarak anılır, hak sahiplerine aittir; uygulama bağlantılı/onaylı değildir" |

## 7. Erişilebilirlik

| Madde | Durum | Not |
|---|---|---|
| Semantics | TAMAM | Özel dokunulabilir öğelerde etiket var; bomba ekranında süreyi ele veren etiket yok (test) |
| Dokunma hedefleri | TAMAM | `AppTapTarget` ≥48dp; Bomba seçicileri 48dp |
| Kontrast | TAMAM | 20 Ekim'de palet yumuşatıldı; yeniden ölçüldü: lime/camgöbeği/kehribar/fuşya/mor zeminde koyu metin 13.1/10.7/11.0/6.2/6.4 : 1; koyu zeminde renkli metin en düşük 4.57:1 (kırmızı, kart üstü); Imposter rol kartı koyu kırmızı zeminde beyaz metin 9.1:1, lime buton 6.6:1 (WCAG AA ≥4.5) |
| Hareketi azalt | TAMAM | Sayfa geçişleri, dramatik animasyonlar, buton basışı ve bomba nabzı kapanır |
| Sayaç ekran okuyucuda | TAMAM | `liveRegion` yalnızca son geri sayımda |

## 8. Görsel yoğunluk (20 Ekim)

| Madde | Durum | Not |
|---|---|---|
| Aşırı neon / parlama | DÜZELTİLDİ | Vurgu renkleri biraz daha az doygun tonlara çekildi; tüm renkli parlamalar (22 yer) tek `AppShadows.glowIntensity` (0.5) çarpanından geçiyor; token glow'ların opaklığı %35'ten %20'ye, bulanıklığı 20'den 14'e indi; Imposter rol kartının tam ekran parlak kırmızısı koyu kırmızıya (`AppColors.imposterReveal`) çevrildi |

## 9. Tablet / geniş ekran

| Madde | Durum | Not |
|---|---|---|
| İçerik genişliği | TAMAM | `AppViewport`: azami 600 px, ortalı (test: 1024×1366) |

## Kaynaklar
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) (2.1(a), 2.3.7, 4.1(c), 5.2.1)
- [Apple yaklaşan gereksinimler](https://developer.apple.com/news/upcoming-requirements/)
- [Google Play hedef API](https://developer.android.com/google/play/requirements/target-sdk)
- [Flutter ve Xcode 26 (üçüncü taraf)](https://theflutterk.it.com/blog/flutter-ios-26-cupertino-migration-guide)
