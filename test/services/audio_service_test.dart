// test/services/audio_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';
import 'package:flashquiz/services/audio_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() => DatabaseHelper.setCaminhoParaTeste(inMemoryDatabasePath));
  tearDown(() async => DatabaseHelper().fecharParaTeste());

  test('toggles default ligados e persistem', () async {
    final audio = AudioService();
    await audio.carregarPreferencias();
    expect(audio.somAtivo, isTrue);
    expect(audio.hapticsAtivo, isTrue);

    await audio.setSomAtivo(false);
    expect(audio.somAtivo, isFalse);

    // nova instância relê do config
    final audio2 = AudioService();
    await audio2.carregarPreferencias();
    expect(audio2.somAtivo, isFalse);
    expect(audio2.hapticsAtivo, isTrue);
  });
}
