// lib/screens/secoes/secoes_screen.dart
import 'package:flutter/material.dart';

class SecoesScreen extends StatelessWidget {
  final int temaId;
  final String nomeTema;

  const SecoesScreen({super.key, required this.temaId, required this.nomeTema});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nomeTema)),
      body: const Center(child: Text('Seções')),
    );
  }
}
