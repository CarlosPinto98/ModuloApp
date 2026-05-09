// ============================================================
//  PerfilContent.dart
//  Pantalla placeholder del módulo de Perfil.
// ============================================================

import 'package:flutter/material.dart';

class PerfilContent extends StatelessWidget {
  const PerfilContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
          ),
          child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        Text('Mi Perfil', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16)),
      ]),
    );
  }
}
