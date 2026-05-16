// ============================================================
//  TransferenciaService.dart
//  Capa de servicio — compatible con el backend Spring Boot.
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'TokenStore.dart';
import '../model/TransferenciaModels.dart';

// ── CONFIGURACIÓN DE URL ──────────────────────────────────────────────────
const String baseUrl = 'http://192.168.1.7:8080/api';

// ── HEADERS ───────────────────────────────────────────────────────────────
Future<Map<String, String>> headersAsync() async {
  final jwtPropio = TokenStore.getJwtPropio();
  if (jwtPropio != null) {
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $jwtPropio'};
  }
  final token = TokenStore.get();
  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

// ═══════════════════════════════════════════════════════════════════════════
class TransferenciaService {

  // ── LOGIN CON TOKEN EXTERNO ────────────────────────────────────────────
  static Future<LoginResponse?> loginConTokenExterno() async {
    try {
      final tokenApp = TokenStore.get();
      if (tokenApp == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/token-externo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tokenApp': tokenApp}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = LoginResponse.fromJson(jsonDecode(response.body));
        TokenStore.jwtPropio = null;
        await TokenStore.setJwtPropio(data.token);
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error en loginConTokenExterno: $e');
      return null;
    }
  }

  // ── SALDO de cuenta específica ─────────────────────────────────────────
  static Future<double?> obtenerSaldo() async {
    try {
      final cuentaId = TokenStore.cuentaActiva?.id;
      if (cuentaId == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/usuario/saldo?cuentaId=$cuentaId'),
        headers: await headersAsync(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['saldo'] as num).toDouble();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── TRANSFERENCIA ──────────────────────────────────────────────────────
  static Future<TransferenciaResponse> realizarTransferencia(
      TransferenciaRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/transferencias'),
        headers: await headersAsync(),
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TransferenciaResponse.fromJson(data);
      }
      return TransferenciaResponse.error(data['mensaje'] ?? 'Error en la transferencia');
    } on http.ClientException {
      return TransferenciaResponse.error('No se pudo conectar al servidor');
    } catch (_) {
      return TransferenciaResponse.error('Error inesperado');
    }
  }

  // ── HISTORIAL COMPLETO de cuenta activa ───────────────────────────────
  static Future<List<Movimiento>> obtenerMovimientos() async {
    try {
      final cuentaId = TokenStore.cuentaActiva?.id;
      if (cuentaId == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/transferencias/historial?cuentaId=$cuentaId'),
        headers: await headersAsync(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Movimiento.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error en obtenerMovimientos: $e');
      return [];
    }
  }

  // ── HISTORIAL DE HOY de cuenta activa ────────────────────────────────
  static Future<List<Movimiento>> obtenerMovimientosHoy() async {
    try {
      final cuentaId = TokenStore.cuentaActiva?.id;
      if (cuentaId == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/transferencias/historial/hoy?cuentaId=$cuentaId'),
        headers: await headersAsync(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Movimiento.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error en obtenerMovimientosHoy: $e');
      return [];
    }
  }

  // ── RECARGA desde cuenta activa ────────────────────────────────────────
  static Future<Map<String, dynamic>> realizarRecarga({
    required double monto,
    required String metodoPago,
    String? cuentaDestino,
  }) async {
    try {
      final cuentaOrigenId = TokenStore.cuentaActiva?.id;
      if (cuentaOrigenId == null) return {'exito': false, 'mensaje': 'Sin cuenta activa'};

      final response = await http.post(
        Uri.parse('$baseUrl/recargas'),
        headers: await headersAsync(),
        body: jsonEncode({
          'cuentaOrigenId': cuentaOrigenId,
          'monto':          monto,
          'metodoPago':     metodoPago,
          if (cuentaDestino != null) 'cuentaDestino': cuentaDestino,
        }),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (_) {
      return {'exito': false, 'mensaje': 'Error de conexión'};
    }
  }

  // ── ACTUALIZAR NÚMERO DE CUENTA ────────────────────────────────────────
  static Future<Map<String, dynamic>> actualizarNumeroCuenta(
      String nuevaCuenta, int cuentaId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/usuario/cuenta'),
        headers: await headersAsync(),
        body: jsonEncode({'cuentaId': cuentaId, 'numeroCuenta': nuevaCuenta}),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (_) {
      return {'exito': false, 'mensaje': 'Error de conexión'};
    }
  }

  // ── CREAR NUEVA CUENTA ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> crearCuenta() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuario/cuenta'),
        headers: await headersAsync(),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (_) {
      return {'exito': false, 'mensaje': 'Error de conexión'};
    }
  }

  // ── ELIMINAR CUENTA ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> eliminarCuenta(int cuentaId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/usuario/cuenta/$cuentaId'),
        headers: await headersAsync(),
      ).timeout(const Duration(seconds: 15));

      return jsonDecode(response.body);
    } catch (_) {
      return {'exito': false, 'mensaje': 'Error de conexión'};
    }
  }
}