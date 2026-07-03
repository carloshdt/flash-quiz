// test/services/audio_service_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashquiz/db/database_helper.dart';
import 'package:flashquiz/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('setSomAtivo(false) registra evento som_toggled com valor off', () async {
    final audio = AudioService();
    await audio.carregarPreferencias();
    await audio.setSomAtivo(false);

    final db = await DatabaseHelper().banco;
    final rows = await db.query('eventos', where: "evento = 'som_toggled'");
    expect(rows.length, 1);
    expect(rows.first['valor'], 'off');
  });

  test('vibrar respeita gating de haptics', () async {
    // Intercepta o canal de plataforma pra registrar chamadas de haptics
    final chamadas = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      chamadas.add(call);
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    final audio = AudioService();
    await audio.carregarPreferencias();

    // haptics on → gera chamada HapticFeedback.vibrate
    audio.vibrar(Vibracao.leve);
    await Future<void>.delayed(Duration.zero);
    expect(
      chamadas.where((c) => c.method == 'HapticFeedback.vibrate'),
      hasLength(1),
    );

    // haptics off → não gera chamada
    chamadas.clear();
    await audio.setHapticsAtivo(false);
    audio.vibrar(Vibracao.leve);
    await Future<void>.delayed(Duration.zero);
    expect(
      chamadas.where((c) => c.method == 'HapticFeedback.vibrate'),
      isEmpty,
    );
  });

  test('tocar com som off completa sem instanciar player', () async {
    final audio = AudioService();
    await audio.carregarPreferencias();
    await audio.setSomAtivo(false);

    // com som off retorna antes de tocar — não lança nem cria player
    await audio.tocar(Som.carimbo);
  });
}
