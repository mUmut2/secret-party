import 'dart:math' as math;

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
import '../../../domain/models/player.dart';
import '../../../domain/services/game_engine_notifier.dart';
import '../viewmodels/round_notifier.dart';
import '../viewmodels/round_state.dart';
import '../widgets/imposter_exit.dart';

// --- Sayaç halkası ---
const double _ringMaxSize = 260;
const double _ringStrokeWidth = 10;
const double _ringGlowBlur = 12;
const double _ringGlowAlpha = 0.45;
const double _ringTextPadding = AppSpacing.xl;
const Duration _ringProgressTween = Duration(seconds: 1);

// --- Kalp atışı (son 10 saniye) ---
const Duration _heartbeatDuration = Duration(milliseconds: 650);
const double _heartbeatBaseGlowBlur = 12;
const double _heartbeatPeakGlowBlur = 36;
const double _normalGlowAlpha = 0.35;
const double _heartbeatGlowAlpha = 0.8;

// --- Süre bitti flaşı ---
const Duration _flashDuration = Duration(milliseconds: 900);
const double _flashPeakOpacity = 0.85;
const double _flashEchoOpacity = 0.5;
const double _shakeAmplitude = 14;
const double _shakeCycles = 6;

const double _entryScaleStart = 0.6;

/// "Lub-dub" kalp atışı: önce güçlü, hemen ardından daha zayıf ikinci vuruş,
/// sonra dinlenme. Saniyenin tamamına yayılmaz; ritim net hissedilsin diye
/// vuruşlar saniyenin ilk yarısında toplanır.
final TweenSequence<double> _heartbeatScale = TweenSequence<double>([
  TweenSequenceItem(
    tween:
        Tween(begin: 1.0, end: 1.18).chain(CurveTween(curve: Curves.easeOut)),
    weight: 15,
  ),
  TweenSequenceItem(
    tween: Tween(begin: 1.18, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
    weight: 15,
  ),
  TweenSequenceItem(
    tween:
        Tween(begin: 1.0, end: 1.08).chain(CurveTween(curve: Curves.easeOut)),
    weight: 12,
  ),
  TweenSequenceItem(
    tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
    weight: 28,
  ),
  TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
]);

/// Süre bitti flaşının opaklık eğrisi: sert parlama, sönme, daha zayıf bir
/// yankı ve kehribar zemine yerleşme.
final TweenSequence<double> _flashOpacity = TweenSequence<double>([
  TweenSequenceItem(
    tween: Tween<double>(begin: 0, end: _flashPeakOpacity),
    weight: 8,
  ),
  TweenSequenceItem(
    tween: Tween<double>(begin: _flashPeakOpacity, end: 0),
    weight: 22,
  ),
  TweenSequenceItem(
    tween: Tween<double>(begin: 0, end: _flashEchoOpacity),
    weight: 8,
  ),
  TweenSequenceItem(
    tween: Tween<double>(begin: _flashEchoOpacity, end: 0)
        .chain(CurveTween(curve: Curves.easeOut)),
    weight: 62,
  ),
]);

/// Oyun turu ekranı: geri sayım + ipucu aşaması.
///
/// - Normal: lime halka ve sayaç, hafif neon parlama.
/// - Son 10 saniye: kırmızı sayaç, her saniye "lub-dub" kalp atışı + parlama,
///   "SON 10 SANİYE" uyarısı (titreşim `RoundNotifier`'da).
/// - Süre bitti: beyaz flaş + yankı, başlık sarsıntısı ve kehribar zemin
///   (titreşim `RoundNotifier`'da).
///
/// Renk tek başına anlam taşımaz: rakam, animasyon ve açık metin de vardır.
/// Cihazda "animasyonları azalt" açıksa flaş ve sarsıntı oynatılmaz.
class RoundScreen extends ConsumerStatefulWidget {
  const RoundScreen({super.key});

  @override
  ConsumerState<RoundScreen> createState() => _RoundScreenState();
}

class _RoundScreenState extends ConsumerState<RoundScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashController = AnimationController(
    vsync: this,
    duration: _flashDuration,
  );

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  void _onRoundChanged(RoundState? previous, RoundState next) {
    final justTimedUp = previous?.status != RoundStatus.timeUp &&
        next.status == RoundStatus.timeUp;
    if (justTimedUp && !_reduceMotion) {
      _flashController.forward(from: 0);
    }
  }

  void _goToVoting() {
    ref.read(gameSessionProvider.notifier).beginVoting();
    context.go(AppRouter.voting);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RoundState>(roundProvider, _onRoundChanged);

    final session = ref.watch(gameSessionProvider);
    final round = ref.watch(roundProvider);

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

    // Geri tuşuyla turdan yanlışlıkla çıkılmasını engeller.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) requestImposterExit(context, ref);
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedContainer(
              duration: AppMotion.slow,
              curve: AppMotion.standardCurve,
              color:
                  round.isFinished ? AppColors.warning : AppColors.background,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: AnimatedSwitcher(
                    duration: AppMotion.base,
                    child: round.isFinished
                        ? _FinishedContent(
                            key: const ValueKey('finished'),
                            title: round.status == RoundStatus.timeUp
                                ? 'SÜRE BİTTİ!'
                                : 'TUR BİTTİ!',
                            shake: _flashController,
                            onContinue: _goToVoting,
                          )
                        : _ActiveContent(
                            key: const ValueKey('active'),
                            round: round,
                            players: session.players,
                            onSkip: () =>
                                ref.read(roundProvider.notifier).endEarly(),
                          ),
                  ),
                ),
              ),
            ),
            // Flaş katmanı dokunuşları engellemez; sadece görseldir.
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _flashController,
                builder: (context, _) {
                  final opacity = _flashController.isAnimating
                      ? _flashOpacity.transform(_flashController.value)
                      : 0.0;
                  if (opacity <= 0) return const SizedBox.shrink();
                  return ColoredBox(
                    color: AppColors.textPrimary.withValues(alpha: opacity),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _timerColor(RoundState round) =>
    round.isFinalCountdown ? AppColors.error : AppColors.primary;

String _formatTime(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _ActiveContent extends StatelessWidget {
  const _ActiveContent({
    super.key,
    required this.round,
    required this.players,
    required this.onSkip,
  });

  final RoundState round;
  final List<Player> players;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Kalan Süre',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.m),
        Flexible(
          flex: 3,
          child: Center(child: _CountdownRing(round: round)),
        ),
        const SizedBox(height: AppSpacing.s),
        _FinalCountdownBanner(visible: round.isFinalCountdown),
        const SizedBox(height: AppSpacing.s),
        const Text(
          'Sırayla birer ipucu verin. Gizli kelimeyi doğrudan söylemek yasak.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.l),
        const Text('Oyuncular', style: AppTypography.title),
        const SizedBox(height: AppSpacing.m),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                for (final player in players) _PlayerChip(name: player.name),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        AppButton(
          label: 'Oylamaya Geç',
          variant: ButtonVariant.secondary,
          fullWidth: true,
          onPressed: onSkip,
        ),
      ],
    );
  }
}

/// Dairesel ilerleme halkası ve ortasında kalp atışlı sayaç.
///
/// Halka saniyelik sıçramalar yerine 1 saniyelik doğrusal tween ile akar;
/// renk lime → kırmızı geçişini yumuşakça yapar.
class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.round});

  final RoundState round;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = [
          constraints.maxWidth,
          constraints.maxHeight,
          _ringMaxSize,
        ].reduce(math.min);

        return SizedBox.square(
          dimension: size,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: _timerColor(round)),
            duration: AppMotion.slow,
            curve: AppMotion.standardCurve,
            builder: (context, color, _) {
              final ringColor = color ?? _timerColor(round);
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(end: round.progress),
                duration: _ringProgressTween,
                curve: Curves.linear,
                builder: (context, progress, child) => CustomPaint(
                  painter: _RingPainter(
                    progress: progress,
                    color: ringColor,
                    trackColor: AppColors.surface,
                  ),
                  child: child,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_ringTextPadding),
                  child: Center(
                    child: _HeartbeatTimerText(
                      round: round,
                      color: ringColor,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - _ringStrokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStrokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweep <= 0) return;

    const startAngle = -math.pi / 2;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: _ringGlowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStrokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _ringGlowBlur);
    canvas.drawArc(rect, startAngle, sweep, false, glowPaint);

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringStrokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweep, false, arcPaint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}

