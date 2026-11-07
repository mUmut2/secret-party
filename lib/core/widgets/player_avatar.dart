import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';

/// Avatarın oyun içi görsel durumu.
///
/// [imposter] durumu tek başına renkle anlam taşımamalı; kullanıldığı
/// ekranda yanında açık bir "Imposter" etiketi de gösterilmelidir.
enum AvatarState { default_, selected, imposter }

const double _defaultAvatarSize = 56;
const double _stateBorderWidth = 2;

/// Uygulamadaki TEK oyuncu avatarı bileşeni (isim baş harfi gösterir).
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.name,
    this.state = AvatarState.default_,
    this.size = _defaultAvatarSize,
  });

  final String name;
  final AvatarState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final _AvatarStyleSpec spec = _resolveStyle(state);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        shape: BoxShape.circle,
        border: spec.border,
        boxShadow: spec.shadow,
      ),
      child: Text(
        _initialOf(name),
        style: AppTypography.title.copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  String _initialOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    // Türkçe i/ı için doğru büyük harf.
    final first = trimmed[0];
    if (first == 'i') return 'İ';
    if (first == 'ı') return 'I';
    return first.toUpperCase();
  }

  _AvatarStyleSpec _resolveStyle(AvatarState state) {
    switch (state) {
      case AvatarState.default_:
        return const _AvatarStyleSpec(border: null, shadow: null);
      case AvatarState.selected:
        return _AvatarStyleSpec(
          border: Border.all(
            color: AppColors.primary,
            width: _stateBorderWidth,
          ),
          shadow: AppShadows.glowPrimary,
        );
      case AvatarState.imposter:
        return _AvatarStyleSpec(
          border: Border.all(
            color: AppColors.error,
            width: _stateBorderWidth,
          ),
          shadow: AppShadows.glowError,
        );
    }
  }
}

class _AvatarStyleSpec {
  const _AvatarStyleSpec({required this.border, required this.shadow});

  final Border? border;
  final List<BoxShadow>? shadow;
}
