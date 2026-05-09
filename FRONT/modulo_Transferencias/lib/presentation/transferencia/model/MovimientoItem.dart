// ============================================================
//  MovimientoItem.dart
//  Modelo de datos que representa un movimiento del historial.
// ============================================================

class MovimientoItem {
  final String referencia;
  final String cuentaDestino;
  final String monto;       // formateado: "1.000.000"
  final String concepto;
  final String fechaHora;
  final String estado;      // 'completado' | 'fallido' | 'pendiente'
  final String tipo;        // 'transferencia' | 'recarga'
  final bool   esHoy;

  const MovimientoItem({
    required this.referencia,
    required this.cuentaDestino,
    required this.monto,
    required this.concepto,
    required this.fechaHora,
    required this.estado,
    required this.tipo,
    required this.esHoy,
  });
}
