# Mağaza Beyanları ve Metinleri — Secret Party

> Uygulamanın gerçek davranışına göre hazırlanmış HAZIR cevaplar (Ekim 2026).
> Hukuki tavsiye değildir. Kaynaklar en altta. "DOĞRULANMALI" işaretli
> maddeleri form doldururken ekrandaki güncel soru metniyle karşılaştırın.

## 0. Uygulamanın veri davranışı (tüm cevapların dayanağı)

| Konu | Gerçek durum (koddan) |
|---|---|
| Cihazda saklanan | Oyuncu isim geçmişi, titreşim/ses tercihi, Imposter kategori/süre/ipucu ayarı, Tik Tak Bomba fitil/tur/kategori ayarı, tekrar önleme için görülen kelime/kart/görev geçmişi (en fazla 3000 kayıt) (`SharedPreferences`, `lib/data/repositories/local_storage_repository.dart`) |
| Cihaz dışına gönderilen | Hiçbir şey. Uygulamada HTTP/soket kodu yok; release Android manifestinde INTERNET izni yok |
| Paketler | riverpod, go_router (yalnızca yönlendirme), shared_preferences (yerel), wakelock_plus (ekran açık), url_launcher (yalnızca kullanıcı dokununca mağaza/e-posta açar), package_info_plus (sürüm okur). Hiçbiri ağ isteği yapmaz |
| Analitik / reklam / çökme raporu / hesap | Yok |
| İzinler | Android: yok (release). iOS: izin açıklaması yok |
| Şifreleme | Uygulama kendi şifrelemesini kullanmaz; ağ bağlantısı da yok |

## 1. Apple App Store Connect

### 1.1 App Privacy
- **"Do you or your third-party partners collect data from this app?" → No.**
  Sonuç etiketi: **Data Not Collected**. Gerekçe: Apple tanımına göre cihazda
  işlenip cihaz dışına gönderilmeyen veri "toplanmış" sayılmaz.
- Tracking: **No**. Privacy Manifest: `ios/Runner/PrivacyInfo.xcprivacy` (eklendi).
- Privacy Policy URL: `docs/gizlilik-politikasi.html`'in yayınlandığı adres
  (KULLANICI YAPACAK).

