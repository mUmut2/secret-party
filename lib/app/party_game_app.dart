import 'package:flutter/material.dart';

import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import 'app_viewport.dart';
import 'session_guard.dart';

/// Uygulamanın kök widget'ı.
class PartyGameApp extends StatelessWidget {
  const PartyGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SessionGuard(
      router: AppRouter.router,
      child: MaterialApp.router(
        title: 'Secret Party',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: AppRouter.router,
        builder: (context, child) =>
            AppViewport(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
