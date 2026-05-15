// ============================================================
//  MainScreen.dart
//  Pantalla principal con navbar, saldo y recarga.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'TransferenciaScreen.dart';
import 'MovimientosScreen.dart';
import '../service/HistorialService.dart';
import '../service/SaldoService.dart';
import '../service/TransferenciaService.dart';
import '../service/TokenStore.dart';
import '../widgets/HomeContent.dart';
import '../widgets/NotificacionesContent.dart';
import '../widgets/PerfilContent.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController animController;
  late Animation<double> fadeAnim;
  int selectedIndex = 0;
  Timer? refreshTimer;

  final List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.grid_view_rounded,      'label': 'Inicio'},
    {'icon': Icons.swap_horiz_rounded,     'label': 'Transferir'},
    {'icon': Icons.receipt_long_rounded,   'label': 'Movimientos'},
    {'icon': Icons.notifications_outlined, 'label': 'Notificaciones'},
    {'icon': Icons.person_outline_rounded, 'label': 'Perfil'},
  ];

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    fadeAnim = CurvedAnimation(parent: animController, curve: Curves.easeOut);
    animController.forward();

    TokenStore.cargarDesdePrefs().then((_) async {
      // ── Extraer foto del token externo ────────────────────────────
      if (TokenStore.token != null) {
        TokenStore.extraerDatosToken(TokenStore.token!);
      }
      final loginData = await TransferenciaService.loginConTokenExterno();
      if (loginData != null) {
        SaldoService.instancia.setSaldo(loginData.saldo);
        TokenStore.nombre        = loginData.nombre;
        TokenStore.apellido      = loginData.apellido;
        TokenStore.email         = loginData.email;
        TokenStore.numeroCuenta  = loginData.numeroCuenta;
        setState(() {});
      } else {
        SaldoService.instancia.sincronizarConBackend();
      }
      HistorialService.instancia.cargarHoyDesdeBackend();

      // ── Refresco automático cada 15 segundos ──────────────────────
      refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        SaldoService.instancia.sincronizarConBackend();
        HistorialService.instancia.refrescarHoySilencioso();
      });
    });

    screens = [
      const HomeContent(),
      TransferenciaScreen(onGoHome: () => setState(() => selectedIndex = 0)),
      MovimientosScreen(onGoHome: () => setState(() => selectedIndex = 0)),
      const NotificacionesContent(),
      const PerfilContent(),
    ];
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    animController.dispose();
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
              ),
              child: const Text('Salir',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop && selectedIndex != 0) {
          setState(() => selectedIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: FadeTransition(
          opacity: fadeAnim,
          child: SafeArea(
            child: Column(
              children: [

                // ── HEADER (solo visible en Inicio) ──────────────────
                if (selectedIndex == 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        // ── Saludo + Nombre ───────────────────────────
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Buen día 👋',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              ListenableBuilder(
                                listenable: SaldoService.instancia,
                                builder: (_, __) => Text(
                                  '${TokenStore.nombre} ${TokenStore.apellido}'.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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

                        // ── Botones notificación y logout ─────────────
                        Row(
                          children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white.withOpacity(0.06),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              child: const Icon(Icons.notifications_outlined,
                                  color: Colors.white70, size: 20),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: handleLogout,
                              child: Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(Icons.logout_rounded,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: screens[selectedIndex],
                ),

                // ── BOTTOM NAVIGATION BAR ─────────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: List.generate(menuItems.length, (i) {
                        final isSelected = selectedIndex == i;
                        return GestureDetector(
                          onTap: () => setState(() => selectedIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: isSelected
                                  ? const LinearGradient(
                                  colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)])
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(menuItems[i]['icon'] as IconData,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white38,
                                    size: 20),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                  child: isSelected
                                      ? Row(children: [
                                    const SizedBox(width: 6),
                                    Text(menuItems[i]['label'] as String,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                  ])
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}