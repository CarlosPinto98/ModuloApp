// ============================================================
//  saldo_service.dart
//  Singleton que comparte el saldo entre pantallas.
//  - Al hacer login, el módulo Auth llama setSaldo(saldo).
//  - La recarga llama setSaldo(nuevoSaldo) con el valor real
//    que devuelve el backend en { nuevoSaldo: double }.
//  - La transferencia exitosa llama descontar(monto) localmente
//    (el backend ya descontó en base de datos).
//  - Para refrescar desde el servidor usa sincronizarConBackend().
// ============================================================

import 'package:flutter/foundation.dart';
import 'TransferenciaService.dart';

class SaldoService extends ChangeNotifier {
  SaldoService._();
  static final SaldoService instancia = SaldoService._();

  double saldoActual = 0.0;

  double get saldo => saldoActual;

  // ── Establece el saldo (llamar tras login con el valor del backend) ────
  void setSaldo(double nuevoSaldo) {
    saldoActual = nuevoSaldo;
    notifyListeners();
  }

  // ── Suma monto al saldo (recarga local) ───────────────────────────────
  void recargar(double monto) {
    assert(monto > 0, 'El monto de recarga debe ser positivo');
    saldoActual += monto;
    notifyListeners();
  }

  // ── Resta monto del saldo (transferencia exitosa local) ───────────────
  // Retorna false si no hay saldo suficiente.
  bool descontar(double monto) {
    assert(monto > 0, 'El monto a descontar debe ser positivo');
    if (monto > saldoActual) return false;
    saldoActual -= monto;
    notifyListeners();
    return true;
  }

  // ── Sincroniza el saldo real desde GET /api/usuario/saldo ─────────────
  Future<void> sincronizarConBackend() async {
    final saldoReal = await TransferenciaService.obtenerSaldo();
    if (saldoReal != null) {
      saldoActual = saldoReal;
      notifyListeners();
    }
  }
}
