import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Rehberdeki bir bölüm: başlık ve maddeler.
class GuideSection {
  const GuideSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<String> items;
}

/// Platformdaki oyunların "Nasıl Oynanır?" rehberleri.
enum GameGuide {
  imposter(
    title: 'Imposter',
    tagline: 'Aranızdaki yalancıyı bulun.',
    color: AppColors.primary,
    icon: Icons.person_search,
    sections: [
      GuideSection(
        icon: Icons.flag,
        title: 'Amaç',
        items: [
          'Herkes aynı gizli kelimeyi görür; Imposter ise yalnızca kendisinin '
              'Imposter olduğunu öğrenir.',
          'Masumlar Imposter\'ı bulmaya, Imposter ise yakalanmamaya çalışır.',
        ],
      ),
      GuideSection(
        icon: Icons.phone_android,
        title: 'Tek Telefon Akışı',
        items: [
          'Telefon sırayla herkese verilir. Ekrandaki ismi gören kişi butonu '
              'basılı tutarak rolünü gizlice öğrenir.',
          '"Anladım, Gizle" ile rol kapanır ve telefon sıradakine geçer.',
          'Herkes rolünü görünce sayaç başlar.',
        ],
      ),
      GuideSection(
        icon: Icons.record_voice_over,
        title: 'Tur',
        items: [
          'Sırayla gizli kelimeyle ilgili birer ipucu verin. Kelimeyi doğrudan '
              'söylemek yasak!',
          'Imposter kelimeyi bilmez; ipuçlarından tahmin edip uyum sağlamaya '
              'çalışır.',
        ],
      ),
      GuideSection(
        icon: Icons.how_to_vote,
        title: 'Oylama ve Sonuç',
        items: [
          'Süre bitince grup tartışıp elenecek TEK kişiyi birlikte seçer.',
          'Elenen Imposter ise masumlar, değilse Imposter kazanır.',
        ],
      ),
    ],
  ),
  taboo(
    title: 'Tabu',
    tagline: 'Anlat ama yasaklı kelimeleri sakın söyleme!',
    color: AppColors.tertiary,
    icon: Icons.record_voice_over,
    sections: [
      GuideSection(
        icon: Icons.groups,
        title: 'Takımlar',
        items: [
          'İki takım sırayla oynar. Sırası gelen takımdan bir anlatıcı '
              'telefonu alır; takım arkadaşları ekranı görmez.',
        ],
      ),
      GuideSection(
        icon: Icons.style,
        title: 'Kartlar',
        items: [
          'Anlatıcı ekrandaki kelimeyi, altındaki 5 yasaklı kelimeyi '
              'kullanmadan anlatır.',
          'DOĞRU: +1 puan. TABU! (yasaklı kelime söylendi): −1 puan.',
          'PAS: puan değişmez, kart değişir. Pas hakkı tur başına sınırlıdır.',
        ],
      ),
      GuideSection(
        icon: Icons.emoji_events,
        title: 'Kazanma',
        items: [
          'İki takım eşit sayıda tur oynadığında hedef skora ulaşan ve önde '
              'olan takım kazanır. Eşitlikte oyun devam eder.',
        ],
      ),
    ],
  ),
  werewolf(
    title: 'Vampir Köylü',
    tagline: 'Geceleri vampirler avlanır, gündüzleri köy oylar.',
    color: AppColors.nightAccent,
    icon: Icons.nights_stay,
    sections: [
      GuideSection(
        icon: Icons.badge,
        title: 'Roller',
        items: [
          'Vampir: Her gece av seçer. Vampirlerin en çok seçtiği kişi '
              'saldırıya uğrar.',
          'Doktor: Her gece birini korur (aynı kişiyi art arda iki gece '
              'koruyamaz).',
          'Cadı: Oyun boyunca bir iyileştirme ve bir zehir iksiri vardır.',
          'Kâhin: Oyun boyunca TEK KEZ bir oyuncunun rolünü öğrenir.',
          'Avcı: Tek kurşunu vardır; elendiği an isterse birini yanında '
              'götürür.',
          'Köylü: Özel gücü yoktur; tartışmalarda vampirleri yakalamaya '
              'çalışır.',
        ],
      ),
      GuideSection(
        icon: Icons.nights_stay,
        title: 'Gece (Tek Telefon)',
        items: [
          'Telefon sırayla YAŞAYAN HERKESİN eline geçer; böylece kimin özel '
              'rolü olduğu anlaşılmaz.',
          'Ekranın kilidi basılı tutularak açılır. Hakkı olan hamlesini yapar, '
              'olmayan "Aksiyonun Yok" görür ve telefonu sıradakine verir.',
        ],
      ),
      GuideSection(
        icon: Icons.wb_sunny,
        title: 'Gündüz ve Oylama',
        items: [
          'Sabah gece olanlar duyurulur, köy tartışır.',
          'Herkes telefonu sırayla alıp kendisi dışındaki birine GİZLİCE oy '
              'verir. En çok oy alan sürgün edilir.',
          'Eşitlikte, ayara göre kimse elenmez ya da kura çekilir.',
        ],
      ),
      GuideSection(
        icon: Icons.emoji_events,
        title: 'Kazanma',
        items: [
          'Tüm vampirler elenirse Köylüler kazanır.',
          'Vampir sayısı köylü sayısına eşitlenirse Vampirler kazanır.',
        ],
      ),
    ],
  ),
  spy(
    title: 'Ajan',
    tagline: 'Herkes konumu biliyor, biri hariç.',
    color: AppColors.secondary,
    icon: Icons.policy,
    sections: [
      GuideSection(
        icon: Icons.place,
        title: 'Roller',
        items: [
          'Masumlar gizli konumu ve o konumdaki rollerini görür '
              '(örn. Korsan Gemisi · Kaptan).',
          'Ajan konumu bilmez; sorulardan çözmeye çalışır.',
        ],
      ),
      GuideSection(
        icon: Icons.question_answer,
        title: 'Soru-Cevap',
        items: [
          'İlk soruyu ekranda adı yazan oyuncu sorar. Cevap veren sıradaki '
              'soruyu sorar.',
          'Sorular ajana ipucu vermeyecek kadar kapalı, masumları ikna '
              'edecek kadar açık olmalı.',
        ],
      ),
      GuideSection(
        icon: Icons.policy,
        title: 'Ajanın Hamlesi',
        items: [
          'Ajan istediği an oyunu durdurup konumu tahmin edebilir. Doğruysa '
              'ajan, yanlışsa masumlar kazanır.',
        ],
      ),
      GuideSection(
        icon: Icons.how_to_vote,
        title: 'Oylama',
        items: [
          'Telefon sırayla herkese verilir; herkes ajan olduğunu düşündüğü '
              'kişiye gizlice oy verir.',
          'Masum biri suçlanırsa ya da oylar eşitse ajan kazanır.',
          'Ajan yakalanırsa konumu tahmin etmek için son bir şansı olur.',
        ],
      ),
    ],
  ),
  bomb(
    title: 'Tik Tak Bomba',
    tagline: 'Cevabını söyle, bombayı geçir!',
    color: AppColors.warning,
    icon: Icons.local_fire_department,
    sections: [
      GuideSection(
        icon: Icons.record_voice_over,
        title: 'Tur',
        items: [
          'Ekranda bir görev çıkar (örn. "Bir meyve söyle"). Bomba sendeyse '
              'göreve uygun bir cevabı yüksek sesle söyle.',
          'Aynı turda söylenmiş bir cevabı tekrar etmek yok; tereddüt eden '
              'vakit kaybeder!',
          '"GEÇİR"e dokun ve telefonu hemen sıradaki oyuncuya ver.',
        ],
      ),
      GuideSection(
        icon: Icons.local_fire_department,
        title: 'Patlama',
        items: [
          'Fitilin süresi gizlidir ve her tur değişir. Tik sesleri zamanla '
              'hızlanır ama patlama anını ele vermez.',
          'Bomba patladığında telefon kimdeyse o tur o oyuncu patlar. '
              'Sonraki turu patlayan oyuncu başlatır.',
          'Uygulamadan çıkınca fitil durur, dönünce kaldığı yerden devam '
              'eder.',
        ],
      ),
      GuideSection(
        icon: Icons.emoji_events,
        title: 'Kazanma',
        items: [
          'Seçilen tur sayısı bitince en az patlayan kazanır; en çok patlayan '
              'ise gecenin "bomba mıknatısı" olur.',
        ],
      ),
    ],
  );

