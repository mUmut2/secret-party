import 'package:flutter/material.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/turkish_text.dart';
import '../../../domain/models/taboo_match.dart';
import '../../../domain/models/taboo_team.dart';

const double _activeBorderWidth = 1.5;
const double _progressHeight = 4;
const double _scoreFontSizeLarge = 40;
const double _scoreFontSizeCompact = 28;

/// Takım vurgu rengi: A lime, B camgöbeği. Tabu ekranlarında takımlar her
/// yerde bu renklerle ayırt edilir (yanında her zaman takım adı da yazar).
Color tabooTeamColor(int teamIndex) =>
    teamIndex == 0 ? AppColors.primary : AppColors.tertiary;

/// İki takımın skorunu yan yana gösteren tablo.
///
/// Sırası gelen takım renkli çerçeve ve "SIRADA" rozetiyle vurgulanır;
/// [highlightIndex] verilirse (örn. kazanan) o takım vurgulanır. Altındaki
/// ince çubuk hedef skora ne kadar yaklaşıldığını gösterir.
class TabooScoreboard extends StatelessWidget {
  const TabooScoreboard({
    super.key,
    required this.match,
    this.compact = false,
    this.highlightIndex,
    this.badgeLabel = 'Sırada',
  });

  final TabooMatch match;
  final bool compact;
  final int? highlightIndex;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    final highlighted = highlightIndex ?? match.activeTeamIndex;
    return Row(
      children: [
        for (var i = 0; i < match.teams.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.s),
          Expanded(
            child: _TeamScoreTile(
              team: match.teams[i],
              color: tabooTeamColor(i),
              isHighlighted: i == highlighted,
              badgeLabel: badgeLabel,
              targetScore: match.settings.targetScore,
              compact: compact,
            ),
          ),
        ],
      ],
    );
  }
}

class _TeamScoreTile extends StatelessWidget {
  const _TeamScoreTile({
    required this.team,
    required this.color,
    required this.isHighlighted,
    required this.badgeLabel,
    required this.targetScore,
    required this.compact,
  });

  final TabooTeam team;
  final Color color;
  final bool isHighlighted;
  final String badgeLabel;
  final int targetScore;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = (team.score / targetScore).clamp(0.0, 1.0);

    return Semantics(
      label: '${team.name}: ${team.score} puan'
          '${isHighlighted ? ', $badgeLabel' : ''}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.standardCurve,
        padding: EdgeInsets.all(compact ? AppSpacing.s : AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(
            color: isHighlighted ? color : AppColors.divider,
            width: _activeBorderWidth,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppShadows.glow(color, 0.3),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    team.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(color: color),
                  ),
                ),
                if (isHighlighted && !compact) ...[
                  const SizedBox(width: AppSpacing.xs),
                  // Dar ekranlarda rozet kısalır; takım adı önceliklidir.
                  Flexible(
                    child: Text(
                      badgeLabel.toUpperTr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(color: color),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: compact ? AppSpacing.xs : AppSpacing.s),
            AnimatedSwitcher(
              duration: AppMotion.base,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Text(
                '${team.score}',
                key: ValueKey(team.score),
                style: AppTypography.display.copyWith(
                  fontSize:
                      compact ? _scoreFontSizeCompact : _scoreFontSizeLarge,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: AppSpacing.s),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: AppMotion.slow,
                  curve: AppMotion.standardCurve,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: _progressHeight,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
