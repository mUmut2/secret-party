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
import '../../../core/widgets/player_avatar.dart';
import '../../../domain/models/game_session.dart';
import '../../../domain/services/game_engine_notifier.dart';

const double _entryScaleStart = 0.6;
const double _verdictIconSize = 56;
const double _imposterAvatarSize = 64;

/// Oyun sonucu ekranı.
///
/// - Masumlar kazandı: lime tonlar, zafer ikonu.
/// - Imposter kazandı: kırmızı tonlar, kayıp ikonu.
///
/// Renk tek başına anlam taşımaz: büyük başlık, ikon ve açık cümle de var.
/// Ekran, gösterdiği bitmiş oturumu kendi içinde saklar. "Tekrar Oyna"ya
/// basılınca yeni oturum hemen başlar; geçiş animasyonu sürerken bu ekranın
/// boş duruma düşmesini engellemek için gereklidir.
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  GameSession? _finishedSession;

  void _replay() {
    ref.read(gameSessionProvider.notifier).restartWithSamePlayers();
    context.go(AppRouter.roleReveal);
  }

  void _goHome() {
    context.go(AppRouter.home);
  }

  @override
  Widget build(BuildContext context) {
    final liveSession = ref.watch(gameSessionProvider);
    if (liveSession?.result != null) {
      _finishedSession = liveSession;
    }

    final session = _finishedSession;
    if (session == null) {
      return _MissingResultView(onGoHome: _goHome);
    }

    final isWin = session.result == GameResult.innocentsWon;

    // Geri tuşuyla sonuç ekranından yanlışlıkla çıkılmasını engeller.
    // Oyun bitti: geri tuşu ana menüye götürür (kaybedilecek ilerleme yok).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: _entryScaleStart, end: 1.0),
                      duration: AppMotion.resolve(context, AppMotion.dramatic),
                      curve: AppMotion.dramaticCurve,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: _ResultContent(session: session, isWin: isWin),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                AppButton(
                  label: 'Yeniden Oyna',
                  variant: ButtonVariant.primary,
                  fullWidth: true,
                  onPressed: _replay,
                ),
                const SizedBox(height: AppSpacing.s),
                AppButton(
                  label: 'Ana Menüye Dön',
                  variant: ButtonVariant.outlined,
                  fullWidth: true,
                  onPressed: _goHome,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sonuç içeriği: ikon, başlık, mesaj, Imposter kartı, gizli kelime kartı.
class _ResultContent extends StatelessWidget {
  const _ResultContent({required this.session, required this.isWin});

  final GameSession session;
  final bool isWin;

  @override
  Widget build(BuildContext context) {
    final imposter = session.imposter;
    final accused = session.accusedPlayer;
    final accentColor = isWin ? AppColors.primary : AppColors.error;
    final verdict = isWin ? 'MASUMLAR KAZANDI' : 'IMPOSTER KAZANDI';
    final message = isWin
        ? 'Tebrikler, Imposter\'ı Buldunuz!'
        : 'Yanlış Kişiyi Elediniz! Imposter ${imposter.name} İdi.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          isWin ? Icons.emoji_events : Icons.cancel,
          color: accentColor,
          size: _verdictIconSize,
          semanticLabel: isWin ? 'Zafer' : 'Kayıp',
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          verdict,
          textAlign: TextAlign.center,
          style: AppTypography.gameDisplay.copyWith(color: accentColor),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.headline,
        ),
        if (!isWin && accused != null) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            'Elediğiniz kişi: ${accused.name}',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          variant: isWin ? CardVariant.highlighted : CardVariant.danger,
          child: Row(
            children: [
              PlayerAvatar(
                name: imposter.name,
                size: _imposterAvatarSize,
                state: AvatarState.imposter,
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IMPOSTER',
                      style: AppTypography.label.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      imposter.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headline,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        AppCard(
          child: Column(
            children: [
              const Text('Gizli Kelime', style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                session.secretWord,
                textAlign: TextAlign.center,
                style: AppTypography.headline.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                session.category.capitalizeTr(),
                style: AppTypography.caption,
              ),
              // Yalnızca ipucu kullanıldıysa gösterilir.
              if (session.imposterHint case final hint?) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  "Imposter'a verilen ipucu: ${hint.capitalizeTr()}",
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Oylama yapılmadan bu ekrana gelinirse gösterilen güvenli boş durum.
class _MissingResultView extends StatelessWidget {
  const _MissingResultView({required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Gösterilecek bir oyun sonucu bulunamadı.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Ana Menüye Dön',
                variant: ButtonVariant.outlined,
                fullWidth: true,
                onPressed: onGoHome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
