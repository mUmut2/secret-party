import '../player.dart';

/// Ajan oyunundaki bir oyuncu: ortak [Player]'ı rol bilgisiyle sarmalar.
///
/// Ajanın rolü yoktur ([roleName] `null`); masumlar konumdaki benzersiz bir
/// rol alır.
class SpyPlayer {
  const SpyPlayer({
    required this.player,
    required this.isSpy,
    this.roleName,
  });

  final Player player;
  final bool isSpy;

  /// Konumdaki rol (ajan için `null`).
  final String? roleName;

  String get id => player.id;
  String get name => player.name;
}
