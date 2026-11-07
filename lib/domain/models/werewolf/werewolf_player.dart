import '../player.dart';
import 'werewolf_role.dart';

/// Vampir Köylü oyunundaki bir oyuncu: ortak [Player]'ı rol ve hayatta kalma
/// bilgisiyle sarmalar.
///
/// [isProtectedByDoctor] ve [isTargetedByVampires] yalnızca İÇİNDE
/// bulunulan gecenin işaretleridir; her yeni gecenin başında sıfırlanır.
class WerewolfPlayer {
  const WerewolfPlayer({
    required this.player,
    required this.role,
    this.isAlive = true,
    this.isProtectedByDoctor = false,
    this.isTargetedByVampires = false,
  });

  final Player player;
  final WerewolfRole role;
  final bool isAlive;
  final bool isProtectedByDoctor;
  final bool isTargetedByVampires;

  String get id => player.id;
  String get name => player.name;

  bool get isVampire => role.isVampire;

  WerewolfPlayer copyWith({
    bool? isAlive,
    bool? isProtectedByDoctor,
    bool? isTargetedByVampires,
  }) {
    return WerewolfPlayer(
      player: player,
      role: role,
      isAlive: isAlive ?? this.isAlive,
      isProtectedByDoctor: isProtectedByDoctor ?? this.isProtectedByDoctor,
      isTargetedByVampires: isTargetedByVampires ?? this.isTargetedByVampires,
    );
  }
}
