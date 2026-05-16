// ============================================================
//  transferencia_screen.dart
//  Pantalla de transferencias: formulario + confirmación + resultado.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/TransferenciaModels.dart';
import '../service/HistorialService.dart';
import '../service/TransferenciaService.dart';
import '../service/SaldoService.dart';
import '../service/TokenStore.dart';
import '../model/MovimientoItem.dart';
import '../widgets/Resultado.dart';
import '../widgets/MilesFormatter.dart';

class TransferenciaScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  const TransferenciaScreen({super.key, this.onGoHome});

  @override
  State<TransferenciaScreen> createState() => TransferenciaScreenState();
}

class TransferenciaScreenState extends State<TransferenciaScreen> {
  final cuentaCtrl   = TextEditingController();
  final montoCtrl    = TextEditingController();
  final conceptoCtrl = TextEditingController();
  final formKey      = GlobalKey<FormState>();

  bool enviando = false;
  CuentaInfo? get cuentaOrigen => TokenStore.cuentaActiva;

  // ── Montos rápidos ────────────────────────────────────────────────────
  final List<int> montosRapidos = [10000, 20000, 50000, 100000, 200000, 500000];

  @override
  void dispose() {
    cuentaCtrl.dispose();
    montoCtrl.dispose();
    conceptoCtrl.dispose();
    super.dispose();
  }

  static String formatearMonto(double monto) {
    final entero = monto.toStringAsFixed(0);
    return entero.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }

  void seleccionarMontoRapido(int monto) {
    final fmt = monto.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    montoCtrl.value = TextEditingValue(
      text: fmt,
      selection: TextSelection.collapsed(offset: fmt.length),
    );
    setState(() {});
  }

  Future<void> enviarTransferencia() async {
    if (!formKey.currentState!.validate()) return;

    if (cuentaOrigen == null) {
      mostrarSnack('No hay cuenta activa seleccionada', error: true);
      return;
    }

    final montoVal = double.tryParse(montoCtrl.text.replaceAll('.', ''));
    if (montoVal == null || montoVal <= 0) {
      mostrarSnack('Monto inválido', error: true);
      return;
    }

    if (montoVal > SaldoService.instancia.saldo) {
      mostrarSnack('Saldo insuficiente', error: true);
      return;
    }

    final saldoAntes = SaldoService.instancia.saldo;
    SaldoService.instancia.descontar(montoVal);

    setState(() => enviando = true);

    final request = TransferenciaRequest(
      cuentaOrigenId: cuentaOrigen!.id,
      cuentaDestino:  cuentaCtrl.text.trim(),
      monto:          montoVal,
      concepto:       conceptoCtrl.text.trim().isEmpty
          ? 'Transferencia'
          : conceptoCtrl.text.trim(),
    );

    final response = await TransferenciaService.realizarTransferencia(request);

    if (!mounted) return;
    setState(() => enviando = false);

    if (response.exito) {
      HistorialService.instancia.agregar(
        MovimientoItem(
          referencia:    response.referencia,
          cuentaDestino: request.cuentaDestino,
          monto:         formatearMonto(montoVal),
          concepto:      request.concepto,
          fechaHora:     () {
            final n = DateTime.now();
            return 'Hoy, ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
          }(),
          estado: 'Completado',
          tipo:   'Transferencia',
          esHoy:  true,
        ),
      );
      mostrarResultado(exito: true, mensaje: response.mensaje, referencia: response.referencia);
      cuentaCtrl.clear();
      montoCtrl.clear();
      conceptoCtrl.clear();
    } else {
      SaldoService.instancia.setSaldo(saldoAntes);
      mostrarResultado(exito: false, mensaje: response.mensaje, referencia: '');
    }
  }

  void mostrarSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: error ? const Color(0xFFFF5C7A) : const Color(0xFF00D4AA),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void mostrarResultado({required bool exito, required String mensaje, required String referencia}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Resultado(
        exito: exito,
        mensaje: mensaje,
        referencia: referencia,
        onGoHome: widget.onGoHome,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => widget.onGoHome != null ? widget.onGoHome!() : Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
          ),
        ),
        title: const Text('Transferir',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Selector cuenta origen ──────────────────────────────────
            if (TokenStore.cuentas.length > 1) ...[
              label('Cuenta origen'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CuentaInfo>(
                    value: cuentaOrigen,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1A24),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: BorderRadius.circular(14),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
                    items: TokenStore.cuentas.map((c) => DropdownMenuItem(
                      value: c,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(c.numeroCuenta,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          Text('Saldo: \$${c.saldo.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                        ],
                      ),
                    )).toList(),
                    onChanged: (c) {
                      if (c != null) {
                        setState(() {
                          TokenStore.setcuentaActiva(c);
                          SaldoService.instancia.setSaldo(c.saldo);
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Cuenta destino ──────────────────────────────────────────
            label('Cuenta destino'),
            const SizedBox(height: 8),
            inputField(
              controller: cuentaCtrl,
              hint: 'Ej: 1234567890',
              icon: Icons.account_balance_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa la cuenta destino';
                if (v.trim().length < 8)  return 'La cuenta debe tener mínimo 8 dígitos';
                if (v.trim().length > 20) return 'La cuenta no puede tener más de 20 dígitos';
                return null;
              },
            ),

            // ── Montos rápidos ──────────────────────────────────────────
            const SizedBox(height: 20),
            label('Monto rápido'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: montosRapidos.map((v) {
                final lbl = v >= 1000000
                    ? '\$${(v ~/ 1000000)}M'
                    : '\$${(v ~/ 1000)}k';
                final fmtV = v.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
                final seleccionado = montoCtrl.text == fmtV;
                return GestureDetector(
                  onTap: () => seleccionarMontoRapido(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: seleccionado
                          ? const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)])
                          : null,
                      color: seleccionado ? null : Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: seleccionado ? Colors.transparent : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      lbl,
                      style: TextStyle(
                        color: seleccionado ? Colors.white : Colors.white60,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // ── Monto a transferir ──────────────────────────────────────
            const SizedBox(height: 20),
            label('Monto a transferir'),
            const SizedBox(height: 8),
            inputField(
              controller: montoCtrl,
              hint: 'Ej: 500.000',
              icon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [MilesFormatter()],
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa el monto';
                final n = int.tryParse(v.replaceAll('.', '')) ?? 0;
                if (n < 1000)     return 'El monto mínimo es \$1.000';
                if (n > 50000000) return 'El monto máximo es \$50.000.000';
                if (n > SaldoService.instancia.saldo) return 'Saldo insuficiente';
                return null;
              },
            ),

            // ── Concepto ───────────────────────────────────────────────
            const SizedBox(height: 20),
            label('Concepto (opcional)'),
            const SizedBox(height: 8),
            inputField(
              controller: conceptoCtrl,
              hint: 'Ej: Pago arriendo',
              icon: Icons.notes_rounded,
              keyboardType: TextInputType.text,
            ),

            const SizedBox(height: 36),

            // ── Botón transferir ────────────────────────────────────────
            GestureDetector(
              onTap: enviando ? null : enviarTransferencia,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: enviando ? null : const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
                  color: enviando ? Colors.white12 : null,
                ),
                child: Center(
                  child: enviando
                      ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2))
                      : const Text('Transferir',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget label(String text) => Text(text,
      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600));

  Widget inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF5C7A), width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF5C7A), width: 1.5)),
        errorStyle: const TextStyle(color: Color(0xFFFF5C7A)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}