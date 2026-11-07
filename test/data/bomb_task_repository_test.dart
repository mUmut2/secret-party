import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/core/utils/turkish_text.dart';
import 'package:party_game/data/repositories/bomb_task_repository.dart';

/// Tik Tak Bomba görev havuzunun içerik kuralları.
void main() {
  const repository = LocalBombTaskRepository();
  final categories = repository.categoryNames.keys.toList();
  final all = repository.tasks();

  String normalize(String text) => text.toLowerTr().trim();

  test('en az 10 kategori, her birinde en az 20 görev, toplam en az 200', () {
    expect(categories.length, greaterThanOrEqualTo(10));
    for (final id in categories) {
      expect(
        repository.tasks(categoryId: id).length,
        greaterThanOrEqualTo(20),
        reason: id,
      );
    }
    expect(all.length, greaterThanOrEqualTo(200));
  });

  test('görev boş değil, kırpılmış ve "söyle" ile biten bir istek', () {
    for (final task in all) {
      expect(task.prompt, isNotEmpty);
      expect(task.prompt, task.prompt.trim());
      expect(task.prompt, endsWith('söyle'), reason: task.prompt);
    }
  });

  test('aynı görev iki kez geçmiyor', () {
    final seen = <String>{};
    final duplicates = [
      for (final task in all)
        if (!seen.add(normalize(task.prompt))) task.prompt,
    ];
    expect(duplicates, isEmpty);
  });

  test('her kategorinin ekranda gösterilen bir adı var', () {
    for (final id in categories) {
      expect(repository.categoryNames[id], isNotEmpty);
    }
    expect(repository.tasks(categoryId: 'yok'), isEmpty);
  });

  test('aile dostu: yasaklı çağrışımlar yok', () {
    const banned = [
      'alkol',
      'bira',
      'rakı',
      'şarap',
      'sigara',
      'silah',
      'tabanca',
      'kumar',
      'bahis',
      'öldür',
      'savaş',
      'siyas',
      'seçim',
      'cami',
      'kilise',
      'dini',
      'seks',
      'kan ',
      'ölüm',
      'uyuşturucu',
    ];
    for (final task in all) {
      final text = normalize(task.prompt);
      for (final word in banned) {
        expect(text.contains(word), isFalse, reason: '${task.prompt} ($word)');
      }
    }
  });
}
