import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/bomb/bomb_task.dart';
import '../content/bomb/bomb_tasks.dart';

/// Tik Tak Bomba görev içeriğine erişimin TEK soyutlaması.
abstract class BombTaskRepository {
  /// Kategori id → ekranda gösterilen Türkçe ad (gösterim sırasıyla).
  Map<String, String> get categoryNames;

  /// [categoryId] verilirse o kategorinin, `null` ise (Karışık) tüm
  /// kategorilerin görevleri. Bilinmeyen kategoride boş liste döner.
  List<BombTask> tasks({String? categoryId});
}

/// Görevleri `lib/data/content/bomb/bomb_tasks.dart` içinden okur.
class LocalBombTaskRepository implements BombTaskRepository {
  const LocalBombTaskRepository();

  @override
  Map<String, String> get categoryNames => bombCategoryNames;

  @override
  List<BombTask> tasks({String? categoryId}) {
    final ids =
        categoryId == null ? bombCategoryNames.keys : <String>[categoryId];
    return [
      for (final id in ids)
        for (final prompt in bombTasksByCategory[id] ?? const <String>[])
          BombTask(categoryId: id, prompt: prompt),
    ];
  }
}

final bombTaskRepositoryProvider = Provider<BombTaskRepository>((ref) {
  return const LocalBombTaskRepository();
});
