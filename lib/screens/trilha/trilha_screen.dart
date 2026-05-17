// lib/screens/trilha/trilha_screen.dart
import 'package:flutter/material.dart';

class TrilhaScreen extends StatelessWidget {
  final int temaId;
  final int secaoId;
  final String nomeSecao;
  final String nomeTema;

  const TrilhaScreen({
    super.key,
    required this.temaId,
    required this.secaoId,
    required this.nomeSecao,
    required this.nomeTema,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$nomeTema — $nomeSecao')),
      body: const Center(child: Text('Trilha')),
    );
  }
}
