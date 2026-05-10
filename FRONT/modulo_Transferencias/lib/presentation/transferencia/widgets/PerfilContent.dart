// ============================================================
//  PerfilContent.dart
//  Pantalla de perfil con edición de número de cuenta.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../service/TransferenciaService.dart';
import '../service/SaldoService.dart';
import '../service/TokenStore.dart';

class PerfilContent extends StatefulWidget {
  const PerfilContent({super.key});

  @override
  State<PerfilContent> createState() => PerfilContentState();
}

class PerfilContentState extends State<PerfilContent> {
  // TODO: reemplazar con los datos reales que vengan del módulo Auth
  String numeroCuenta = '0012345678';
  bool guardando = false;

  void mostrarDialogEditar() {
    final cuentaCtrl = TextEditingController(text: numeroCuenta);
    final formKey    = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Editar número de cuenta',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingresa tu nuevo número de cuenta',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: cuentaCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 15, letterSpacing: 1.5),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa el número de cuenta';
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF5C7A))),
                  focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
              onTap: guardando
                  ? null
                  : () async {
                if (!formKey.currentState!.validate()) return;

                setDialogState(() => guardando = true);

                final res = await TransferenciaService.actualizarNumeroCuenta(
                    cuentaCtrl.text.trim());

                setDialogState(() => guardando = false);

                if (!mounted) return;
                Navigator.pop(ctx);

                if (res['exito'] == true) {
                  setState(() => numeroCuenta = cuentaCtrl.text.trim());
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
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.08),
                  ])
                      : const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
                ),
                child: guardando
                    ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2))
                    : const Text('Guardar',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void mostrarSnack(String msg, {required bool error}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
          color: error ? const Color(0xFFFF5C7A) : const Color(0xFF00D4AA),
          size: 18,
        ),
        const SizedBox(width: 10),
        Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      ]),
      backgroundColor: const Color(0xFF13131A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Avatar ────────────────────────────────────────────────────
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Container(
                  width: 88, height: 88,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      color: Colors.white, size: 44),
                ),
                const SizedBox(height: 14),
                ListenableBuilder(
                  listenable: SaldoService.instancia,
                  builder: (_, __) => Text(
                    '${TokenStore.nombre} ${TokenStore.apellido}'.trim(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Sección: Datos de cuenta ──────────────────────────────────
          Text('Datos de cuenta',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Saldo disponible ────────────────────────────────────
                ListenableBuilder(
                  listenable: SaldoService.instancia,
                  builder: (_, __) {
                    final saldo = SaldoService.instancia.saldo;
                    final saldoFmt = saldo
                        .toStringAsFixed(2)
                        .replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?=\.))'),
                            (m) => '${m[1]},');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saldo disponible',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('\$$saldoFmt',
                            style: const TextStyle(
                                color: Color(0xFF00D4AA),
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                      ],
                    );
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Colors.white.withOpacity(0.07), height: 1),
                ),

                // ── Número de cuenta ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Número de cuenta',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text(numeroCuenta,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5)),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: numeroCuenta));
                            mostrarSnack('Número copiado', error: false);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              color: const Color(0xFF00D4AA).withOpacity(0.12),
                            ),
                            child: const Row(children: [
                              Icon(Icons.copy_rounded, color: Color(0xFF00D4AA), size: 14),
                              SizedBox(width: 4),
                              Text('Copiar',
                                  style: TextStyle(
                                      color: Color(0xFF00D4AA),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: mostrarDialogEditar,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              color: const Color(0xFF6C63FF).withOpacity(0.12),
                            ),
                            child: const Row(children: [
                              Icon(Icons.edit_rounded, color: Color(0xFF6C63FF), size: 14),
                              SizedBox(width: 4),
                              Text('Editar',
                                  style: TextStyle(
                                      color: Color(0xFF6C63FF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Colors.white.withOpacity(0.07), height: 1),
                ),

                // ── Correo electrónico ──────────────────────────────────
                ListenableBuilder(
                  listenable: SaldoService.instancia,
                  builder: (_, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Correo electrónico',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text(
                        TokenStore.email,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}