// ============================================================
//  Resultado.dart
//  Bottom sheet que muestra el resultado de una transferencia.
// ============================================================

import 'package:flutter/material.dart';

class Resultado extends StatelessWidget {
  final bool          exito;
  final String        mensaje;
  final String        referencia;
  final VoidCallback? onGoHome;

  const Resultado({
    super.key,
    required this.exito,
    required this.mensaje,
    required this.referencia,
    this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    final color = exito ? const Color(0xFF00D4AA) : const Color(0xFFFF5C7A);
    final icon  = exito ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            exito ? '¡Transferencia exitosa!' : 'Transferencia fallida',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(mensaje,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
              textAlign: TextAlign.center),
          if (referencia.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.05)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Referencia',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                Text(referencia,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
          const SizedBox(height: 28),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withOpacity(0.06),
                      border: Border.all(color: Colors.white.withOpacity(0.1))),
                  child: Center(child: Text('Nueva transferencia',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () { Navigator.pop(context); onGoHome?.call(); },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)])),
                  child: const Center(child: Text('Inicio',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
