import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/turkish_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../domain/services/game_engine_notifier.dart';
import '../../../core/widgets/app_hold_button.dart';
import '../viewmodels/role_reveal_notifier.dart';
import '../widgets/imposter_exit.dart';
import '../viewmodels/round_notifier.dart';

const double _revealEntryScaleStart = 0.6;
const double _handOffScaleStart = 0.92;
const Offset _handOffSlideStart = Offset(0, 0.06);

/// Telefon elden ele geçerken kullanılan hızlı "yukarı kayarak büyüme"
/// geçişi. Kısa ve sert tutulur: gerilimi artırır, oyunu yavaşlatmaz.
Widget _handOffTransition(Widget child, Animation<double> animation) {
  return FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween<Offset>(begin: _handOffSlideStart, end: Offset.zero)
          .animate(animation),
      child: ScaleTransition(
        scale: Tween<double>(begin: _handOffScaleStart, end: 1.0)
            .animate(animation),
        child: child,
      ),
    ),
  );
}

/// Pass-and-play rol gösterme ekranı.
///
/// Güvenlik: "Anladım, Gizle" adımı zorunludur. Adımlar route değil bu
/// widget'ın state'iyle yönetildiği için geri tuşu önceki oyuncunun
/// bilgisini tekrar göstermez.
class RoleRevealScreen extends ConsumerWidget {
  const RoleRevealScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider);
    final revealState = ref.watch(roleRevealProvider);

    if (session == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Aktif bir oyun oturumu bulunamadı.',
            style: AppTypography.bodyLarge,
          ),
        ),
      );
    }

    if (revealState.allPlayersRevealed) {
      return ImposterExitGuard(
        child: _AllRevealedStep(
          playerCount: session.players.length,
          roundDurationSeconds: session.roundDurationSeconds,
        ),
      );
    }

    final currentPlayer = session.players[revealState.currentPlayerIndex];

    return ImposterExitGuard(
      // Geri tuşu: çıkış onayı açılmadan önce açık kart kapanır; gizli
      // kelime / ipucu yarı saydam pencerenin arkasında görünmez.
      onBack: ref.read(roleRevealProvider.notifier).conceal,
      child: _ConcealOnLeave(
        child: Scaffold(
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.standardCurve,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: _handOffTransition,
              child: revealState.isRevealed
                  ? _RoleRevealedStep(
                      key: const ValueKey('revealed'),
                      isImposter: currentPlayer.id == session.imposterId,
                      category: session.category,
                      secretWord: session.secretWord,
                      // İpucu YALNIZCA Imposter'ın kartına verilir.
                      imposterHint: currentPlayer.id == session.imposterId
                          ? session.imposterHint
                          : null,
                      onHide: () => ref
                          .read(roleRevealProvider.notifier)
                          .hideAndAdvance(totalPlayers: session.players.length),
                    )
                  : _PassPhoneStep(
                      // Index anahtarda: her yeni oyuncu kendi geçişiyle girer.
                      key: ValueKey('hidden_${revealState.currentPlayerIndex}'),
                      playerName: currentPlayer.name,
                      onReveal: () => ref
                          .read(roleRevealProvider.notifier)
                          .revealCurrentPlayer(),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uygulama ön plandan çıktığında (arka plana alma, gelen çağrı, bildirim
/// paneli, uygulama değiştirici) açık rol kartını kapatır.
///
/// İşletim sistemi uygulama değiştiricide son ekranın görüntüsünü gösterir;
/// kart açık kalsaydı gizli kelime ya da Imposter ipucu orada görünürdü.
class _ConcealOnLeave extends ConsumerStatefulWidget {
  const _ConcealOnLeave({required this.child});

  final Widget child;

  @override
  ConsumerState<_ConcealOnLeave> createState() => _ConcealOnLeaveState();
}

class _ConcealOnLeaveState extends ConsumerState<_ConcealOnLeave> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onInactive: _conceal,
      onHide: _conceal,
      onPause: _conceal,
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  void _conceal() => ref.read(roleRevealProvider.notifier).conceal();

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Adım A: "Telefonu [İsim] isimli oyuncuya ver".
class _PassPhoneStep extends StatelessWidget {
  const _PassPhoneStep({
    super.key,
    required this.playerName,
    required this.onReveal,
  });

  final String playerName;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppSpacing.l),
      alignment: Alignment.center,
      // Uzun kelime / büyük sistem yazı boyutunda içerik taşmasın diye
      // kaydırılabilir.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Telefonu $playerName isimli oyuncuya ver',
              textAlign: TextAlign.center,
              style: AppTypography.headline,
            ),
            const SizedBox(height: AppSpacing.xxl),
            // Kilitli onay: yanlışlıkla dokunuşla rol açılmaz, butonun
            // basılı tutulması gerekir.
            AppHoldButton(
              label: 'Ben $playerName · Basılı Tut',
              onConfirmed: onReveal,
            ),
          ],
        ),
      ),
    );
  }
}

