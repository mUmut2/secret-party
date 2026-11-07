import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/utils/turkish_text.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/repositories/bomb_task_repository.dart';
import '../../../domain/models/bomb/bomb_game_state.dart';
import '../viewmodels/bomb_game_notifier.dart';
import '../widgets/bomb_exit.dart';
import '../widgets/bomb_graphic.dart';
import '../widgets/bomb_missing_game_view.dart';

const double _bombSize = 180;
const double _tickPulseScale = 1.06;
const double _passPulseScale = 1.12;

/// Bomba turu: görev, yanan bomba, bombayı tutan oyuncu ve büyük "GEÇİR".
///
/// GİZLİLİK: Ekranda kalan süre, sayı, ilerleme çubuğu ya da süreyi ele veren
/// bir ekran okuyucu etiketi YOKTUR. Bomba yalnızca tik anlarında (tempo
/// turun başından beri geçen süreye bağlı) ve "GEÇİR"de hafifçe nabız atar.
///
/// Uygulama arka plana alınınca fitil durur, dönünce kaldığı yerden devam
/// eder.
class BombPlayScreen extends ConsumerStatefulWidget {
  const BombPlayScreen({super.key});

  @override
  ConsumerState<BombPlayScreen> createState() => _BombPlayScreenState();
}

class _BombPlayScreenState extends ConsumerState<BombPlayScreen> {
  late final AppLifecycleListener _lifecycle;
  bool _inBackground = false;

  /// "GEÇİR" nabzını tetikleyen sayaç.
  int _passPulse = 0;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleChanged);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onLifecycleChanged(AppLifecycleState lifecycle) {
    final notifier = ref.read(bombGameProvider.notifier);
    final background = lifecycle != AppLifecycleState.resumed;
    if (background == _inBackground) return;
    _inBackground = background;
    if (background) {
      notifier.pause();
    } else {
      notifier.resume();
    }
  }

  void _pass() {
    final passed = ref.read(bombGameProvider.notifier).passBomb();
    if (passed) setState(() => _passPulse++);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bombGameProvider.select((game) => game?.phase), (_, phase) {
      if (phase == BombPhase.exploded) context.go(AppRouter.bombExplosion);
    });

    final game = ref.watch(bombGameProvider);
    if (game == null) return const BombMissingGameView();
    final categoryName = ref
        .watch(bombTaskRepositoryProvider)
        .categoryNames[game.task.categoryId];

    return BombExitScope(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const BombExitButton(),
                    const Spacer(),
                    Text(
                      'TUR ${game.roundNumber} / ${game.totalRounds}',
                      style: AppTypography.label.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                _TaskCard(prompt: game.task.prompt, category: categoryName),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PulsingBomb(passPulse: _passPulse),
                          const SizedBox(height: AppSpacing.m),
                          const Text(
                            'Bomba şu an',
                            style: AppTypography.bodyMedium,
                          ),
                          Text(
                            game.holder.name,
                            textAlign: TextAlign.center,
                            style: AppTypography.headline.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Text(
                  'Cevabını söyle, sonra geçir!',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.s),
                AppButton(
                  label: 'Geçir',
                  variant: ButtonVariant.warning,
                  fullWidth: true,
                  onPressed: game.phase == BombPhase.ticking ? _pass : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.prompt, required this.category});

  final String prompt;
  final String? category;

  @override
  Widget build(BuildContext context) {
    final category = this.category;
    return AppCard(
      variant: CardVariant.elevated,
      child: Column(
        children: [
          if (category != null)
            Text(
              category.toUpperTr(),
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: AppColors.warning),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            prompt,
            textAlign: TextAlign.center,
            style: AppTypography.headline,
          ),
        ],
      ),
    );
  }
}

/// Tik ve "GEÇİR" anlarında kısa nabız atan bomba. Hareketi azalt açıksa
/// sabit durur.
class _PulsingBomb extends ConsumerWidget {
  const _PulsingBomb({required this.passPulse});

  final int passPulse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tick = ref.watch(bombTickProvider);
    final bomb = Semantics(
      label: 'Bomba, fitil yanıyor',
      excludeSemantics: true,
      child: const BombGraphic(size: _bombSize),
    );
    if (AppMotion.reduceMotion(context)) return bomb;

    // Her tik ve her geçişte yeni anahtar: animasyon büyükten normale döner.
    return _Pulse(
      key: ValueKey('pass-$passPulse'),
      fromScale: passPulse == 0 ? 1 : _passPulseScale,
      child: _Pulse(
        key: ValueKey('tick-$tick'),
        fromScale: tick == 0 ? 1 : _tickPulseScale,
        child: bomb,
      ),
    );
  }
}

class _Pulse extends StatelessWidget {
  const _Pulse({super.key, required this.fromScale, required this.child});

  final double fromScale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: fromScale, end: 1),
      duration: AppMotion.base,
      curve: AppMotion.standardCurve,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}
