// lib/models/evento.dart
import 'dart:convert';

class Evento {
  final String evento;
  final String? tema;
  final String? secao;
  final String? valor;
  final Map<String, dynamic>? metadata;

  const Evento({
    required this.evento,
    this.tema,
    this.secao,
    this.valor,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
    'evento': evento,
    'tema': tema,
    'secao': secao,
    'valor': valor,
    'metadata': metadata != null ? jsonEncode(metadata) : null,
  };
}
