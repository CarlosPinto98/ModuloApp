// ============================================================
//  HistorialService.dart
//  Singleton que carga el historial desde el backend real.
//  El módulo de Auth llama cargarDesdeBackend() después
//  del login para poblar la lista con datos reales.
// ============================================================

import 'package:flutter/foundation.dart';
import '../model/MovimientoItem.dart';
import 'TransferenciaService.dart';

class HistorialService extends ChangeNotifier {
  HistorialService._();
  static final HistorialService instancia = HistorialService._();

  final List<MovimientoItem> movimientos = [];
  bool cargandoInterno = false;
  String? errorInterno;

  List<MovimientoItem> get todos    => List.unmodifiable(movimientos);
  List<MovimientoItem> get deHoy    => movimientos.where((m) => m.esHoy).toList();
  bool                 get cargando => cargandoInterno;
  String?              get error    => errorInterno;

  // ── AGREGAR UN MOVIMIENTO NUEVO (transferencia o recarga recién hecha) ──
  void agregar(MovimientoItem item) {
    movimientos.insert(0, item);
    notifyListeners();
  }

  // ── CARGAR HISTORIAL COMPLETO DESDE EL BACKEND ─────────────────────
  Future<void> cargarDesdeBackend() async {
    cargandoInterno = true;
    errorInterno    = null;
    notifyListeners();

    try {
      final resultado = await TransferenciaService.obtenerMovimientos();

      movimientos.clear();
      movimientos.addAll(
        resultado.map((m) => MovimientoItem(
          referencia:    m.referencia,
          cuentaDestino: m.cuentaDestino,
          monto:         formatearMonto(m.monto),
          concepto:      m.concepto,
          fechaHora:     m.fechaHora,
          estado:        m.estado,
          tipo:          m.tipo,
          esHoy:         m.esHoy,
        )),
      );
    } catch (e) {
      errorInterno = 'No se pudo cargar el historial';
    } finally {
      cargandoInterno = false;
      notifyListeners();
    }
  }

  // ── REFRESCO SILENCIOSO (sin mostrar loading — para el timer) ──────
  Future<void> refrescarHoySilencioso() async {
    try {
      final resultado = await TransferenciaService.obtenerMovimientosHoy();
      movimientos.removeWhere((m) => m.esHoy);
      movimientos.insertAll(
        0,
        resultado.map((m) => MovimientoItem(
          referencia:    m.referencia,
          cuentaDestino: m.cuentaDestino,
          monto:         formatearMonto(m.monto),
          concepto:      m.concepto,
          fechaHora:     m.fechaHora,
          estado:        m.estado,
          tipo:          m.tipo,
          esHoy:         m.esHoy,
        )),
      );
      notifyListeners();
    } catch (_) {
      // si falla silenciosamente, no muestra error ni parpadeo
    }
  }

  // ── CARGAR SOLO LOS DE HOY ──────────────────────────────────────────
  Future<void> cargarHoyDesdeBackend() async {
    cargandoInterno = true;
    errorInterno    = null;
    notifyListeners();

    try {
      final resultado = await TransferenciaService.obtenerMovimientosHoy();

      // Reemplaza solo los de hoy, conserva los anteriores
      movimientos.removeWhere((m) => m.esHoy);
      movimientos.insertAll(
        0,
        resultado.map((m) => MovimientoItem(
          referencia:    m.referencia,
          cuentaDestino: m.cuentaDestino,
          monto:         formatearMonto(m.monto),
          concepto:      m.concepto,
          fechaHora:     m.fechaHora,
          estado:        m.estado,
          tipo:          m.tipo,
          esHoy:         m.esHoy,
        )),
      );
    } catch (e) {
      errorInterno = 'No se pudo cargar los movimientos de hoy';
    } finally {
      cargandoInterno = false;
      notifyListeners();
    }
  }

  // ── LIMPIAR (al cerrar sesión) ──────────────────────────────────────
  void limpiar() {
    movimientos.clear();
    errorInterno = null;
    notifyListeners();
  }

  // ── HELPER: convierte double a string formateado ─────────────────────
  // 1500000.0  →  "1.500.000"
  static String formatearMonto(double monto) {
    final entero = monto.toStringAsFixed(0);
    return entero.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }

  // ── HELPER ESTÁTICO para crear un item desde una transferencia ───────
  static MovimientoItem desdeTransferencia({
    required String referencia,
    required String cuentaDestino,
    required String monto,
    required String concepto,
    required bool   exito,
  }) {
    final ahora = DateTime.now();
    final hora  = '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';
    return MovimientoItem(
      referencia:    referencia,
      cuentaDestino: cuentaDestino,
      monto:         monto,
      concepto:      concepto,
      fechaHora:     'Hoy, $hora',
      estado:        exito ? 'completado' : 'fallido',
      tipo:          'transferencia',
      esHoy:         true,
    );
  }

  // ── HELPER ESTÁTICO para crear un item desde una recarga ────────────
  static MovimientoItem desdeRecarga({
    required String referencia,
    required double monto,
    required String metodoPago,
    required String cuentaDestino,
  }) {
    final ahora = DateTime.now();
    final hora  = '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';
    return MovimientoItem(
      referencia:    referencia,
      cuentaDestino: cuentaDestino,
      monto:         formatearMonto(monto),
      concepto:      'Recarga - $metodoPago',
      fechaHora:     'Hoy, $hora',
      estado:        'completado',
      tipo:          'recarga',
      esHoy:         true,
    );
  }
}