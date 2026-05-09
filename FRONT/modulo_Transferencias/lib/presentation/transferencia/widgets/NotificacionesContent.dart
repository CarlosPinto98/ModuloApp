// ============================================================
//  NotificacionesContent.dart
//  Pantalla placeholder del módulo de Notificaciones.
// ============================================================

import 'package:flutter/material.dart';

class NotificacionesContent extends StatelessWidget {
  const NotificacionesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.notifications_outlined, color: Colors.white.withOpacity(0.2), size: 60),
        const SizedBox(height: 12),
        Text('Sin notificaciones', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16)),
      ]),
    );
  }
}
