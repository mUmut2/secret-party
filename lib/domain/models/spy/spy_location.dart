/// Ajan oyunundaki bir konum ve o konuma özel roller.
///
/// Ajan dışındaki her oyuncu konumu ve [roles] içinden kendisine düşen rolü
/// görür; ajan ise konumu bilmez.
class SpyLocation {
  const SpyLocation({required this.name, required this.roles});

  /// Konumun Türkçe adı, örn. "Korsan Gemisi". Konumu benzersiz tanımlar.
  final String name;

  /// Bu konumdaki roller, örn. ["Kaptan", "Tayfa", "Aşçı", ...].
  final List<String> roles;

  @override
  bool operator ==(Object other) => other is SpyLocation && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