### 1.2 Yaş derecelendirmesi (Ocak 2026'dan itibaren geçerli yeni anket)
| Bölüm | Madde | Cevap |
|---|---|---|
| In-App Controls | Parental Controls / Age Assurance | Yok |
| Capabilities | Unrestricted Web Access | Yok |
| | User-Generated Content | Yok (oyuncu isimleri yalnızca cihazda, kimseyle paylaşılmaz) |
| | Social Media / Messaging and Chat | Yok |
| | Advertising | Yok |
| Mature Themes | Profanity or Crude Humor | Yok |
| | Horror/Fear Themes | Yok (Vampir Köylü yalnızca metinle anlatılır, korku öğesi yok) — DOĞRULANMALI |
| | Alcohol, Tobacco, Drugs | Yok |
| Medical / Wellness | Hepsi | Yok |
| Sexuality / Nudity | Hepsi | Yok |
| Violence | Cartoon or Fantasy Violence | **Infrequent** (Vampir Köylü'de "vampirler bir oyuncuyu avladı" gibi grafiksiz metin anlatımı) |
| | Realistic / Graphic Violence, Guns | Yok |
| Chance-Based | Gambling / Simulated Gambling / Contests / Loot Boxes | Yok |

Beklenen sonuç: **9+** (fantastik şiddet "Infrequent" nedeniyle). Bu maddeyi
"Yok" işaretlerseniz 4+ çıkar; muhafazakâr ve doğru cevap Infrequent'tir.

### 1.3 İhracat uyumluluğu (şifreleme)
- `Info.plist` → `ITSAppUsesNonExemptEncryption = false` (zaten var).
- Form sorulursa: "Uygulamanız şifreleme kullanıyor mu?" → **Hayır** (yalnızca
  işletim sisteminin sağladığı standart işlevler; uygulamanın ağ bağlantısı yok).

### 1.4 App Review notları (kopyala-yapıştır, İngilizce önerilir)
```
Secret Party is an offline, pass-and-play party game app (UI in Turkish).
No account, login, network connection or in-app purchase is required.
How to test:
1. Tap "Oyna" on the Imposter card, add 4 player names (e.g. A, B, C, D)
   and tap the start button.
2. Pass the phone: each player holds the "basılı tut" button to see their
   secret role, then hides it.
3. Start the round timer, then vote and see the result.
Minimum players: Imposter 4, Ajan (Spy) 3, Vampir Köylü 5, Tik Tak Bomba 3,
Tabu 2 teams.
Player names are stored only on the device and can be deleted in
Ayarlar > Oyuncu Geçmişini Sil.
```

## 2. Google Play Console

### 2.1 Veri güvenliği (Data safety)
| Soru | Cevap |
|---|---|
| Uygulamanız gerekli kullanıcı veri türlerinden herhangi birini topluyor veya paylaşıyor mu? | **Hayır** |
| (Hayır seçilince sonraki bölümler atlanır) | — |
| Gizlilik politikası URL'si | Yayınlanan `gizlilik-politikasi.html` adresi (KULLANICI YAPACAK) |

Gerekçe: Google tanımına göre "toplama", verinin cihazdan dışarı aktarılmasıdır;
yalnızca cihazda işlenen veri beyan edilmez. Veri toplamayan uygulamalar da formu
doldurmak ve gizlilik politikası bağlantısı vermek zorundadır.

### 2.2 İçerik derecelendirmesi (IARC anketi)
- Kategori: **Oyun** (Game).
- Şiddet: Grafiksiz, metinle anlatılan fantastik şiddet var (Vampir Köylü);
  kan/vahşet yok, gerçekçi şiddet yok.
- Cinsellik, küfür, uyuşturucu/alkol/tütün, kumar, korku: **Hayır**.
- Kullanıcılar arası etkileşim / içerik paylaşımı / konum paylaşımı: **Hayır**.
- Dijital ürün satın alma: **Hayır**.
- Sonuç IARC tarafından belirlenir (beklenti: PEGI 7 / ESRB Everyone 10+
  civarı) — DOĞRULANMALI.

### 2.3 Hedef kitle ve içerik
- Hedef yaş grupları: **13-15, 16-17, 18 ve üzeri** (13 yaş altı SEÇİLMEZ).
- "Uygulamanız çocukların ilgisini çekebilir mi?" → **Hayır**; uygulama
  arkadaş/aile grupları için kelime-blöf oyunu, çocuk karakter veya çocuklara
  yönelik pazarlama yok. (Google bu cevabı mağaza görsellerine bakarak
  sorgulayabilir; görsellerde çizgi film çocuk karakteri kullanmayın.)
- Reklamlar: **Uygulamam reklam içermiyor**.
- Uygulama erişimi: **Tüm işlevler özel erişim gerektirmez** (giriş yok).
- Haber uygulaması: Hayır. Sağlık: Hayır. Finans: Hayır. Devlet: Hayır.

### 2.4 İzinlerin gerekçesi
- Release paketinde özel izin yok. (INTERNET yalnızca debug/profile
  manifestinde; geliştirme sırasında hot reload için.)
- `<queries>` bloğu izin değildir: Android 11+ cihazlarda "Uygulamayı
  Değerlendir" (https) ve "Geri Bildirim" (mailto) bağlantılarını açabilmek için.
- Wakelock: Android'de pencere bayrağı (`FLAG_KEEP_SCREEN_ON`) ile çalışır,
  `WAKE_LOCK` izni eklemez — birleşik manifest ile doğrulandı (bkz.
  `docs/YAYIN_DENETIMI.md`).

### 2.5 Kapalı test zorunluluğu
- **13 Kasım 2023'ten sonra açılan KİŞİSEL geliştirici hesapları**, üretime
  çıkmadan önce **en az 12 test kullanıcısıyla, kesintisiz en az 14 gün** kapalı
  test yapmak zorunda. Sonra Dashboard'dan üretim erişimi için başvurulur.
  Kurumsal (organization) hesaplarda bu zorunluluk yok.

## 3. Türkçe mağaza metinleri

> Karakter sayıları kontrol edildi. Ad için risk notu: "Secret Party" genel bir
> ifade; mağazalarda benzer adlı uygulamalar olabilir ve marka tescili
> yapılmadıysa korunamaz. Yayından önce App Store/Play'de ve TÜRKPATENT'te arama
> yapın — DOĞRULANMALI. **"Tabu" uyarısı:** Hasbro'nun "Taboo" oyunu Türkiye'de
> "Tabu" adıyla satılmaktadır; "Tabu" adını oyun adı/anahtar kelime olarak
> kullanmak fikri mülkiyet şikâyetine yol açabilir (Apple 5.2, Google IP
> politikası). Öneri: oyun içinde ve metinlerde "Yasak Kelime" gibi özgün bir ad —
> karar sizin. Aşağıdaki metinler "Tabu"yu yalnızca açıklamada geçirir;
> değiştirirseniz buraları da güncelleyin.

| Alan | Metin | Sınır | Uzunluk |
|---|---|---|---|
| Apple ad / Google başlık | Secret Party: Parti Oyunları | 30 | 28 |
| Apple alt başlık | Tek telefonla grup oyunları | 30 | 27 |
| Google kısa açıklama | Imposter, Tabu, Ajan, Tik Tak Bomba ve dahası: tek telefonla internetsiz eğlence | 80 | 80 |
| Apple anahtar kelimeler | imposter,vampir köylü,ajan,tabu,bomba,parti oyunu,grup oyunu,kelime,blöf,casus,internetsiz | 100 | 90 |
| Apple tanıtım metni | Telefonu ortaya koy, rolleri dağıt ve aranızdaki yalancıyı bulun! Beş parti oyunu, internetsiz ve reklamsız. | 170 | 108 |

Not: Apple anahtar kelimelerde uygulama adındaki kelimeleri tekrar yazmaya gerek
yoktur; virgülden sonra boşluk bırakmayın.

### Uzun açıklama (Google ≤4000, Apple ≤4000)
```
Arkadaşlarınla buluştun, telefon elinde, eğlence başlasın! Secret Party; tek bir telefonu elden ele dolaştırarak oynanan beş parti oyununu bir araya getirir. İnternet, hesap ya da kurulum gerekmez.

IMPOSTER
Herkes gizli kelimeyi bilir, biri hariç. Sırayla kelimeyle ilgili ipucu verin, blöf yapın ve aranızdaki yalancıyı oylayarak bulun. 400'den fazla kelime ve farklı kategoriler. İstersen Imposter'a küçük bir ipucu ver.

VAMPİR KÖYLÜ
Geceleri vampirler avlanır, gündüzleri köy oylar. Kâhin, doktor, avcı ve cadı gibi rollerle 5-16 kişilik dev gruplar için gerilim dolu bir oyun.

TABU
İki takım, bir sayaç. Kelimeyi anlat ama yasaklı kelimeleri sakın söyleme!

AJAN
Herkes nerede olduğunu biliyor, ajan hariç. Sorular sor, cevapları dinle, ajanı yakala. Ajan ise konumu tahmin ederek kazanmaya çalışır.

TİK TAK BOMBA
Ekrandaki göreve bir cevap söyle ("Bir meyve söyle!") ve bombayı hemen yanındakine geçir. Fitil gizli; bomba patladığında telefon kimdeyse o yanar! 250'den fazla görev, 3-10 oyuncu.

NEDEN SECRET PARTY?
• Tek telefon yeterli, internetsiz oynanır
• Reklam yok, hesap yok
• Rol kartları basılı tutunca açılır; telefon el değiştirirken gizli bilgi korunur
• Oyun sırasında ekran kararmaz
• Her oyun için "Nasıl Oynanır?" rehberi
• Kişisel veri toplamaz: oyuncu isimleri yalnızca cihazında kalır

Oyun gecesi, doğum günü, yolculuk ya da kafe sohbeti: telefonu ortaya koy ve partiyi başlat!
```

### Yenilikler (ilk sürüm)
```
Secret Party yayında! Imposter, Vampir Köylü, Tabu, Ajan ve Tik Tak Bomba ile tek telefondan parti zamanı.
```

## 4. Gerekli görseller

| Mağaza | Görsel | Boyut / kural |
|---|---|---|
| Apple | iPhone ekran görüntüsü (6.9"/6.7" sınıfı) | 1290×2796 veya 1320×2868 (dikey), 1-10 adet, PNG/JPEG, saydamlık yok |
| Apple | iPad 13" ekran görüntüsü | 2064×2752 veya 2048×2732 — **yalnızca iPad desteklenirse zorunlu** |
| Apple | App Store ikonu | 1024×1024, alfa YOK (proje ikonu kontrol edildi: RGB, alfa yok) |
| Google | Uygulama ikonu | 512×512, 32-bit PNG, ≤1 MB |
| Google | Öne çıkan görsel (feature graphic) | 1024×500, JPEG veya 24-bit PNG (alfa yok) |
| Google | Telefon ekran görüntüsü | 2-8 adet, kenar 320-3840 px, uzun kenar ≤2× kısa kenar; öne çıkarılmak için oyunlarda en az 3 adet 1080×1920 |
| Google | Tablet ekran görüntüsü | İsteğe bağlı (eklenirse en az 4, 1080-7680 px) |

### Önerilen ekranlar ve başlıklar (6 görüntü)
1. Ana ekran (beş oyun kartı) — "5 parti oyunu, tek telefon"
2. Imposter rol kartı (kelime açık) — "Herkes kelimeyi bilir… biri hariç"
3. Imposter tur sayacı — "Konuş, blöf yap, şüphelen"
4. Oylama / sonuç ekranı — "Yalancıyı bul!"
5. Vampir Köylü gece ekranı — "Geceleri vampirler avlanır"
6. Ayarlar / gizlilik kartı — "İnternetsiz, reklamsız, veri toplamaz"

Ekran görüntülerinde gerçek ünlü fotoğrafı veya marka logosu kullanmayın.

## Kaynaklar
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple yaş derecelendirmeleri: https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions
- Apple ekran görüntüsü özellikleri: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- Apple yaklaşan gereksinimler: https://developer.apple.com/news/upcoming-requirements/
- Google Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
- Google kapalı test (yeni kişisel hesaplar): https://support.google.com/googleplay/android-developer/answer/14151465
- Google görsel öğeler: https://support.google.com/googleplay/android-developer/answer/9866151
- Google hedef API: https://developer.android.com/google/play/requirements/target-sdk
