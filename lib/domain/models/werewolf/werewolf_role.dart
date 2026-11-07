/// Vampir Köylü oyununda iki taraf vardır; her rol bunlardan birine aittir.
enum WerewolfTeam {
  villagers('Köylüler'),
  vampires('Vampirler');

  const WerewolfTeam(this.label);

  /// Ekranda gösterilen Türkçe ad.
  final String label;
}

/// Vampir Köylü rolleri.
///
/// Saf Dart'tır (Flutter bağımlılığı yoktur); ikon ve renk gibi görsel
/// tanımlar sunum katmanındaki `WerewolfRoleStyle` extension'ındadır.
enum WerewolfRole {
  vampir(
    label: 'Vampir',
    description: 'Her gece sıran geldiğinde avlayacağın köylüyü gizlice seç. '
        'Vampirlerin en çok seçtiği kişi saldırıya uğrar. Gündüz masum görün.',
    goal: 'Köylülerin sayısını kendi sayınıza indirin.',
    team: WerewolfTeam.vampires,
  ),
  koylu(
    label: 'Köylü',
    description: 'Özel bir gücün yok ama oyun var. Gündüz tartışmalarında '
        'vampirleri ele veren ipuçlarını yakala.',
    goal: 'Tüm vampirleri köyden sürün.',
    team: WerewolfTeam.villagers,
  ),
  doktor(
    label: 'Doktor',
    description: 'Her gece bir kişiyi koru. Vampirler o kişiye saldırırsa '
        'kurtulur. Aynı kişiyi art arda iki gece koruyamazsın.',
    goal: 'Köylüleri hayatta tut, vampirleri bul.',
    team: WerewolfTeam.villagers,
  ),
  cadi(
    label: 'Cadı',
    description: 'Bir iyileştirme ve bir zehir iksirin var; her biri oyunda '
        'bir kez kullanılır. İyileştirdiğin kişi o gece vampir saldırısından '
        'kurtulur, zehirlediğin kişi ölür.',
    goal: 'İksirlerini doğru anda kullanarak köyü kurtar.',
    team: WerewolfTeam.villagers,
  ),
  kahin(
    label: 'Kâhin',
    description: 'Oyun boyunca SADECE BİR KEZ, bir gece seçtiğin oyuncunun '
        'gerçek rolünü öğrenebilirsin. Hakkını iyi zamanla.',
    goal: 'Doğru kişiyi sorgula, köyü doğru yöne çek.',
    team: WerewolfTeam.villagers,
  ),
  avci(
    label: 'Avcı',
    description: 'Oyun boyunca tek kurşunun var. Gece ya da oylamayla '
        'elendiğin an, istersen bu kurşunla yaşayan bir oyuncuyu da '
        'yanında götürürsün.',
    goal: 'Ölürken bile doğru kişiyi vur.',
    team: WerewolfTeam.villagers,
  );

  const WerewolfRole({
    required this.label,
    required this.description,
    required this.goal,
    required this.team,
  });

  /// Ekranda gösterilen Türkçe ad.
  final String label;

  /// Rolün yeteneği / nasıl oynandığı.
  final String description;

  /// Kısa kazanma hedefi.
  final String goal;

  final WerewolfTeam team;

  bool get isVampire => team == WerewolfTeam.vampires;

  /// Köylü takımındaki özel roller (düz köylü dışındakiler).
  static const List<WerewolfRole> specialRoles = [doktor, cadi, kahin, avci];
}

/// Eşit oy durumunda uygulanacak kural.
enum WerewolfTieBreak {
  noElimination('Kimse Elenmez'),
  randomDraw('Kura Çekilir');

  const WerewolfTieBreak(this.label);

  final String label;
}
