import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/core/services/haptic_service.dart';
import 'package:party_game/core/theme/app_theme.dart';
import 'package:party_game/data/repositories/local_storage_repository.dart';
import 'package:party_game/domain/models/game_session.dart';
import 'package:party_game/domain/models/player.dart';
import 'package:party_game/domain/services/game_engine_notifier.dart';
import 'package:party_game/features/imposter/viewmodels/role_reveal_notifier.dart';
import 'package:party_game/features/imposter/viewmodels/round_notifier.dart';
import 'package:party_game/features/imposter/views/role_reveal_screen.dart';
import 'package:party_game/features/imposter/views/round_screen.dart';
import 'package:party_game/features/imposter/views/voting_screen.dart';
import 'package:party_game/features/results/views/result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// GÜVENLİK: Imposter ipucu YALNIZCA Imposter'ın rol kartında (ve oyun
/// bittikten sonra sonuç ekranında) görünür. Normal oyuncu kartı, "telefonu
/// ver" ekranı, tur, oylama, geri tuşu ve arka plana alma durumlarında
/// görünmez.
void main() {
  const hint = 'atlıkarınca';

  final players = [
    for (final name in ['Ali', 'Ayşe', 'Can', 'Ece'])
      Player(id: name, name: name),
  ];

  /// Ali Imposter; ipucu açık.
  GameSession session({
    GameState status = GameState.roleReveal,
    String? imposterHint = hint,
  }) =>
      GameSession(
        id: 'gizlilik',
        players: players,
        secretWord: 'Lunapark',
        imposterId: 'Ali',
        category: 'mekanlar',
        status: status,
        roundDurationSeconds: 60,
        giveImposterHint: imposterHint != null,
        imposterHint: imposterHint,
      );

  /// İpucu ekranda (herhangi bir yazımla) görünüyor mu?
  Finder hintText() => find.textContaining('tlıkarınca');

  void expectHintHidden() {
    expect(hintText(), findsNothing);
    expect(find.text('İPUCUN'), findsNothing);
  }

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget screen,
    GameSession initial,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        hapticServiceProvider.overrideWithValue(
          const HapticService(enabled: false),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(gameSessionProvider.notifier).state = initial;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.dark, home: screen),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
      'ipucu yalnızca Imposter kartında; "telefonu ver" ekranında ve '
      'normal oyuncu kartında görünmez', (tester) async {
    final c = await pump(tester, const RoleRevealScreen(), session());
    final reveal = c.read(roleRevealProvider.notifier);

    // "Telefonu Ali'ye ver" ekranı: ipucu yok.
    expect(find.textContaining('Ali'), findsWidgets);
    expectHintHidden();

    // Ali (Imposter) kartını açar: ipucu görünür.
    reveal.revealCurrentPlayer();
    await tester.pumpAndSettle();
    expect(find.text("SEN IMPOSTER'SIN"), findsOneWidget);
    expect(find.text('İPUCUN'), findsOneWidget);
    expect(find.text('Atlıkarınca'), findsOneWidget);

    // Gizle → sıradaki oyuncunun "telefonu ver" ekranı: ipucu yok.
    reveal.hideAndAdvance(totalPlayers: players.length);
    await tester.pumpAndSettle();
    expectHintHidden();

    // Ayşe (normal oyuncu) kartı: kelime var, ipucu yok.
    reveal.revealCurrentPlayer();
    await tester.pumpAndSettle();
    expect(find.textContaining('Lunapark'), findsOneWidget);
    expectHintHidden();
  });

  testWidgets('uygulama arka plana alınınca açık Imposter kartı kapanır',
      (tester) async {
    final c = await pump(tester, const RoleRevealScreen(), session());
    c.read(roleRevealProvider.notifier).revealCurrentPlayer();
    await tester.pumpAndSettle();
    expect(find.text('Atlıkarınca'), findsOneWidget);

    // Uygulama değiştirici / gelen çağrı / bildirim paneli.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expectHintHidden();
    expect(c.read(roleRevealProvider).isRevealed, isFalse);
    // Sıra Imposter'da kalır; kartını yeniden açabilir.
    expect(c.read(roleRevealProvider).currentPlayerIndex, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expectHintHidden();
  });

  testWidgets('geri tuşu: çıkış onayı açılmadan önce Imposter kartı kapanır',
      (tester) async {
    final c = await pump(tester, const RoleRevealScreen(), session());
    c.read(roleRevealProvider.notifier).revealCurrentPlayer();
    await tester.pumpAndSettle();
    expect(find.text('Atlıkarınca'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Oyundan Çık'), findsOneWidget);
    expectHintHidden();
    expect(c.read(roleRevealProvider).isRevealed, isFalse);
  });

  testWidgets('tur ekranında ipucu görünmez', (tester) async {
    final c = await pump(
      tester,
      const RoundScreen(),
      session(status: GameState.playing),
    );
    c.read(roundProvider.notifier).start(durationSeconds: 60);
    await tester.pump(const Duration(milliseconds: 500));
    expectHintHidden();
    c.read(roundProvider.notifier).stop();
    await tester.pumpAndSettle();
    expectHintHidden();
  });

  testWidgets('oylama ekranında ipucu görünmez', (tester) async {
    await pump(tester, const VotingScreen(), session(status: GameState.voting));
    expectHintHidden();
  });

  group('sonuç ekranı', () {
    GameSession finished({String? imposterHint}) => session(
          status: GameState.finished,
          imposterHint: imposterHint,
        ).copyWith(accusedPlayerId: 'Ali', result: GameResult.innocentsWon);

    testWidgets('ipucu kullanıldıysa satır görünür', (tester) async {
      await pump(tester, const ResultScreen(), finished(imposterHint: hint));
      expect(
        find.text("Imposter'a verilen ipucu: Atlıkarınca"),
        findsOneWidget,
      );
    });

    testWidgets('ipucu kullanılmadıysa satır hiç görünmez', (tester) async {
      await pump(tester, const ResultScreen(), finished());
      expect(find.textContaining('verilen ipucu'), findsNothing);
      expectHintHidden();
    });
  });
}
