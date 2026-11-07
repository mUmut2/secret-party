import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/taboo_card.dart';
import '../content/taboo/taboo_categories.dart';

/// Tabu kart içeriğine erişimin TEK soyutlaması.
///
/// Oyun motoru kartların nereden geldiğini (local / ileride JSON asset ya da
/// uzak sunucu) bilmez; sadece filtrelenmiş kart listesini ister.
abstract class TabooWordRepository {
  /// Kategori id → ekranda gösterilen Türkçe ad (gösterim sırasıyla).
  Map<String, String> get categoryNames;

  /// Filtreye uyan tüm kartlar.
  ///
  /// - [categoryIds] `null` ya da boşsa tüm kategoriler,
  /// - [difficulty] `null` ise tüm zorluklar dahil edilir.
  List<TabooCard> cards(
      {Set<String>? categoryIds, TabooDifficulty? difficulty});
}

/// Uygulama içi kart destesi: kartlar `lib/data/content/taboo/` altında
/// kategori başına dosyalarda, `'Hedef: y1, y2, y3, y4, y5'` satırları olarak
/// durur ve ilk kullanımda bir kez [TabooCard]'a çevrilir.
class LocalTabooWordRepository implements TabooWordRepository {
  const LocalTabooWordRepository();

  /// Tüm deste (ilk erişimde bir kez kurulur).
  static final List<TabooCard> _cards = List.unmodifiable(_buildCards());

  @override
  Map<String, String> get categoryNames => tabooCategoryNames;

  @override
  List<TabooCard> cards({
    Set<String>? categoryIds,
    TabooDifficulty? difficulty,
  }) {
    final filterByCategory = categoryIds != null && categoryIds.isNotEmpty;
    return _cards
        .where((card) =>
            (!filterByCategory || categoryIds.contains(card.categoryId)) &&
            (difficulty == null || card.difficulty == difficulty))
        .toList(growable: false);
  }

  static List<TabooCard> _buildCards() {
    final cards = <TabooCard>[];
    tabooDecks.forEach((categoryId, deck) {
      void addAll(List<String> lines, TabooDifficulty difficulty) {
        for (var i = 0; i < lines.length; i++) {
          cards.add(
            parseCardLine(
              lines[i],
              id: '${categoryId}_${difficulty.name}_$i',
              categoryId: categoryId,
              difficulty: difficulty,
            ),
          );
        }
      }

      addAll(deck.easy, TabooDifficulty.easy);
      addAll(deck.medium, TabooDifficulty.medium);
      addAll(deck.hard, TabooDifficulty.hard);
    });
    return cards;
  }

  /// `'Hedef: y1, y2, y3, y4, y5'` satırını karta çevirir. Biçim bozuksa
  /// [FormatException] fırlatır (içerik testleri bunu yakalar).
  static TabooCard parseCardLine(
    String line, {
    required String id,
    required String categoryId,
    required TabooDifficulty difficulty,
  }) {
    final separator = line.indexOf(':');
    if (separator <= 0) {
      throw FormatException('Tabu kartında ":" yok', line);
    }
    final target = line.substring(0, separator).trim();
    final forbidden = line
        .substring(separator + 1)
        .split(',')
        .map((word) => word.trim())
        .toList(growable: false);
    return TabooCard(
      id: id,
      targetWord: target,
      forbiddenWords: forbidden,
      categoryId: categoryId,
      difficulty: difficulty,
    );
  }
}

final tabooWordRepositoryProvider = Provider<TabooWordRepository>((ref) {
  return const LocalTabooWordRepository();
});
