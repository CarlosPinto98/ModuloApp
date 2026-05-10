// ============================================================
//  TokenStore.dart
//  Almacén de tokens de sesión (tokenApp externo y JWT propio).
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static String? token;      // tokenApp del microservicio externo
  static String? jwtPropio;  // JWT propio del backend Spring Boot
  static int?    expiraEn;

  static String nombre   = 'Usuario';
  static String apellido = '';
  static String email    = '';

  static const List<String> claves = [
    'tokenApp',
    'token',
    'jwt_token',
    'auth_token',
    'access_token',
    'userToken',
  ];

  // ── TOKEN DE PRUEBA ──────────────────────────────────────────────
  // Token del microservicio externo para desarrollo/pruebas.
  // El módulo de Auth lo reemplazará con el token real en producción.
  static const String? tokenPrueba =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJwZW5kaWVudGVfMTc3NzU1ODg1Njk1NEB0bXAuY29tIiwiZXNFbXByZXNhIjpmYWxzZSwicm9sZXMiOlsiUGFkcmUiXSwibm9tYnJlcyI6IkNhcmxvcyIsImFwZWxsaWRvcyI6IlBpbnRvIiwidXVpZEFjY2VzbyI6ImY2NjdjNDdjLWY4MDEtNGI2Yy1iMzYyLWQ5MDQwYzU4NDc1ZCIsImV4cGlyYUVuIjoxNzc4NDY2NDQ4NDYzLCJpYXQiOjE3NzgzODAwNDgsImV4cCI6MTc3ODQ2NjQ0OH0.3bv4Qgh-MNzKTMeZDW-qJwnMI0-YK2RUIAy42FLVcfw';
  // Carga el tokenApp y el jwtPropio desde SharedPreferences al iniciar la app
  static Future<void> cargarDesdePrefs() async {
    if (token != null) return;
    final prefs = await SharedPreferences.getInstance();

    for (final clave in claves) {
      final valor = prefs.getString(clave);
      if (valor != null && valor.isNotEmpty) {
        token = valor;
        break;
      }
    }

    expiraEn = prefs.getInt('tokenExpiraEn');

    // Cargar el JWT propio del backend si ya fue generado antes
    final jwtGuardado = prefs.getString('jwtPropio');
    if (jwtGuardado != null && jwtGuardado.isNotEmpty) {
      jwtPropio = jwtGuardado;
    }

    if (token == null && tokenPrueba != null && tokenPrueba!.isNotEmpty) {
      token = tokenPrueba;
    }
  }

  static Future<void> guardarToken({
    required String tokenApp,
    required int    expiraEn,
  }) async {
    token    = tokenApp;
    expiraEn = expiraEn;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tokenApp',   tokenApp);
    await prefs.setInt('tokenExpiraEn', expiraEn);
  }

  static bool get tokenExpirado {
    if (expiraEn == null) return false;
    return DateTime.now().millisecondsSinceEpoch >= expiraEn!;
  }

  // ── tokenApp (microservicio externo) ──────────────────────────────
  static void    set(String t) => token = t;
  static String? get()             => token;
  static void    clear()           => token = null;
  static bool    get tieneToken    => token != null;

  // ── JWT propio del backend ────────────────────────────────────────
  // Se guarda después de llamar a /api/auth/token-externo
  // Lo persiste en SharedPreferences para sobrevivir navegación entre pantallas
  static Future<void> setJwtPropio(String jwt) async {
    jwtPropio = jwt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwtPropio', jwt);
  }

  static String? getJwtPropio()     => jwtPropio;
  static bool    get tieneJwtPropio => jwtPropio != null;
}
