import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../domain/models/werewolf/werewolf_game_state.dart';
import '../../../domain/models/werewolf/werewolf_role.dart';
import '../viewmodels/werewolf_game_notifier.dart';
import 'werewolf_player_picker.dart';
import 'werewolf_role_style.dart';

const double _iconSize = 56;
const double _borderWidth = 2;

/// "Avcı Elendi! Tek Kurşun Hakkını Kullanmak İstiyor musun?" paneli.
///
/// Avcı gece öldürüldüğünde (gündüz duyurusunda) ya da oylamayla
/// sürüldüğünde (sonuç ekranında) açılır. Avcı ister bir kişiyi vurur,
/// ister kurşunu kullanmadan oyundan çıkar. Karar verilmeden oyun ilerlemez.
class WerewolfHunterDecision extends ConsumerStatefulWidget {
  const WerewolfHunterDecision({super.key, required this.game});

  final WerewolfGameState game;

  @override
  ConsumerState<WerewolfHunterDecision> createState() =>
      _WerewolfHunterDecisionState();
}

class _WerewolfHunterDecisionState
    extends ConsumerState<WerewolfHunterDecision> {
  bool _aiming = false;
  String? _targetId;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final hunter = game.tryPlayerById(game.pendingHunterId);
    if (hunter == null) return const SizedBox.shrink();

    const role = WerewolfRole.avci;
    final notifier = ref.read(werewolfGameProvider.notifier);
    final options = ref.read(werewolfEngineProvider).hunterOptions(game);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: role.color, width: _borderWidth),
        boxShadow: AppShadows.glowWarning,
      ),
      child: AnimatedSize(
        duration: AppMotion.base,
        curve: AppMotion.standardCurve,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(role.icon, size: _iconSize, color: role.color),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Avcı Elendi!',
              textAlign: TextAlign.center,
              style: AppTypography.display.copyWith(color: role.color),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              '${hunter.name}, tek kurşun hakkını kullanmak istiyor musun?',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Vurduğun kişi de seninle birlikte anında oyundan çıkar.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.l),
            if (!_aiming) ...[
              AppButton(
                label: 'Evet, Ateş Et',
                variant: ButtonVariant.warning,
                fullWidth: true,
                onPressed: () => setState(() => _aiming = true),
              ),
              const SizedBox(height: AppSpacing.s),
              AppButton(
                label: 'Hayır, Kurşunu Kullanma',
                variant: ButtonVariant.ghost,
                fullWidth: true,
                onPressed: notifier.hunterHoldFire,
              ),
            ] else ...[
              Text(
                'Kimi vuruyorsun?',
                style: AppTypography.title.copyWith(color: role.color),
              ),
              const SizedBox(height: AppSpacing.s),
              WerewolfPlayerPicker(
                players: options,
                selectedId: _targetId,
                accentColor: role.color,
                surfaceColor: AppColors.surface,
                semanticAction: 'vur',
                onSelected: (id) => setState(() => _targetId = id),
              ),
              const SizedBox(height: AppSpacing.m),
              AppButton(
                label: 'Tetiği Çek',
                variant: ButtonVariant.danger,
                fullWidth: true,
                // Titreşim (heavyImpact) notifier'da tetiklenir.
                haptics: false,
                onPressed: _targetId == null
                    ? null
                    : () => notifier.hunterShoot(_targetId!),
              ),
              const SizedBox(height: AppSpacing.s),
              AppButton(
                label: 'Geri',
                variant: ButtonVariant.ghost,
                fullWidth: true,
                onPressed: () => setState(() {
                  _aiming = false;
                  _targetId = null;
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
