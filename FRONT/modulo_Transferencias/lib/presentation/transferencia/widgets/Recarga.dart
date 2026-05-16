// ============================================================
//  Recarga.dart
//  Bottom sheet para recargar saldo (a cuenta propia o a otro).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../service/SaldoService.dart';
import '../service/TokenStore.dart';
import '../model/TransferenciaModels.dart';

class Recarga extends StatefulWidget {
  final String miCuenta;
  final void Function(double monto, String metodo, String cuentaDestino) onRecargar;

  const Recarga({
    super.key,
    required this.miCuenta,
    required this.onRecargar,
  });

  @override
  State<Recarga> createState() => RecargaState();
}

class RecargaState extends State<Recarga> {
  final formKey    = GlobalKey<FormState>();
  final montoCtrl  = TextEditingController();
  final cuentaCtrl = TextEditingController();
  String montoFmt  = '';
  String metodo    = 'Tarjeta de crédito';
  bool   isLoading = false;
  bool   esPropia  = true;
  CuentaInfo? cuentaOrigen;

  final List<Map<String, dynamic>> metodos = [
    {'label': 'Tarjeta de crédito', 'icon': Icons.credit_card_rounded},
    {'label': 'Tarjeta débito',     'icon': Icons.payment_rounded},
    {'label': 'PSE',                'icon': Icons.account_balance_rounded},
    {'label': 'Efectivo',           'icon': Icons.money_rounded},
  ];

  final List<int> rapidos = [10000, 20000, 50000, 100000, 200000, 500000];

  void formatear(String v) {
    final n = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (n.isEmpty) { setState(() => montoFmt = ''); montoCtrl.clear(); return; }
    String f = '';
    for (int i = 0; i < n.length; i++) {
      if (i > 0 && (n.length - i) % 3 == 0) f += '.';
      f += n[i];
    }
    montoCtrl.value = TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
    setState(() => montoFmt = f);
  }

  String? validarMonto(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa el monto';
    final n = int.tryParse(v.replaceAll('.', '')) ?? 0;
    if (n < 5000)     return 'El monto mínimo de recarga es \$5.000';
    if (n > 10000000) return 'El monto máximo de recarga es \$10.000.000';
    if (!esPropia && n > SaldoService.instancia.saldo) {
      return 'Saldo insuficiente';
    }
    return null;
  }

  String? validarCuenta(String? v) {
    if (esPropia) return null;
    if (v == null || v.trim().isEmpty) return 'Ingresa el número de cuenta';
    if (v.trim().length < 8)  return 'La cuenta debe tener mínimo 8 dígitos';
    if (v.trim().length > 20) return 'La cuenta no puede tener más de 20 dígitos';
    return null;
  }

