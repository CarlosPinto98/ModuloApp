// ============================================================
//  TokenStore.dart
//  Almacén de tokens de sesión y datos del usuario autenticado.
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../model/TransferenciaModels.dart';

class TokenStore {

  static String? token;      // tokenApp del microservicio externo
  static String? jwtPropio;  // JWT propio del backend Spring Boot
  static int?    expiraEn;

  static String nombre   = 'Usuario';
  static String apellido = '';
  static String email    = '';
  static String fotoApp  = '';

  // ── CUENTAS ───────────────────────────────────────────────────────────
  static List<CuentaInfo> cuentas       = [];
  static CuentaInfo?      cuentaActiva;

  // ── TOKEN DE PRUEBA ───────────────────────────────────────────────────
  static const String? tokenPrueba =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJwZW5kaWVudGVfMTc3NzU1ODg1Njk1NEB0bXAuY29tIiwiZXNFbXByZXNhIjpmYWxzZSwicm9sZXMiOlsiUGFkcmUiXSwibm9tYnJlcyI6IkNhcmxvcyIsImFwZWxsaWRvcyI6IlBpbnRvIiwidXVpZEFjY2VzbyI6IjU4NGE0NWM2LTUyNTUtNGQ4ZC1iNTZjLTdhYjgyMGMxNDM1NSIsImV4cGlyYUVuIjoxNzc4OTA2MTEyMzI1LCJpYXQiOjE3Nzg4MTk3MTIsImV4cCI6MTc3ODkwNjExMn0.sNzZlRsdi9ZsCCDzE21RlHXKgulvjadXC-9XF6nVASw";

  static const List<String> claves = [
    'tokenApp', 'token', 'jwt_token', 'auth_token', 'access_token', 'userToken',
  ];

  // ── Carga tokens desde SharedPreferences al iniciar ───────────────────
  static Future<void> cargarDesdePrefs() async {
    if (token != null) return;
    final prefs = await SharedPreferences.getInstance();

    for (final clave in claves) {
      final valor = prefs.getString(clave);
      if (valor != null && valor.isNotEmpty) { token = valor; break; }
    }

    expiraEn = prefs.getInt('tokenExpiraEn');

    final jwtGuardado = prefs.getString('jwtPropio');
    if (jwtGuardado != null && jwtGuardado.isNotEmpty) {
      jwtPropio = jwtGuardado;
    }

    if (token == null && tokenPrueba != null && tokenPrueba!.isNotEmpty) {
      token = tokenPrueba;
    }
  }

  // ── Guarda lista de cuentas y activa la primera ────────────────────────
  static void setCuentas(List<CuentaInfo> lista) {
    cuentas = lista;
    if (lista.isNotEmpty && cuentaActiva == null) {
      cuentaActiva = lista.first;
    }
    // Si la cuenta activa ya no está en la lista, resetear a la primera
    if (cuentaActiva != null) {
      final sigue = lista.any((c) => c.id == cuentaActiva!.id);
      if (!sigue) cuentaActiva = lista.isNotEmpty ? lista.first : null;
    }
  }

  // ── Cambia la cuenta activa ────────────────────────────────────────────
  static void setcuentaActiva(CuentaInfo cuenta) {
    cuentaActiva = cuenta;
  }

  // ── Agrega una cuenta nueva a la lista ────────────────────────────────
  static void agregarCuenta(CuentaInfo cuenta) {
    cuentas = [...cuentas, cuenta];
  }

  // ── Elimina una cuenta de la lista ────────────────────────────────────
  static void eliminarCuentaLocal(int cuentaId) {
    cuentas = cuentas.where((c) => c.id != cuentaId).toList();
    if (cuentaActiva?.id == cuentaId) {
      cuentaActiva = cuentas.isNotEmpty ? cuentas.first : null;
    }
  }

  // ── Actualiza el saldo de una cuenta en la lista local ────────────────
  static void actualizarSaldoCuenta(int cuentaId, double nuevoSaldo) {
    cuentas = cuentas.map((c) {
      if (c.id == cuentaId) {
        return CuentaInfo(id: c.id, numeroCuenta: c.numeroCuenta, saldo: nuevoSaldo);
      }
      return c;
    }).toList();
    if (cuentaActiva?.id == cuentaId) {
      cuentaActiva = CuentaInfo(
        id: cuentaActiva!.id,
        numeroCuenta: cuentaActiva!.numeroCuenta,
        saldo: nuevoSaldo,
      );
    }
  }

  // ── tokenApp ──────────────────────────────────────────────────────────
  static void    set(String t)      => token = t;
  static String? get()              => token;
  static void    clear()            => token = null;
  static bool    get tieneToken     => token != null;
  static bool    get tokenExpirado {
    if (expiraEn == null) return false;
    return DateTime.now().millisecondsSinceEpoch >= expiraEn!;
  }

  // ── JWT propio del backend ────────────────────────────────────────────
  static Future<void> setJwtPropio(String jwt) async {
    jwtPropio = jwt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwtPropio', jwt);
  }

  static String? getJwtPropio()     => jwtPropio;
  static bool    get tieneJwtPropio => jwtPropio != null;

  // ── Extrae fotoApp del token externo ──────────────────────────────────
  static void extraerDatosToken(String tokenRaw) {
    try {
      final partes = tokenRaw.split('.');
      if (partes.length < 2) return;
      String payload = partes[1];
      final mod = payload.length % 4;
      if (mod != 0) payload += '=' * (4 - mod);
      final decoded = utf8.decode(base64Url.decode(payload));
      final json = jsonDecode(decoded);
      fotoApp = json['fotoApp'] ?? '';
    } catch (_) {}
  }
}