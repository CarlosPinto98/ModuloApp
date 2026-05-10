import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/MovimientoItem.dart';
import '../service/HistorialService.dart';

class MovimientosScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  const MovimientosScreen({super.key, this.onGoHome});

  @override
  State<MovimientosScreen> createState() => MovimientosScreenState();
}

class MovimientosScreenState extends State<MovimientosScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  final TextEditingController searchCtrl = TextEditingController();
  String filtroBusqueda = '';
  String filtroTipo     = 'todos'; // 'todos' | 'transferencia' | 'recarga'

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    HistorialService.instancia.addListener(onCambio);
    HistorialService.instancia.cargarDesdeBackend();
    searchCtrl.addListener(() {
      setState(() => filtroBusqueda = searchCtrl.text.trim().toLowerCase());
    });
  }

  void onCambio() => setState(() {});

  @override
  void dispose() {
    tabController.dispose();
    searchCtrl.dispose();
    HistorialService.instancia.removeListener(onCambio);
    super.dispose();
  }

  List<MovimientoItem> aplicarFiltros(List<MovimientoItem> lista) {
    return lista.where((m) {
      final coincideTipo = filtroTipo == 'todos' || m.tipo == filtroTipo;
      final coincideBusqueda = filtroBusqueda.isEmpty ||
          m.referencia.toLowerCase().contains(filtroBusqueda) ||
          m.cuentaDestino.toLowerCase().contains(filtroBusqueda) ||
          m.tipo.toLowerCase().contains(filtroBusqueda) ||
          m.concepto.toLowerCase().contains(filtroBusqueda);
      return coincideTipo && coincideBusqueda;
    }).toList();
  }

  void mostrarDetalle(BuildContext context, MovimientoItem m) {
    final esRecarga = m.tipo == 'recarga';
    final esFallido = m.estado == 'fallido';
    final Color colorPrincipal = esFallido
        ? const Color(0xFFFF5C7A)
        : esRecarga
        ? const Color(0xFF00D4AA)
        : const Color(0xFF6C63FF);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF13131A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorPrincipal.withOpacity(0.15),
                border: Border.all(color: colorPrincipal.withOpacity(0.3)),
              ),
              child: Icon(
                esFallido
                    ? Icons.error_outline_rounded
                    : esRecarga
                    ? Icons.bolt_rounded
                    : Icons.swap_horiz_rounded,
                color: colorPrincipal, size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${esRecarga ? '+' : '-'}\$${m.monto}',
              style: TextStyle(
                color: colorPrincipal, fontSize: 32,
                fontWeight: FontWeight.w800, letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colorPrincipal.withOpacity(0.15),
              ),
              child: Text(
                m.estado.toUpperCase(),
                style: TextStyle(
                  color: colorPrincipal, fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  filaDetalle('Tipo', esRecarga ? 'Recarga' : 'Transferencia', Icons.category_outlined),
                  divider(),
                  filaDetalle('Concepto', m.concepto, Icons.notes_rounded),
                  divider(),
                  filaDetalle('Cuenta destino', m.cuentaDestino, Icons.account_balance_outlined),
                  divider(),
                  filaDetalle('Fecha y hora', m.fechaHora, Icons.access_time_rounded),
                  divider(),
                  filaDetalleConCopia('Referencia', m.referencia, context),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity, height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Center(
                    child: Text('Cerrar',
                        style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget filaDetalle(String label, String valor, IconData icono) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withOpacity(0.05),
            ),
            child: Icon(icono, color: Colors.white38, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(valor, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget filaDetalleConCopia(String label, String valor, BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withOpacity(0.05),
            ),
            child: const Icon(Icons.tag_rounded, color: Colors.white38, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(valor, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: valor));
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: const Row(children: [
                  Icon(Icons.copy_rounded, color: Color(0xFF00D4AA), size: 16),
                  SizedBox(width: 8),
                  Text('Referencia copiada', style: TextStyle(color: Colors.white)),
                ]),
                backgroundColor: const Color(0xFF13131A),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF00D4AA).withOpacity(0.1),
              ),
              child: const Row(children: [
                Icon(Icons.copy_rounded, color: Color(0xFF00D4AA), size: 13),
                SizedBox(width: 4),
                Text('Copiar', style: TextStyle(color: Color(0xFF00D4AA), fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget divider() => Divider(color: Colors.white.withOpacity(0.06), height: 1);

  Widget chipTipo(String label, String valor) {
    final sel = filtroTipo == valor;
    return GestureDetector(
      onTap: () => setState(() => filtroTipo = valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: sel
              ? const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)])
              : null,
          color: sel ? null : Colors.white.withOpacity(0.06),
          border: Border.all(
            color: sel ? Colors.transparent : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? Colors.white : Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget listaMovimientos(List<MovimientoItem> lista) {
    final filtrados = aplicarFiltros(lista);
    if (filtrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: Colors.white.withOpacity(0.2), size: 52),
            const SizedBox(height: 12),
            Text('Sin resultados',
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: filtrados.length,
      itemBuilder: (_, i) {
        final m = filtrados[i];
        final esRecarga = m.tipo == 'recarga';
        final esFallido = m.estado == 'fallido';
        return GestureDetector(
          onTap: () => mostrarDetalle(context, m),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: esFallido
                        ? const Color(0xFFFF5C7A).withOpacity(0.15)
                        : esRecarga
                        ? const Color(0xFF00D4AA).withOpacity(0.15)
                        : const Color(0xFF6C63FF).withOpacity(0.15),
                  ),
                  child: Icon(
                    esFallido
                        ? Icons.error_outline_rounded
                        : esRecarga
                        ? Icons.bolt_rounded
                        : Icons.swap_horiz_rounded,
                    color: esFallido
                        ? const Color(0xFFFF5C7A)
                        : esRecarga
                        ? const Color(0xFF00D4AA)
                        : const Color(0xFF6C63FF),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.concepto,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(m.fechaHora,
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${esRecarga ? '+' : '-'}\$${m.monto}',
                      style: TextStyle(
                        color: esFallido
                            ? const Color(0xFFFF5C7A)
                            : esRecarga
                            ? const Color(0xFF00D4AA)
                            : Colors.white,
                        fontSize: 15, fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: esFallido
                            ? const Color(0xFFFF5C7A).withOpacity(0.15)
                            : const Color(0xFF00D4AA).withOpacity(0.15),
                      ),
                      child: Text(m.estado,
                          style: TextStyle(
                            color: esFallido ? const Color(0xFFFF5C7A) : const Color(0xFF00D4AA),
                            fontSize: 10, fontWeight: FontWeight.w600,
                          )),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.2), size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final todos  = HistorialService.instancia.todos;
    final deHoy  = HistorialService.instancia.deHoy;
    final cargando = HistorialService.instancia.cargando;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: const Text(
                'Movimientos',
                style: TextStyle(
                  color: Colors.white, fontSize: 24,
                  fontWeight: FontWeight.w800, letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Buscador ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar por cuenta, referencia o concepto...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                    suffixIcon: filtroBusqueda.isNotEmpty
                        ? GestureDetector(
                      onTap: () { searchCtrl.clear(); setState(() => filtroBusqueda = ''); },
                      child: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Chips de tipo ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    chipTipo('Todos', 'todos'),
                    chipTipo('Transferencias', 'transferencia'),
                    chipTipo('Recargas', 'recarga'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tabs Hoy / Todos ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TabBar(
                  controller: tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)],
                    ),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(text: 'Hoy (${aplicarFiltros(deHoy).length})'),
                    Tab(text: 'Todos (${aplicarFiltros(todos).length})'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Contenido ─────────────────────────────────────────────
            Expanded(
              child: cargando
                  ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
              )
                  : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TabBarView(
                  controller: tabController,
                  children: [
                    listaMovimientos(deHoy),
                    listaMovimientos(todos),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
