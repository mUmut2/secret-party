import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/turkish_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

const double _gameIconSize = 32;

/// Platformdaki oynanabilir bir oyunun vitrin bilgisi.
class _GameEntry {
  const _GameEntry({
    required this.name,
    required this.tagline,
    required this.playerCount,
    required this.icon,
    required this.accentColor,
    required this.route,
  });

  final String name;
  final String tagline;
  final String playerCount;
  final IconData icon;
  final Color accentColor;

  /// Oyunun kurulum ekranının rotası.
  final String route;
}

/// Oyun modu seçim ekranı: platformdaki tüm aktif oyunlar.
///
/// Yeni bir oyun eklemek için [_games] listesine bir kayıt eklemek yeterlidir.
class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  static const List<_GameEntry> _games = [
    _GameEntry(
      name: 'Imposter',
      tagline: 'Aranızdaki yalancıyı bulun.',
      playerCount: '4-10 Oyuncu',
      icon: Icons.person_search,
      accentColor: AppColors.primary,
      route: AppRouter.playerSetup,
    ),
    _GameEntry(
      name: 'Tabu',
      tagline: 'Anlat ama yasaklı kelimeleri sakın söyleme!',
      playerCount: '2 Takım · 4+ Oyuncu',
      icon: Icons.record_voice_over,
      accentColor: AppColors.tertiary,
      route: AppRouter.tabooSetup,
    ),
    _GameEntry(
      name: 'Vampir Köylü',
      tagline:
          'Geceleri vampirler avlanır, gündüzleri köy oylar. Kimseye güvenme!',
      playerCount: '5-16 Oyuncu',
      icon: Icons.nights_stay,
      accentColor: AppColors.nightAccent,
      route: AppRouter.werewolfSetup,
    ),
    _GameEntry(
      name: 'Ajan',
      tagline: 'Herkes konumu biliyor, biri hariç. Soru sor, blöf yap, '
          'ajanı bul!',
      playerCount: '3-9 Oyuncu',
      icon: Icons.policy,
      accentColor: AppColors.secondary,
      route: AppRouter.spySetup,
    ),
    _GameEntry(
      name: 'Tik Tak Bomba',
      tagline: 'Görevi cevapla, bombayı geçir. Fitil gizli; patladığında '
          'bomba kimdeyse o yanar!',
      playerCount: '3-10 Oyuncu',
      icon: Icons.local_fire_department,
      accentColor: AppColors.warning,
      route: AppRouter.bombSetup,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oyun Seç'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Ana menüye dön',
          onPressed: () => context.go(AppRouter.home),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.l),
          itemCount: _games.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
          itemBuilder: (context, index) {
            final game = _games[index];
            return _GameCard(
              game: game,
              highlighted: index == 0,
              onPlay: () => context.go(game.route),
            );
          },
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.highlighted,
    required this.onPlay,
  });

  final _GameEntry game;
  final bool highlighted;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: highlighted ? CardVariant.highlighted : CardVariant.standard,
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(game.icon, size: _gameIconSize, color: game.accentColor),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Text(game.name, style: AppTypography.headline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Text(game.tagline, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.s),
          Text(
            game.playerCount.toUpperTr(),
            style: AppTypography.caption.copyWith(color: game.accentColor),
          ),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Oyna',
            variant:
                highlighted ? ButtonVariant.primary : ButtonVariant.outlined,
            fullWidth: true,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}
