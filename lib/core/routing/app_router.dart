import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/bomb/views/bomb_explosion_screen.dart';
import '../../features/bomb/views/bomb_final_screen.dart';
import '../../features/bomb/views/bomb_play_screen.dart';
import '../../features/bomb/views/bomb_ready_screen.dart';
import '../../features/bomb/views/bomb_setup_screen.dart';
import '../../features/game_selection/views/game_selection_screen.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/imposter/views/role_reveal_screen.dart';
import '../../features/imposter/views/round_screen.dart';
import '../../features/imposter/views/voting_screen.dart';
import '../../features/players/views/player_setup_screen.dart';
import '../../features/results/views/result_screen.dart';
import '../../features/settings/views/privacy_policy_screen.dart';
import '../../features/settings/views/settings_screen.dart';
import '../../features/spy/views/spy_game_screen.dart';
import '../../features/spy/views/spy_location_guess_screen.dart';
import '../../features/spy/views/spy_result_screen.dart';
import '../../features/spy/views/spy_role_reveal_screen.dart';
import '../../features/spy/views/spy_setup_screen.dart';
import '../../features/spy/views/spy_voting_screen.dart';
import '../../features/taboo/views/taboo_game_screen.dart';
import '../../features/taboo/views/taboo_result_screen.dart';
import '../../features/taboo/views/taboo_setup_screen.dart';
import '../../features/werewolf/views/werewolf_day_screen.dart';
import '../../features/werewolf/views/werewolf_night_screen.dart';
import '../../features/werewolf/views/werewolf_result_screen.dart';
import '../../features/werewolf/views/werewolf_role_reveal_screen.dart';
import '../../features/werewolf/views/werewolf_setup_screen.dart';
import '../../features/werewolf/views/werewolf_voting_screen.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_back_guard.dart';
import '../widgets/app_button.dart';
import 'app_page_transitions.dart';

/// Uygulamanın TÜM rota tanımlarının tek merkezi kaynağı.
///
/// Rotalar arasında veri taşınmaz (`extra` kullanılmaz). Oyuncular, oylama
/// seçimi ve sonuç `gameSessionProvider` / `votingProvider` üzerinden okunur.
/// Tabu modülü aynı şekilde `tabooSetupProvider` / `tabooGameProvider`,
/// Vampir Köylü modülü `werewolfSetupProvider` / `werewolfGameProvider`,
/// Ajan modülü `spySetupProvider` / `spyGameProvider`, Tik Tak Bomba
/// `bombSetupProvider` / `bombGameProvider` okur.
///
/// Her rota `pageBuilder` + [buildTransitionPage] ile kendi anlamına uygun
/// Neon Ink geçişini kullanır (bkz. [AppPageTransition]).
class AppRouter {
  AppRouter._();

  static const String home = '/';
  static const String gameSelection = '/game-selection';
  static const String playerSetup = '/player-setup';
  static const String roleReveal = '/role-reveal';
  static const String round = '/round';
  static const String voting = '/voting';
  static const String result = '/result';

  // --- Uygulama ---
  static const String settings = '/settings';
  static const String privacyPolicy = '/settings/privacy';

  // --- Tabu ---
  static const String tabooSetup = '/taboo/setup';
  static const String tabooGame = '/taboo/game';
  static const String tabooResult = '/taboo/result';

  // --- Vampir Köylü ---
  static const String werewolfSetup = '/werewolf/setup';
  static const String werewolfReveal = '/werewolf/reveal';
  static const String werewolfNight = '/werewolf/night';
  static const String werewolfDay = '/werewolf/day';
  static const String werewolfVoting = '/werewolf/voting';
  static const String werewolfResult = '/werewolf/result';

  // --- Tik Tak Bomba ---
  static const String bombSetup = '/bomb/setup';
  static const String bombReady = '/bomb/ready';
  static const String bombPlay = '/bomb/play';
  static const String bombExplosion = '/bomb/explosion';
  static const String bombFinal = '/bomb/final';

