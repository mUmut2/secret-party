/// Kullanıcının uygulama genelindeki tercihleri (immutable).
///
/// Cihazda kalıcı tutulur (`LocalStorageRepository`); varsayılan olarak
/// titreşim ve ses efektleri açıktır.
class AppPreferences {
  const AppPreferences({
    this.hapticsEnabled = true,
    this.soundEnabled = true,
  });

  /// Dokunsal geri bildirim (titreşim) açık mı?
  final bool hapticsEnabled;

  /// Ses efektleri (buton tıklaması, süre bitti uyarısı) açık mı?
  final bool soundEnabled;

  AppPreferences copyWith({bool? hapticsEnabled, bool? soundEnabled}) {
    return AppPreferences(
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}
