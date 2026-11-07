import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/models/werewolf/werewolf_role.dart';

/// Rollerin görsel kimliği (ikon + renk).
///
/// Domain katmanı saf Dart kaldığı için görsel tanımlar burada, sunum
/// katmanındadır. Renk tek başına anlam taşımaz: her yerde rol adı da yazar.
extension WerewolfRoleStyle on WerewolfRole {
  IconData get icon {
    switch (this) {
      case WerewolfRole.vampir:
        return Icons.bloodtype;
      case WerewolfRole.koylu:
        return Icons.cottage;
      case WerewolfRole.doktor:
        return Icons.medical_services;
      case WerewolfRole.cadi:
        return Icons.auto_fix_high;
      case WerewolfRole.kahin:
        return Icons.visibility;
      case WerewolfRole.avci:
        return Icons.gps_fixed;
    }
  }

  Color get color {
    switch (this) {
      case WerewolfRole.vampir:
        return AppColors.error;
      case WerewolfRole.koylu:
        return AppColors.primary;
      case WerewolfRole.doktor:
        return AppColors.success;
      case WerewolfRole.cadi:
        return AppColors.nightAccent;
      case WerewolfRole.kahin:
        return AppColors.tertiary;
      case WerewolfRole.avci:
        return AppColors.warning;
    }
  }
}

extension WerewolfTeamStyle on WerewolfTeam {
  Color get color =>
      this == WerewolfTeam.vampires ? AppColors.error : AppColors.primary;

  IconData get icon =>
      this == WerewolfTeam.vampires ? Icons.bloodtype : Icons.cottage;
}