/// Sayaç metni. Son 10 saniyede her saniye baştan oynayan bir "lub-dub"
/// kalp atışıyla büyür ve kırmızı neon parlaması güçlenir.
class _HeartbeatTimerText extends StatelessWidget {
  const _HeartbeatTimerText({required this.round, required this.color});

  final RoundState round;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    Widget buildText(double beat) {
      // beat: 1.0 = dinlenme, > 1.0 = vuruş anı.
      final intensity = ((beat - 1.0) / 0.18).clamp(0.0, 1.0);
      final glowAlpha = round.isFinalCountdown
          ? _normalGlowAlpha +
              (_heartbeatGlowAlpha - _normalGlowAlpha) * intensity
          : _normalGlowAlpha;
      final glowBlur = _heartbeatBaseGlowBlur +
          (_heartbeatPeakGlowBlur - _heartbeatBaseGlowBlur) * intensity;

      return Transform.scale(
        scale: beat,
        child: Text(
          _formatTime(round.remainingSeconds),
          style: AppTypography.timerDisplay.copyWith(
            color: color,
            shadows: [
              Shadow(
                color: AppShadows.glow(color, glowAlpha),
                blurRadius: glowBlur,
              ),
            ],
          ),
        ),
      );
    }

    final Widget content = round.isFinalCountdown && !reduceMotion
        ? TweenAnimationBuilder<double>(
            // `key` her saniye değiştiği için kalp atışı her saniye baştan oynar.
            key: ValueKey(round.remainingSeconds),
            tween: Tween(begin: 0, end: 1),
            duration: _heartbeatDuration,
            builder: (context, t, _) => buildText(_heartbeatScale.transform(t)),
          )
        : buildText(1.0);

