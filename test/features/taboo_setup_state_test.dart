import 'package:flutter_test/flutter_test.dart';
import 'package:party_game/features/taboo/viewmodels/taboo_setup_state.dart';

void main() {
  test('boş takım isimleri varsayılan adlara döner', () {
    final settings = const TabooSetupState(teamAInput: '  ').toSettings();
    expect(settings.teamAName, 'Takım A');
    expect(settings.teamBName, 'Takım B');
  });

  test('aynı takım adı (Türkçe harf duyarsız) kabul edilmez', () {
    const state = TabooSetupState(teamAInput: 'IŞIK', teamBInput: 'ışık');
    expect(state.canStart, isFalse);
    expect(state.errorMessage, 'İki takımın adı farklı olmalı.');
  });

  test('farklı isimlerle oyun başlatılabilir', () {
    const state =
        TabooSetupState(teamAInput: 'Kartallar', teamBInput: 'Aslanlar');
    expect(state.canStart, isTrue);
    expect(state.toSettings().teamNames, ['Kartallar', 'Aslanlar']);
  });
}