  // --- Ajan (Spyfall) ---
  static const String spySetup = '/spy/setup';
  static const String spyReveal = '/spy/reveal';
  static const String spyGame = '/spy/game';
  static const String spyGuess = '/spy/guess';
  static const String spyVote = '/spy/vote';
  static const String spyResult = '/spy/result';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: kDebugMode,
    errorPageBuilder: (context, state) => buildTransitionPage(
      state: state,
      transition: AppPageTransition.fade,
      child: const _NotFoundScreen(),
    ),
    routes: [
      GoRoute(
        path: home,
        name: 'home',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.fade,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: settings,
        name: 'settings',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.fadeUp,
          child: const AppBackGuard(
            fallbackRoute: home,
            child: SettingsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: privacyPolicy,
        name: 'privacyPolicy',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.fadeUp,
          child: const AppBackGuard(
            fallbackRoute: settings,
            child: PrivacyPolicyScreen(),
          ),
        ),
      ),
      GoRoute(
        path: gameSelection,
        name: 'gameSelection',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.fade,
          child: const AppBackGuard(
            fallbackRoute: home,
            child: GameSelectionScreen(),
          ),
        ),
      ),
      GoRoute(
        path: playerSetup,
        name: 'playerSetup',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.fadeUp,
          child: const AppBackGuard(
            fallbackRoute: gameSelection,
            child: PlayerSetupScreen(),
          ),
        ),
      ),
      GoRoute(
        path: roleReveal,
        name: 'roleReveal',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.tensionScale,
          child: const RoleRevealScreen(),
        ),
      ),
      GoRoute(
        path: round,
        name: 'round',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.slideForward,
          child: const RoundScreen(),
        ),
      ),
      GoRoute(
        path: voting,
        name: 'voting',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.rise,
          child: const VotingScreen(),
        ),
      ),
      GoRoute(
        path: result,
        name: 'result',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.dramatic,
          child: const ResultScreen(),
        ),
      ),
      GoRoute(
        path: tabooSetup,
        name: 'tabooSetup',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.fadeUp,
          child: const AppBackGuard(
            fallbackRoute: gameSelection,
            child: TabooSetupScreen(),
          ),
        ),
      ),
      GoRoute(
        path: tabooGame,
        name: 'tabooGame',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.tensionScale,
          child: const TabooGameScreen(),
        ),
      ),
      GoRoute(
        path: tabooResult,
        name: 'tabooResult',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.dramatic,
          child: const TabooResultScreen(),
        ),
      ),
      GoRoute(
        path: werewolfSetup,
        name: 'werewolfSetup',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.fadeUp,
          child: const AppBackGuard(
            fallbackRoute: gameSelection,
            child: WerewolfSetupScreen(),
          ),
        ),
      ),
      GoRoute(
        path: werewolfReveal,
        name: 'werewolfReveal',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.tensionScale,
          child: const WerewolfRoleRevealScreen(),
        ),
      ),
      GoRoute(
        path: werewolfNight,
        name: 'werewolfNight',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.fade,
          child: const WerewolfNightScreen(),
        ),
      ),
      GoRoute(
        path: werewolfDay,
        name: 'werewolfDay',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.fadeUp,
          child: const WerewolfDayScreen(),
        ),
      ),
      GoRoute(
        path: werewolfVoting,
        name: 'werewolfVoting',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.rise,
          child: const WerewolfVotingScreen(),
        ),
      ),
      GoRoute(
        path: werewolfResult,
        name: 'werewolfResult',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.dramatic,
          child: const WerewolfResultScreen(),
        ),
      ),
      GoRoute(
        path: bombSetup,
        name: 'bombSetup',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.fadeUp,
          child: const AppBackGuard(
            fallbackRoute: gameSelection,
            child: BombSetupScreen(),
          ),
        ),
      ),
      GoRoute(
        path: bombReady,
        name: 'bombReady',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.fade,
          child: const BombReadyScreen(),
        ),
      ),
      GoRoute(
        path: bombPlay,
        name: 'bombPlay',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.tensionScale,
          child: const BombPlayScreen(),
        ),
      ),
      GoRoute(
        path: bombExplosion,
        name: 'bombExplosion',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.dramatic,
          child: const BombExplosionScreen(),
        ),
      ),
      GoRoute(
        path: bombFinal,
        name: 'bombFinal',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.dramatic,
          child: const BombFinalScreen(),
        ),
      ),
      GoRoute(
        path: spySetup,
        name: 'spySetup',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.fadeUp,
          child: const AppBackGuard(
            fallbackRoute: gameSelection,
            child: SpySetupScreen(),
          ),
        ),
      ),
      GoRoute(
        path: spyReveal,
        name: 'spyReveal',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.tensionScale,
          child: const SpyRoleRevealScreen(),
        ),
      ),
      GoRoute(
        path: spyGame,
        name: 'spyGame',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.slideForward,
          child: const SpyGameScreen(),
        ),
      ),
      GoRoute(
        path: spyGuess,
        name: 'spyGuess',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.rise,
          child: const SpyLocationGuessScreen(),
        ),
      ),
      GoRoute(
        path: spyVote,
        name: 'spyVote',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.rise,
          child: const SpyVotingScreen(),
        ),
      ),
      GoRoute(
        path: spyResult,
        name: 'spyResult',
        pageBuilder: (context, state) => buildTransitionPage(
          state: state,
          transition: AppPageTransition.dramatic,
          child: const SpyResultScreen(),
        ),
      ),
    ],
  );
}

/// Bilinmeyen bir adrese gidilirse gösterilen güvenli ekran.
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

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
                'Sayfa bulunamadı',
                textAlign: TextAlign.center,
                style: AppTypography.headline,
              ),
              const SizedBox(height: AppSpacing.s),
              const Text(
                'Aradığın ekran taşınmış ya da hiç var olmamış olabilir.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Ana Menüye Dön',
                variant: ButtonVariant.primary,
                fullWidth: true,
                onPressed: () => context.go(AppRouter.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
