// ============================================================
//  TransferenciaModels.dart
//  Modelos de datos usados por TransferenciaService.
// ============================================================

class LoginResponse {
  final String token;
  final String numeroCuenta;
  final String nombre;
  final String apellido;
  final String email;
  final double saldo;

  const LoginResponse({
    required this.token,
    required this.numeroCuenta,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.saldo,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token:        json['token']        as String,
      numeroCuenta: json['numeroCuenta'] as String? ?? '',
      nombre:       json['nombre']       as String? ?? '',
      apellido:     json['apellido']     as String? ?? '',
      email:        json['email']        as String? ?? '',
      saldo:        (json['saldo'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TransferenciaRequest {
  final String cuentaDestino;
  final double monto;
  final String concepto;

  const TransferenciaRequest({
    required this.cuentaDestino,
    required this.monto,
    required this.concepto,
  });

  Map<String, dynamic> toJson() => {
    'cuentaDestino': cuentaDestino,
    'monto':         monto,
    'concepto':      concepto,
  };
}

class TransferenciaResponse {
  final bool    exito;
  final String  referencia;
  final String  mensaje;

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
