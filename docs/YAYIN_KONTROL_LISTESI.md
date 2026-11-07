# Yayın Kontrol Listesi

Uygulamayı Apple Developer hesabı sahibi (yayıncı) yayınlayacak. Paket
kimliği, geliştirici adı, destek e-postası, gizlilik politikası adresi ve iPad
kararı yayıncıya aittir.

Sıralı adımların tamamı: **`docs/YAYINCI_REHBERI.md`**
- Kimlik: `dart run tool/set_app_id.dart com.<ad>.secretparty`
- Bilgiler: `lib/core/config/app_info.dart` → `dart run tool/generate_privacy_html.dart`
- Politika: GitHub Pages
- iOS: Team seçimi, Archive, TestFlight, App Store Connect formları
  (`docs/MAGAZA_BEYANLARI.md`)
- Gerçek cihaz test listesi

Proje sahibine kalan tek iş: projeyi (bu git deposunu) yayıncıya iletmek.
