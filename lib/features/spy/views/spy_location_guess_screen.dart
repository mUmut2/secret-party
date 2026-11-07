import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_hold_button.dart';
import '../../../domain/models/spy/spy_game_state.dart';
import '../../../domain/models/spy/spy_location.dart';
import '../viewmodels/spy_game_notifier.dart';
import '../widgets/spy_dialogs.dart';
import '../widgets/spy_missing_game_view.dart';

const int _gridColumns = 2;
const double _tileAspectRatio = 2.4;
const double _tileBorderWidth = 1.5;

/// Ajanın konum tahmini ekranı.
///
/// İki durumda açılır:
/// - Ajan oyunu kendisi durdurdu ("Ajanım, Konumu Tahmin Edeceğim!").
/// - Ajan oylamada yakalandı; SON ŞANSI.
///
/// Tüm konumlar grid halinde dizilir. Tahmin geri alınamaz olduğu için
/// onay butonu KİLİTLİDİR (basılı tutulmalı).
class SpyLocationGuessScreen extends ConsumerStatefulWidget {
  const SpyLocationGuessScreen({super.key});

  @override
  ConsumerState<SpyLocationGuessScreen> createState() =>
      _SpyLocationGuessScreenState();
}

class _SpyLocationGuessScreenState
    extends ConsumerState<SpyLocationGuessScreen> {
  String? _selected;

  Future<void> _requestExit() async {
    final approved = await confirmSpyExit(context);
    if (!approved || !mounted) return;
    ref.read(spyGameProvider.notifier).quit();
    context.go(AppRouter.gameSelection);
  }

  void _confirmGuess() {
    final selected = _selected;
    if (selected == null) return;
    ref.read(spyGameProvider.notifier).guessLocation(selected);
    context.go(AppRouter.spyResult);
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(spyGameProvider);
    if (game == null) return const SpyMissingGameView();

    final caught = game.guessReason == SpyGuessReason.caughtByVote;
    final accused = game.accused;
    final title = caught ? 'Yakalandın! Son Şansın' : 'Konumu Tahmin Et';
    final message = caught
        ? '${accused?.name ?? 'Ajan'}, köy seni buldu. Konumu doğru bilirsen '
            'yine de sen kazanırsın!'
        : 'Ajan kendini açık etti. Konumu doğru bilirsen kazanırsın; '
            'yanılırsan masumlar kazanır.';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.policy, color: AppColors.secondary),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.headline.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.m),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridColumns,
                      mainAxisSpacing: AppSpacing.s,
                      crossAxisSpacing: AppSpacing.s,
                      childAspectRatio: _tileAspectRatio,
                    ),
                    itemCount: game.allLocations.length,
                    itemBuilder: (context, index) {
                      final location = game.allLocations[index];
                      return _LocationTile(
                        location: location,
                        isSelected: location.name == _selected,
                        onTap: () => setState(() => _selected = location.name),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                if (_selected == null)
                  const AppButton(
                    label: 'Bir Konum Seç',
                    variant: ButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: null,
                  )
                else
                  AppHoldButton(
                    label: 'Tahmin: $_selected',
                    color: AppColors.secondary,
                    onConfirmed: _confirmGuess,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  final SpyLocation location;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.secondary;
    return Semantics(
      button: true,
      selected: isSelected,
      label: location.name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standardCurve,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.m),
            border: Border.all(
              color: isSelected ? color : AppColors.divider,
              width: _tileBorderWidth,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: AppShadows.glow(color, 0.4), blurRadius: 16)
                  ]
                : null,
          ),
          child: Text(
            location.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