  const GameGuide({
    required this.title,
    required this.tagline,
    required this.color,
    required this.icon,
    required this.sections,
  });

  final String title;
  final String tagline;
  final Color color;
  final IconData icon;
  final List<GuideSection> sections;
}

/// Oyunun "Nasıl Oynanır?" rehberini alt sayfa olarak açar.
Future<void> showHowToPlaySheet(BuildContext context, GameGuide guide) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceElevated,
    barrierColor: AppColors.overlay,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) =>
          _GuideContent(guide: guide, controller: controller),
    ),
  );
}

class _GuideContent extends StatelessWidget {
  const _GuideContent({required this.guide, required this.controller});

  final GameGuide guide;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(AppSpacing.l),
      children: [
        Row(
          children: [
            Icon(guide.icon, color: guide.color, size: AppSpacing.xl),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${guide.title} · Nasıl Oynanır?',
                    style: AppTypography.headline,
                  ),
                  Text(guide.tagline, style: AppTypography.bodyMedium),
                ],
              ),
            ),
          ],
        ),
        for (final section in guide.sections) ...[
          const SizedBox(height: AppSpacing.l),
          Row(
            children: [
              Icon(section.icon, size: AppSpacing.l, color: guide.color),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  section.title,
                  style: AppTypography.title.copyWith(color: guide.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          for (final item in section.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s),
                    child: Container(
                      width: AppSpacing.xs + 2,
                      height: AppSpacing.xs + 2,
                      decoration: BoxDecoration(
                        color: guide.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(item, style: AppTypography.bodyLarge),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// Kurulum ekranlarının üst çubuğundaki belirgin "Nasıl Oynanır?" butonu.
class HowToPlayButton extends StatelessWidget {
  const HowToPlayButton({super.key, required this.guide});

  final GameGuide guide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s),
      child: TextButton.icon(
        onPressed: () => showHowToPlaySheet(context, guide),
        style: TextButton.styleFrom(foregroundColor: guide.color),
        icon: const Icon(Icons.help_outline),
        label: Text(
          'Nasıl Oynanır?',
          style: AppTypography.label.copyWith(color: guide.color),
        ),
      ),
    );
  }
}