    return Semantics(
      label: 'Kalan süre: ${round.remainingSeconds ~/ 60} dakika '
          '${round.remainingSeconds % 60} saniye',
      liveRegion: round.isFinalCountdown,
      excludeSemantics: true,
      // Küçük ekranlarda sayaç halkaya sığsın diye otomatik küçülür.
      child: FittedBox(fit: BoxFit.scaleDown, child: content),
    );
  }
}

/// Son 10 saniyede beliren "SON 10 SANİYE!" uyarısı. Yeri her zaman
/// ayrılmıştır; belirdiğinde düzen kaymaz.
class _FinalCountdownBanner extends StatelessWidget {
  const _FinalCountdownBanner({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: AppMotion.base,
      curve: AppMotion.standardCurve,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.3),
        duration: AppMotion.base,
        curve: AppMotion.standardCurve,
        child: Text(
          'SON ${RoundState.finalCountdownSeconds} SANİYE!',
          textAlign: TextAlign.center,
          style: AppTypography.label.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(name, style: AppTypography.bodyLarge),
    );
  }
}

class _FinishedContent extends StatelessWidget {
  const _FinishedContent({
    super.key,
    required this.title,
    required this.shake,
    required this.onContinue,
  });

  final String title;

  /// Süre bitti flaşıyla aynı controller: başlık flaşla senkron sarsılır.
  /// Tur erken bitirildiyse controller hiç çalışmaz, sarsıntı olmaz.
  final Animation<double> shake;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: AnimatedBuilder(
              animation: shake,
              builder: (context, child) {
                final t = shake.value;
                // Sönümlenen yatay sarsıntı: başta güçlü, sona doğru durulur.
                final dx = shake.status == AnimationStatus.forward
                    ? math.sin(t * math.pi * 2 * _shakeCycles) *
                        _shakeAmplitude *
                        (1 - t)
                    : 0.0;
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: _entryScaleStart, end: 1.0),
                duration: AppMotion.resolve(context, AppMotion.dramatic),
                curve: AppMotion.dramaticCurve,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.alarm,
                      size: AppSpacing.xxl,
                      color: AppColors.onPrimary,
                      semanticLabel: 'Süre uyarısı',
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTypography.gameDisplay.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'Şimdi oylama zamanı. Imposter kim?',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AppButton(
          label: 'Oylamaya Geç',
          variant: ButtonVariant.secondary,
          fullWidth: true,
          onPressed: onContinue,
        ),
      ],
    );
  }
}
