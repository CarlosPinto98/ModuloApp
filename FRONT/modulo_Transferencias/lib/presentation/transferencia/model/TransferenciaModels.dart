// ============================================================
//  TransferenciaModels.dart
//  Modelos de datos usados por TransferenciaService.
// ============================================================

// ── Modelo de una cuenta bancaria ─────────────────────────────────────────
class CuentaInfo {
  final int    id;
  final String numeroCuenta;
  final double saldo;

  const CuentaInfo({
    required this.id,
    required this.numeroCuenta,
    required this.saldo,
  });

  factory CuentaInfo.fromJson(Map<String, dynamic> json) {
    return CuentaInfo(
      id:           (json['id'] as num).toInt(),
      numeroCuenta: json['numeroCuenta'] as String? ?? '',
      saldo:        (json['saldo'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ── Respuesta del login ────────────────────────────────────────────────────
class LoginResponse {
  final String           token;
  final String           nombre;
  final String           apellido;
  final String           email;
  final List<CuentaInfo> cuentas;

  const LoginResponse({
    required this.token,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.cuentas,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final cuentasJson = json['cuentas'] as List<dynamic>? ?? [];
    return LoginResponse(
      token:    json['token']    as String,
      nombre:   json['nombre']   as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      email:    json['email']    as String? ?? '',
      cuentas:  cuentasJson.map((c) => CuentaInfo.fromJson(c)).toList(),
    );
  }
}

// ── Request de transferencia ───────────────────────────────────────────────
class TransferenciaRequest {
  final int    cuentaOrigenId;
  final String cuentaDestino;
  final double monto;
  final String concepto;

  const TransferenciaRequest({
    required this.cuentaOrigenId,
    required this.cuentaDestino,
    required this.monto,
    required this.concepto,
  });

  Map<String, dynamic> toJson() => {
    'cuentaOrigenId': cuentaOrigenId,
    'cuentaDestino':  cuentaDestino,
    'monto':          monto,
    'concepto':       concepto,
  };
}

// ── Respuesta de transferencia ─────────────────────────────────────────────
class TransferenciaResponse {
  final bool   exito;
  final String referencia;
  final String mensaje;

  const TransferenciaResponse({
    required this.exito,
    required this.referencia,
    required this.mensaje,
  });

  factory TransferenciaResponse.fromJson(Map<String, dynamic> json) {
    return TransferenciaResponse(
      exito:      json['exito']      as bool?   ?? false,
      referencia: json['referencia'] as String? ?? '',
      mensaje:    json['mensaje']    as String? ?? '',
    );
  }

  factory TransferenciaResponse.error(String mensaje) {
    return TransferenciaResponse(exito: false, referencia: '', mensaje: mensaje);
  }
}

// ── Movimiento del historial ───────────────────────────────────────────────
class Movimiento {
  final String referencia;
  final String cuentaDestino;
  final double monto;
  final String concepto;
  final String fechaHora;
  final String estado;
  final String tipo;
  final bool   esHoy;

  const Movimiento({
    required this.referencia,
    required this.cuentaDestino,
    required this.monto,
    required this.concepto,
    required this.fechaHora,
    required this.estado,
    required this.tipo,
    required this.esHoy,
  });

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    return Movimiento(
      referencia:    json['referencia']    as String? ?? '',
      cuentaDestino: json['cuentaDestino'] as String? ?? '',
      monto:         (json['monto'] as num?)?.toDouble() ?? 0.0,
      concepto:      json['concepto']      as String? ?? '',
      fechaHora:     json['fechaHora']     as String? ?? '',
      estado:        (json['estado'] as String? ?? 'pendiente').toLowerCase(),
      tipo:          (json['tipo']   as String? ?? 'transferencia').toLowerCase(),
      esHoy:         json['esHoy']         as bool? ?? false,
    );
  }
}