  Future<void> confirmar() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => isLoading = false);
    final monto   = double.parse(montoFmt.replaceAll('.', ''));
    final destino = esPropia ? widget.miCuenta : cuentaCtrl.text.trim();
    widget.onRecargar(monto, metodo, destino);
  }

  @override
  void initState() {
    super.initState();
    cuentaOrigen = TokenStore.cuentaActiva;
  }

  @override
  void dispose() { montoCtrl.dispose(); cuentaCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // ── Handle y título ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 36, height: 4,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    Row(children: [
                      Container(width: 40, height: 40,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00D4AA).withOpacity(0.15)),
                          child: const Icon(Icons.bolt_rounded, color: Color(0xFF00D4AA), size: 22)),
                      const SizedBox(width: 12),
                      const Text('Recargar saldo',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 16),

                    // ── Selector cuenta origen (si tiene más de 1) ──────
                    if (TokenStore.cuentas.length > 1) ...[
                      Text('Cuenta origen',
                          style: TextStyle(color: Colors.white.withOpacity(0.5),
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<CuentaInfo>(
                            value: cuentaOrigen,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1A1A24),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            borderRadius: BorderRadius.circular(12),
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
                                  cuentaOrigen = c;
                                  TokenStore.setcuentaActiva(c);
                                  SaldoService.instancia.setSaldo(c.saldo);
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Selector: Cuenta propia / A otro ───────────────
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(children: [
                        tabSelector('Mi cuenta', true),
                        tabSelector('A otro usuario', false),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // // ── Mi número de cuenta (solo lectura) ─────────────
                    // if (esPropia)
                    //   AnimatedSize(
                    //     duration: const Duration(milliseconds: 200),
                    //     child: Container(
                    //       width: double.infinity,
                    //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    //       decoration: BoxDecoration(
                    //         borderRadius: BorderRadius.circular(12),
                    //         color: const Color(0xFF00D4AA).withOpacity(0.08),
                    //         border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.3)),
                    //       ),
                    //       child: Row(
                    //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //         children: [
                    //           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    //             Text('Mi número de cuenta',
                    //                 style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w500)),
                    //             const SizedBox(height: 4),
                    //             Text(widget.miCuenta,
                    //                 style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    //           ]),
                    //           GestureDetector(
                    //             onTap: () {
                    //               Clipboard.setData(ClipboardData(text: widget.miCuenta));
                    //               ScaffoldMessenger.of(context).showSnackBar(
                    //                 SnackBar(
                    //                   content: const Row(children: [
                    //                     Icon(Icons.copy_rounded, color: Color(0xFF00D4AA), size: 16),
                    //                     SizedBox(width: 8),
                    //                     Text('Número copiado', style: TextStyle(color: Colors.white)),
                    //                   ]),
                    //                   backgroundColor: const Color(0xFF13131A),
                    //                   behavior: SnackBarBehavior.floating,
                    //                   duration: const Duration(seconds: 2),
                    //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    //                 ),
                    //               );
                    //             },
                    //             child: Container(
                    //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    //               decoration: BoxDecoration(
                    //                 borderRadius: BorderRadius.circular(8),
                    //                 color: const Color(0xFF00D4AA).withOpacity(0.15),
                    //               ),
                    //               child: const Row(children: [
                    //                 Icon(Icons.copy_rounded, color: Color(0xFF00D4AA), size: 14),
                    //                 SizedBox(width: 4),
                    //                 Text('Copiar', style: TextStyle(color: Color(0xFF00D4AA), fontSize: 12, fontWeight: FontWeight.w600)),
                    //               ]),
                    //             ),
                    //           ),
                    //         ],
                    //       ),
                    //     ),
                    //   ),const SizedBox(height: 16)

                    // ── Campo cuenta destino (solo si es a otro) ────────
                    if (!esPropia)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Número de cuenta destino',
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: cuentaCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              validator: validarCuenta,
                              decoration: InputDecoration(
                                hintText: 'Ej: 0012345678',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                                prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.white38, size: 20),
                                errorStyle: const TextStyle(color: Color(0xFFFF5C7A), fontSize: 12),
                                filled: true, fillColor: Colors.white.withOpacity(0.05),
                                border:             OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                                enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                                focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5)),
                                errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF5C7A))),
                                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF5C7A), width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ── Contenido scrolleable ───────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monto rápido',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: rapidos.map((v) {
                          final lbl = v >= 1000000 ? '\$${(v ~/ 1000000)}M' : '\$${(v ~/ 1000)}k';
                          final sel = montoFmt == v.toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
                          return GestureDetector(
                            onTap: () => formatear(v.toString()),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: sel ? const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]) : null,
                                color: sel ? null : Colors.white.withOpacity(0.06),
                                border: Border.all(color: sel ? Colors.transparent : Colors.white.withOpacity(0.1)),
                              ),
                              child: Text(lbl, style: TextStyle(color: sel ? Colors.white : Colors.white60, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      Text('O Ingresa otro monto',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: montoCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                        validator: validarMonto,
                        onChanged: formatear,
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 20),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text('\$', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 20, fontWeight: FontWeight.w700)),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0),
                          errorStyle: const TextStyle(color: Color(0xFFFF5C7A), fontSize: 12),
                          filled: true, fillColor: Colors.white.withOpacity(0.05),
                          border:             OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                          enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                          focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 1.5)),
                          errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF5C7A))),
                          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF5C7A), width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 18),

                      Text('Método de pago',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: metodo, isExpanded: true,
                            dropdownColor: const Color(0xFF1A1A24),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            borderRadius: BorderRadius.circular(12),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
                            items: metodos.map((m) => DropdownMenuItem<String>(
                              value: m['label'] as String,
                              child: Row(children: [
                                Icon(m['icon'] as IconData, color: Colors.white54, size: 18),
                                const SizedBox(width: 10),
                                Text(m['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              ]),
                            )).toList(),
                            onChanged: (v) => setState(() => metodo = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // ── Botón confirmar (fijo abajo) ────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: GestureDetector(
                  onTap: isLoading ? null : confirmar,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity, height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: isLoading
                          ? LinearGradient(colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.08)])
                          : const LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)],
                          begin: Alignment.centerLeft, end: Alignment.centerRight),
                      boxShadow: isLoading ? [] : [BoxShadow(color: const Color(0xFF00D4AA).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Center(
                      child: isLoading
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                        const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text('Procesando...', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 15, fontWeight: FontWeight.w600)),
                      ])
                          : const Text('Confirmar recarga',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget tabSelector(String label, bool value) {
    final sel = esPropia == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { esPropia = value; cuentaCtrl.clear(); }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: sel ? const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]) : null,
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  color: sel ? Colors.white : Colors.white38,
                  fontSize: 13, fontWeight: FontWeight.w600,
                )),
          ),
        ),
      ),
    );
  }
}