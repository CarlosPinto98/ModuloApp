// ============================================================
//  HomeContent.dart
//  Pantalla de inicio con saldo y acceso a recarga.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../service/SaldoService.dart';
import '../service/HistorialService.dart';
import '../service/TransferenciaService.dart';
import '../model/MovimientoItem.dart';
import 'Recarga.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent> {
  bool saldoVisible = true;
  double get saldo => SaldoService.instancia.saldo;

  // TODO: reemplazar con el número de cuenta real que venga del backend (módulo Auth)
  final String miCuenta = '0012345678';

  final List<Map<String, dynamic>> cards = [
    {
      'title': 'Bonos activos', 'value': '\$3,200', 'change': '+12%',
      'positive': true, 'icon': Icons.card_giftcard_rounded, 'color': const Color(0xFF6C63FF),
    },
  ];

  @override
  void initState() {
    super.initState();
    SaldoService.instancia.addListener(onSaldoCambio);
  }

  void onSaldoCambio() => setState(() {});

  @override
  void dispose() {
    SaldoService.instancia.removeListener(onSaldoCambio);
    super.dispose();
  }

  void handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(color: Colors.white.withOpacity(0.55))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.white.withOpacity(0.4))),
          ),
          GestureDetector(
            onTap: () { Navigator.pop(context); SystemNavigator.pop(); },
            child: Container(
              margin: const EdgeInsets.only(right: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
              ),
              child: const Text('Salir',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void mostrarRecarga() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Recarga(
        miCuenta: miCuenta,
        onRecargar: (double monto, String metodo, String cuentaDestino) {
          Navigator.pop(context);

          final esPropia = cuentaDestino == miCuenta;

          HistorialService.instancia.agregar(
            MovimientoItem(
              referencia:    'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
              cuentaDestino: esPropia ? 'Cuenta propia' : cuentaDestino,
              monto:         monto.toStringAsFixed(0).replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.'),
              concepto:      esPropia ? 'Recarga - $metodo' : 'Recarga a $cuentaDestino - $metodo',
              fechaHora:     () {
                final n = DateTime.now();
                return 'Hoy, ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
              }(),
              estado: 'completado',
              tipo:   'recarga',
              esHoy:  true,
            ),
          );

          // ✅ ACTUALIZACION OPTIMISTA: cambia el saldo YA, sin esperar al backend
          final saldoAntes = SaldoService.instancia.saldo;
          if (esPropia) {
            SaldoService.instancia.recargar(monto);
          } else {
            SaldoService.instancia.descontar(monto);
          }

          // Confirma con el backend en segundo plano
          TransferenciaService.realizarRecarga(
            monto:         monto,
            metodoPago:    metodo,
            cuentaDestino: esPropia ? null : cuentaDestino,
          ).then((res) {
            final nuevoSaldo = res['nuevoSaldo'];
            if (nuevoSaldo != null) {
              SaldoService.instancia.setSaldo((nuevoSaldo as num).toDouble());
            }
          }).catchError((_) {
            // Si falla el backend, REVERTIR el saldo al valor anterior
            SaldoService.instancia.setSaldo(saldoAntes);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF00D4AA), size: 18),
                SizedBox(width: 10),
                Text('Se ha realizado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
              backgroundColor: const Color(0xFF13131A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saldoFmt = saldo.toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?=\.))'), (m) => '${m[1]},');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saldo Total',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    GestureDetector(
                      onTap: () => setState(() => saldoVisible = !saldoVisible),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          saldoVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          key: ValueKey(saldoVisible), color: Colors.white70, size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    saldoVisible ? '\$$saldoFmt' : '••••••••',
                    key: ValueKey('$saldoVisible$saldo'),
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: mostrarRecarga,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('Recarga', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Servicios',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ...List.generate(cards.length, (i) {
            final c = cards[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        color: (c['color'] as Color).withOpacity(0.15),
                      ),
                      child: Icon(c['icon'] as IconData, color: c['color'] as Color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['title'] as String,
                              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 3),
                          Text(c['value'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: (c['positive'] as bool)
                            ? const Color(0xFF00D4AA).withOpacity(0.15)
                            : const Color(0xFFFF5C7A).withOpacity(0.15),
                      ),
                      child: Text(c['change'] as String,
                          style: TextStyle(
                            color: (c['positive'] as bool) ? const Color(0xFF00D4AA) : const Color(0xFFFF5C7A),
                            fontSize: 13, fontWeight: FontWeight.w700,
                          )),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
