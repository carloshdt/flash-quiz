// tool/gerar_sons.dart
// Gera sons placeholder (substituíveis por CC0 curados depois).
// Rodar: dart run tool/gerar_sons.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 22050;

Uint8List _wav(List<double> amostras) {
  final dados = Int16List(amostras.length);
  for (var i = 0; i < amostras.length; i++) {
    dados[i] = (amostras[i].clamp(-1.0, 1.0) * 32767).round();
  }
  final bytes = dados.buffer.asUint8List();
  final header = BytesBuilder();
  void str(String s) => header.add(s.codeUnits);
  void u32(int v) => header.add(
      (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  void u16(int v) => header.add(
      (ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());
  str('RIFF');
  u32(36 + bytes.length);
  str('WAVE');
  str('fmt ');
  u32(16);
  u16(1);
  u16(1);
  u32(sampleRate);
  u32(sampleRate * 2);
  u16(2);
  u16(16);
  str('data');
  u32(bytes.length);
  header.add(bytes);
  return header.toBytes();
}

List<double> _ruido(double dur, {double decaimento = 12}) {
  final r = Random(7);
  final n = (dur * sampleRate).round();
  return List.generate(n, (i) {
    final t = i / sampleRate;
    return (r.nextDouble() * 2 - 1) * exp(-decaimento * t) * 0.5;
  });
}

List<double> _quadrada(List<(double, double)> notas, {double vol = 0.3}) {
  final out = <double>[];
  for (final (freq, dur) in notas) {
    final n = (dur * sampleRate).round();
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      out.add((sin(2 * pi * freq * t) > 0 ? 1 : -1) * vol * exp(-3 * t));
    }
  }
  return out;
}

void main() {
  final dir = Directory('assets/sounds')..createSync(recursive: true);
  final sons = <String, List<double>>{
    'papel_virar.wav': _ruido(0.15, decaimento: 20),
    'papel_recorte.wav': _ruido(0.25, decaimento: 10),
    'carimbo.wav': _ruido(0.12, decaimento: 30) + _quadrada([(90, 0.1)], vol: 0.5),
    'papel_amassar.wav': _ruido(0.3, decaimento: 6),
    'pixel_comer.wav': _quadrada([(660, 0.06), (880, 0.06)]),
    'pixel_evolucao.wav': _quadrada([(523, 0.1), (659, 0.1), (784, 0.1), (1047, 0.25)]),
    'fanfarra.wav': _quadrada([(523, 0.12), (523, 0.08), (659, 0.12), (784, 0.3)]),
    'confete.wav': _quadrada([(1319, 0.05), (1568, 0.05), (2093, 0.1)], vol: 0.2),
  };
  sons.forEach((nome, amostras) {
    File('${dir.path}/$nome').writeAsBytesSync(_wav(amostras));
    stdout.writeln('gerado $nome');
  });
}
