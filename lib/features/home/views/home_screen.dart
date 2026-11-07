import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/utils/turkish_text.dart';

/// Uygulamanın ana ekranı: başlık → Imposter hero kartı → diğer oyun kartları.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: AppSpacing.xl,
          ),
          children: [
            const _Header(),
            const SizedBox(height: AppSpacing.xxl),
            _ImposterHeroCard(
              onPlay: () => context.go(AppRouter.gameSelection),
            ),
            const SizedBox(height: AppSpacing.m),
            _TabooCard(onPlay: () => context.go(AppRouter.tabooSetup)),
            const SizedBox(height: AppSpacing.m),
            _WerewolfCard(onPlay: () => context.go(AppRouter.werewolfSetup)),
            const SizedBox(height: AppSpacing.m),
            _SpyCard(onPlay: () => context.go(AppRouter.spySetup)),
            const SizedBox(height: AppSpacing.m),
            _BombCard(onPlay: () => context.go(AppRouter.bombSetup)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Secret Party', style: AppTypography.display),
              ),
              SizedBox(height: AppSpacing.xs),
              Text('Oyununu seç', style: AppTypography.bodyMedium),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.go(AppRouter.settings),
          tooltip: 'Ayarlar',
          icon: const Icon(Icons.settings, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ImposterHeroCard extends StatelessWidget {
  const _ImposterHeroCard({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: CardVariant.highlighted,
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text('Imposter', style: AppTypography.headline),
              ),
              SizedBox(width: AppSpacing.s),
              _PlayerCountBadge(label: '4-10 Oyuncu'),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          const Text(
            'Aranızdaki yalancıyı bulun.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Oyna',
            variant: ButtonVariant.primary,
            fullWidth: true,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

/// Tabu giriş kartı: doğrudan Tabu kurulumuna götürür.
class _TabooCard extends StatelessWidget {
  const _TabooCard({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text('Tabu', style: AppTypography.headline),
              ),
              SizedBox(width: AppSpacing.s),
              _PlayerCountBadge(
                label: '2 Takım',
                color: AppColors.tertiary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          const Text(
            'Anlat ama yasaklı kelimeleri sakın söyleme!',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Oyna',
            variant: ButtonVariant.outlined,
            fullWidth: true,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

/// Vampir Köylü giriş kartı: gece temalı, doğrudan kurulum ekranına götürür.
class _WerewolfCard extends StatelessWidget {
  const _WerewolfCard({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: CardVariant.night,
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text('Vampir Köylü', style: AppTypography.headline),
              ),
              SizedBox(width: AppSpacing.s),
              _PlayerCountBadge(
                label: '5-16 Oyuncu',
                color: AppColors.nightAccent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          const Text(
            'Geceleri vampirler avlanır, gündüzleri köy oylar.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Oyna',
            variant: ButtonVariant.night,
            fullWidth: true,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

/// Ajan (Spyfall) giriş kartı: doğrudan Ajan kurulumuna götürür.
class _SpyCard extends StatelessWidget {
  const _SpyCard({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text('Ajan', style: AppTypography.headline),
              ),
              SizedBox(width: AppSpacing.s),
              _PlayerCountBadge(
                label: '3-9 Oyuncu',
                color: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          const Text(
            'Herkes konumu biliyor, biri hariç. Ajanı bul!',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Oyna',
            variant: ButtonVariant.secondary,
            fullWidth: true,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

/// Tik Tak Bomba giriş kartı: doğrudan kuruluma götürür.
class _BombCard extends StatelessWidget {
  const _BombCard({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text('Tik Tak Bomba', style: AppTypography.headline),
              ),
              SizedBox(width: AppSpacing.s),
              _PlayerCountBadge(
                label: '3-10 Oyuncu',
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          const Text(
            'Cevabını söyle, bombayı geçir. Patlarsa yandın!',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.l),
          AppButton(
            label: 'Oyna',
            variant: ButtonVariant.warning,
            fullWidth: true,
            onPressed: onPlay,
          ),
        ],
      ),
    );
  }
}

class _PlayerCountBadge extends StatelessWidget {
  const _PlayerCountBadge({
    required this.label,
    this.color = AppColors.primary,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color),
      ),
      child: Text(
        label.toUpperTr(),
        style: AppTypography.caption.copyWith(color: color),
      ),
    );
  }
}
