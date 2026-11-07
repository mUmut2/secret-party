import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/routing/app_router.dart';
import '../core/services/wakelock_service.dart';
import '../domain/services/game_engine_notifier.dart';
import '../features/bomb/viewmodels/bomb_game_notifier.dart';
import '../features/imposter/viewmodels/round_notifier.dart';
import '../features/spy/viewmodels/spy_game_notifier.dart';
import '../features/spy/viewmodels/spy_timer_notifier.dart';
import '../features/taboo/viewmodels/taboo_game_notifier.dart';
import '../features/werewolf/viewmodels/werewolf_game_notifier.dart';

/// Rota değişikliklerini izleyip oyun oturumlarının "yaşam döngüsünü"
/// yöneten görünmez katman.
///
/// - OYUN ekranına girilince ekran açık tutulur (wakelock): telefon elden
///   ele gezerken ya da sayaç işlerken ekran kararmaz.
/// - ANA MENÜ ekranlarına (ana sayfa, oyun seçimi, ayarlar) dönülünce ekran
///   bırakılır ve TÜM oyun oturumları kapatılır: çalışan sayaçlar durur,
///   bir sonraki oyun temiz bir durumla başlar. Böylece arka planda unutulan
///   bir sayacın ana menüde titreşim vermesi gibi sızıntılar önlenir.
/// - Kurulum ekranlarında ekran normal zaman aşımına bırakılır; ayarlar ve
///   oyuncu listeleri korunur.
class SessionGuard extends ConsumerStatefulWidget {
  const SessionGuard({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  /// Ekranın açık tutulacağı oyun rotaları.
  static const Set<String> gameRoutes = {
    AppRouter.roleReveal,
    AppRouter.round,
    AppRouter.voting,
    AppRouter.result,
    AppRouter.tabooGame,
    AppRouter.tabooResult,
    AppRouter.werewolfReveal,
    AppRouter.werewolfNight,
    AppRouter.werewolfDay,
    AppRouter.werewolfVoting,
    AppRouter.werewolfResult,
    AppRouter.spyReveal,
    AppRouter.spyGame,
    AppRouter.spyGuess,
    AppRouter.spyVote,
    AppRouter.spyResult,
    AppRouter.bombReady,
    AppRouter.bombPlay,
    AppRouter.bombExplosion,
    AppRouter.bombFinal,
  };

  /// Dönüldüğünde tüm oyun oturumlarının kapatıldığı menü rotaları.
  static const Set<String> hubRoutes = {
    AppRouter.home,
    AppRouter.gameSelection,
    AppRouter.settings,
    AppRouter.privacyPolicy,
  };

  @override
  ConsumerState<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends ConsumerState<SessionGuard> {
  String? _lastPath;

  /// `dispose` içinde `ref` kullanılamadığı için `initState`'te önbelleğe
  /// alınır.
  late final WakelockService _wakelock;

  @override
  void initState() {
    super.initState();
    _wakelock = ref.read(wakelockServiceProvider);
    widget.router.routerDelegate.addListener(_onRouteChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onRouteChanged());
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouteChanged);
    _wakelock.setEnabled(false);
    super.dispose();
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final path = widget.router.routerDelegate.currentConfiguration.uri.path;
    if (path == _lastPath) return;
    _lastPath = path;

    final inGame = SessionGuard.gameRoutes.contains(path);
    _wakelock.setEnabled(inGame);

    if (SessionGuard.hubRoutes.contains(path)) {
      // Rota değişikliği bir build sırasında bildirilebilir; provider
      // güncellemeleri kare bittikten sonra yapılır.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resetAllGameSessions();
      });
    }
  }

  void _resetAllGameSessions() {
    // Imposter: önce sayaç, sonra oturum (oturuma bağlı akışlar sıfırlanır).
    if (ref.read(gameSessionProvider) != null) {
      ref.read(roundProvider.notifier).stop();
      ref.read(gameSessionProvider.notifier).endSession();
    }
    if (ref.read(tabooGameProvider) != null) {
      ref.read(tabooGameProvider.notifier).quit();
    }
    if (ref.read(werewolfGameProvider) != null) {
      ref.read(werewolfGameProvider.notifier).quit();
    }
    if (ref.read(spyGameProvider) != null) {
      ref.read(spyTimerProvider.notifier).stop();
      ref.read(spyGameProvider.notifier).quit();
    }
    if (ref.read(bombGameProvider) != null) {
      // Fitil (sayaç) da oyunla birlikte durur.
      ref.read(bombGameProvider.notifier).quit();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