/// Adım B: rol açıklanıyor (Imposter ya da normal oyuncu).
class _RoleRevealedStep extends StatelessWidget {
  const _RoleRevealedStep({
    super.key,
    required this.isImposter,
    required this.category,
    required this.secretWord,
    required this.imposterHint,
    required this.onHide,
  });

  final bool isImposter;
  final String category;
  final String secretWord;

  /// Imposter'ın ipucu (ayar kapalıysa ya da oyuncu Imposter değilse `null`).
  final String? imposterHint;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isImposter ? AppColors.imposterReveal : AppColors.background;
    final categoryLabel = _capitalize(category);

    return AnimatedContainer(
      duration: AppMotion.dramatic,
      curve: AppMotion.standardCurve,
      color: backgroundColor,
      padding: const EdgeInsets.all(AppSpacing.l),
      alignment: Alignment.center,
      width: double.infinity,
      height: double.infinity,
      // Uzun kelime / büyük sistem yazı boyutunda içerik taşmasın diye
      // kaydırılabilir.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: _revealEntryScaleStart, end: 1.0),
              duration: AppMotion.resolve(context, AppMotion.dramatic),
              curve: AppMotion.dramaticCurve,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: isImposter
                  ? _ImposterContent(hint: imposterHint)
                  : _NormalPlayerContent(
                      categoryLabel: categoryLabel,
                      secretWord: secretWord,
                    ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            // Her iki kartta da aynı buton (rolü ele vermez); koyu kırmızı
            // zeminde dolu lime buton 6.6:1 kontrastla net okunur.
            AppButton(
              label: 'Anladım, Gizle',
              variant: ButtonVariant.primary,
              fullWidth: true,
              onPressed: onHide,
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    final first = text[0] == 'i' ? 'İ' : text[0].toUpperCase();
    return first + text.substring(1);
  }
}

class _ImposterContent extends StatelessWidget {
  const _ImposterContent({required this.hint});

  /// Ayar açıksa gizli kelimeyle ilgili tek kelimelik ipucu.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final hint = this.hint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Koyu kırmızı zeminde beyaz metin: 9:1 kontrast.
        const Text(
          "SEN IMPOSTER'SIN",
          textAlign: TextAlign.center,
          style: AppTypography.gameDisplay,
        ),
        const SizedBox(height: AppSpacing.m),
        const Text(
          'Gizli kelimeyi bulmaya çalış ve yakalanma.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge,
        ),
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.l),
          _HintPanel(hint: hint),
        ],
      ],
    );
  }
}

/// Imposter kartındaki "İpucun" paneli: koyu kırmızı zemin üzerinde belirgin
/// bir kutu. Yalnızca Imposter'ın kartında çizilir.
class _HintPanel extends StatelessWidget {
  const _HintPanel({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'İpucun: $hint',
      excludeSemantics: true,
      child: AppCard(
        variant: CardVariant.elevated,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lightbulb,
                  size: AppSpacing.l,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'İpucun'.toUpperTr(),
                  style: AppTypography.label.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              hint.capitalizeTr(),
              textAlign: TextAlign.center,
              style: AppTypography.display,
            ),
          ],
        ),
      ),
    );
  }
}

class _NormalPlayerContent extends StatelessWidget {
  const _NormalPlayerContent({
    required this.categoryLabel,
    required this.secretWord,
  });

  final String categoryLabel;
  final String secretWord;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Gizli Kelime',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          '$categoryLabel · $secretWord',
          textAlign: TextAlign.center,
          style: AppTypography.gameDisplay.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.m),
        const Text(
          'Imposter\'ı bul.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge,
        ),
      ],
    );
  }
}

/// Adım D: herkes rolünü gördü, tur başlatılabilir.
class _AllRevealedStep extends ConsumerWidget {
  const _AllRevealedStep({
    required this.playerCount,
    required this.roundDurationSeconds,
  });

  final int playerCount;
  final int roundDurationSeconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Herkes rolünü gördü',
                  style: AppTypography.headline,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  '$playerCount oyuncu hazır. İpucu turuna başlayabilirsiniz.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  label: 'Tura Başla',
                  variant: ButtonVariant.primary,
                  fullWidth: true,
                  onPressed: () {
                    ref.read(gameSessionProvider.notifier).beginRound();
                    ref
                        .read(roundProvider.notifier)
                        .start(durationSeconds: roundDurationSeconds);
                    context.go(AppRouter.round);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
