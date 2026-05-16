// ============================================================
//  PerfilContent.dart
//  Perfil con soporte para múltiples cuentas.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../service/TransferenciaService.dart';
import '../service/SaldoService.dart';
import '../service/TokenStore.dart';
import '../model/TransferenciaModels.dart';

class PerfilContent extends StatefulWidget {
  const PerfilContent({super.key});

  @override
  State<PerfilContent> createState() => PerfilContentState();
}

class PerfilContentState extends State<PerfilContent> {
  bool guardando = false;

  // ── Helpers de formato ────────────────────────────────────────────────
  String formatearSaldo(double saldo) {
    return saldo.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?=\.))'), (m) => '${m[1]},');
  }

  // ── Snack ─────────────────────────────────────────────────────────────
  void mostrarSnack(String msg, {required bool error}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
          color: error ? const Color(0xFFFF5C7A) : const Color(0xFF00D4AA),
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: const Color(0xFF13131A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Seleccionar cuenta activa ─────────────────────────────────────────
  void seleccionarCuenta(CuentaInfo cuenta) {
    setState(() {
      TokenStore.setcuentaActiva(cuenta);
      SaldoService.instancia.setSaldo(cuenta.saldo);
    });
  }

  // ── Crear nueva cuenta ────────────────────────────────────────────────
  Future<void> crearCuenta() async {
    if (TokenStore.cuentas.length >= 3) {
      mostrarSnack('Has alcanzado el límite de 3 cuentas', error: true);
      return;
    }
    setState(() => guardando = true);
    final res = await TransferenciaService.crearCuenta();
    setState(() => guardando = false);

    if (res['exito'] == true) {
      final nueva = CuentaInfo(
        id:           (res['cuentaId'] as num).toInt(),
        numeroCuenta: res['numeroCuenta'] as String,
        saldo:        (res['saldo'] as num).toDouble(),
      );
      setState(() => TokenStore.agregarCuenta(nueva));
      mostrarSnack('Cuenta creada correctamente', error: false);
    } else {
      mostrarSnack(res['mensaje'] ?? 'Error al crear cuenta', error: true);
    }
  }

  // ── Eliminar cuenta ───────────────────────────────────────────────────
  Future<void> eliminarCuenta(CuentaInfo cuenta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar cuenta',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
          'La cuenta ${cuenta.numeroCuenta} será eliminada.\nDebe tener saldo \$0 para poder eliminarla.',
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFFF5C7A).withOpacity(0.15),
              ),
              child: const Text('Eliminar',
                  style: TextStyle(color: Color(0xFFFF5C7A), fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => guardando = true);
    final res = await TransferenciaService.eliminarCuenta(cuenta.id);
    setState(() => guardando = false);

    if (res['exito'] == true) {
      setState(() => TokenStore.eliminarCuentaLocal(cuenta.id));
      SaldoService.instancia.setSaldo(TokenStore.cuentaActiva?.saldo ?? 0.0);
      mostrarSnack('Cuenta eliminada', error: false);
    } else {
      mostrarSnack(res['mensaje'] ?? 'Error al eliminar', error: true);
    }
  }

  // ── Editar número de cuenta ───────────────────────────────────────────
  void mostrarDialogEditar(CuentaInfo cuenta) {
    final cuentaCtrl = TextEditingController(text: cuenta.numeroCuenta);
    final formKey    = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar número de cuenta',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ingresa el nuevo número de cuenta',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
              const SizedBox(height: 14),
              TextFormField(
                controller: cuentaCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 15, letterSpacing: 1.5),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa el número';
                  if (v.trim().length < 8)  return 'Mínimo 8 dígitos';
                  if (v.trim().length > 20) return 'Máximo 20 dígitos';
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Ej: 0012345678',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), letterSpacing: 0),
                  prefixIcon: const Icon(Icons.tag_rounded, color: Colors.white38, size: 20),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF5C7A))),
                  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF5C7A), width: 1.5)),
                  errorStyle: const TextStyle(color: Color(0xFFFF5C7A)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w600)),
          ),
          StatefulBuilder(
            builder: (context, setDialogState) => GestureDetector(
              onTap: guardando ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => guardando = true);
                final res = await TransferenciaService.actualizarNumeroCuenta(
                    cuentaCtrl.text.trim(), cuenta.id);
                setDialogState(() => guardando = false);
                if (!mounted) return;
                Navigator.pop(ctx);
                if (res['exito'] == true) {
                  setState(() {
                    final idx = TokenStore.cuentas.indexWhere((c) => c.id == cuenta.id);
                    if (idx != -1) {
                      final actualizada = CuentaInfo(
                        id: cuenta.id,
                        numeroCuenta: cuentaCtrl.text.trim(),
                        saldo: cuenta.saldo,
                      );
                      TokenStore.cuentas = List.from(TokenStore.cuentas)..[idx] = actualizada;
                      if (TokenStore.cuentaActiva?.id == cuenta.id) {
                        TokenStore.setcuentaActiva(actualizada);
                      }
                    }
                  });
                  mostrarSnack('Número de cuenta actualizado', error: false);
                } else {
                  mostrarSnack(res['mensaje'] ?? 'Error al actualizar', error: true);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: guardando
                      ? LinearGradient(colors: [
                    Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.08)])
                      : const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
                ),
                child: guardando
                    ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2))
                    : const Text('Guardar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget de tarjeta de cuenta ───────────────────────────────────────
  Widget _tarjetaCuenta(CuentaInfo cuenta) {
    final esActiva = TokenStore.cuentaActiva?.id == cuenta.id;
    return GestureDetector(
      onTap: () => seleccionarCuenta(cuenta),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(
            color: esActiva ? const Color(0xFF6C63FF) : Colors.white.withOpacity(0.08),
            width: esActiva ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fila superior: número + acciones ─────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Text(cuenta.numeroCuenta,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  if (esActiva) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
                      ),
                      child: const Text('Activa',
                          style: TextStyle(color: Colors.white,
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
                Row(children: [
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: cuenta.numeroCuenta));
                      mostrarSnack('Número Copiado', error: false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF00D4AA).withOpacity(0.12),
                      ),
                      child: const Icon(Icons.copy_rounded,
                          color: Color(0xFF00D4AA), size: 14),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => mostrarDialogEditar(cuenta),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF6C63FF).withOpacity(0.12),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Color(0xFF6C63FF), size: 14),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => eliminarCuenta(cuenta),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFFFF5C7A).withOpacity(0.12),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFFF5C7A), size: 14),
                    ),
                  ),
                ]),
              ],
            ),

            // ── Saldo disponible ──────────────────────────────────────
            const SizedBox(height: 10),
            Text('Saldo Disponible',
                style: TextStyle(color: Colors.white.withOpacity(0.45),
                    fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('\$${formatearSaldo(cuenta.saldo)}',
                style: const TextStyle(color: Color(0xFF00D4AA),
                    fontSize: 18, fontWeight: FontWeight.w800)),

            // ── Correo (siempre visible dentro del recuadro) ──────────
            if (TokenStore.email.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Correo Electrónico',
                  style: TextStyle(color: Colors.white.withOpacity(0.45),
                      fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(TokenStore.email,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Avatar + nombre ───────────────────────────────────────────
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                ListenableBuilder(
                  listenable: SaldoService.instancia,
                  builder: (_, __) {
                    final tieneFoto = TokenStore.fotoApp.isNotEmpty;
                    return Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: tieneFoto ? null : const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
                      ),
                      child: tieneFoto
                          ? ClipOval(child: Image.memory(
                          base64Decode(TokenStore.fotoApp),
                          fit: BoxFit.cover, width: 88, height: 88))
                          : const Icon(Icons.person_outline_rounded,
                          color: Colors.white, size: 44),
                    );
                  },
                ),
                const SizedBox(height: 14),
                ListenableBuilder(
                  listenable: SaldoService.instancia,
                  builder: (_, __) => Text(
                    '${TokenStore.nombre} ${TokenStore.apellido}'.trim(),
                    style: const TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Mis Cuentas ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mis cuentas',
                  style: TextStyle(color: Colors.white.withOpacity(0.45),
                      fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              Text('${TokenStore.cuentas.length}/3',
                  style: TextStyle(color: Colors.white.withOpacity(0.3),
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),

          ListenableBuilder(
            listenable: SaldoService.instancia,
            builder: (_, __) => Column(
              children: TokenStore.cuentas.map(_tarjetaCuenta).toList(),
            ),
          ),

          // ── Botón agregar cuenta ──────────────────────────────────────
          if (TokenStore.cuentas.length < 3) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: guardando ? null : crearCuenta,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    width: 1.5,
                  ),
                  color: const Color(0xFF6C63FF).withOpacity(0.06),
                ),
                child: guardando
                    ? const Center(child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Color(0xFF6C63FF), strokeWidth: 2)))
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: Color(0xFF6C63FF), size: 20),
                    SizedBox(width: 8),
                    Text('Agregar cuenta',
                        style: TextStyle(color: Color(0xFF6C63FF),
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}