// lib/services/audio_service.dart
// Sons de papel/pixel + haptics, com toggles persistidos em config.
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../repositories/config_repository.dart';
import 'metrica_service.dart';

enum Som {
  papelVirar('papel_virar.wav'),
  papelRecorte('papel_recorte.wav'),
  carimbo('carimbo.wav'),
  papelAmassar('papel_amassar.wav'),
  pixelComer('pixel_comer.wav'),
  pixelEvolucao('pixel_evolucao.wav'),
  fanfarra('fanfarra.wav'),
  confete('confete.wav');

  final String arquivo;
  const Som(this.arquivo);
}

enum Vibracao { leve, media, pesada, selecao }

class AudioService {
  final ConfigRepository _config;
  final MetricaService _metrica;

  // Lazy: evita MissingPluginException em testes unit que não tocam som
  AudioPlayer? _playerInstance;
  AudioPlayer get _player => _playerInstance ??= AudioPlayer();

  bool _somAtivo = true;
  bool _hapticsAtivo = true;

  AudioService({ConfigRepository? config, MetricaService? metrica})
      : _config = config ?? ConfigRepository(),
        _metrica = metrica ?? MetricaService();

  bool get somAtivo => _somAtivo;
  bool get hapticsAtivo => _hapticsAtivo;

  Future<void> carregarPreferencias() async {
    _somAtivo = await _config.getValorInt('som_ativo', padrao: 1) == 1;
    _hapticsAtivo = await _config.getValorInt('haptics_ativo', padrao: 1) == 1;
  }

  Future<void> setSomAtivo(bool ativo) async {
    _somAtivo = ativo;
    await _config.setConfig('som_ativo', ativo ? '1' : '0');
    await _metrica.somToggled(ativo);
  }

  Future<void> setHapticsAtivo(bool ativo) async {
    _hapticsAtivo = ativo;
    await _config.setConfig('haptics_ativo', ativo ? '1' : '0');
    await _metrica.hapticsToggled(ativo);
  }

  Future<void> tocar(Som som) async {
    if (!_somAtivo) return;
    try {
      await _player.play(AssetSource('sounds/${som.arquivo}'));
    } catch (_) {
      // som ausente/erro de player nunca quebra o app
    }
  }

  void vibrar(Vibracao v) {
    if (!_hapticsAtivo) return;
    switch (v) {
      case Vibracao.leve:
        HapticFeedback.lightImpact();
      case Vibracao.media:
        HapticFeedback.mediumImpact();
      case Vibracao.pesada:
        HapticFeedback.heavyImpact();
      case Vibracao.selecao:
        HapticFeedback.selectionClick();
    }
  }
}
