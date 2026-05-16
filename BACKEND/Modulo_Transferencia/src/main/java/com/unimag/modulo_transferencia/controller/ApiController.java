package com.unimag.modulo_transferencia.controller;

import com.unimag.modulo_transferencia.entity.Cuenta;
import com.unimag.modulo_transferencia.entity.Movimiento;
import com.unimag.modulo_transferencia.entity.Usuario;
import com.unimag.modulo_transferencia.repository.CuentaRepository;
import com.unimag.modulo_transferencia.repository.UsuarioRepository;
import com.unimag.modulo_transferencia.service.TransferenciaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class ApiController {

    private final UsuarioRepository    usuarioRepository;
    private final CuentaRepository     cuentaRepository;
    private final TransferenciaService transferenciaService;

    // ── Obtener usuario autenticado ───────────────────────────────────────
    private Usuario getUsuario(Authentication auth) {
        return usuarioRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));
    }

    // ── Obtener cuenta del usuario por cuentaId (valida pertenencia) ──────
    private Cuenta getCuentaById(Usuario usuario, Long cuentaId) {
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new RuntimeException("Cuenta no encontrada"));
        if (!cuenta.getUsuario().getId().equals(usuario.getId()))
            throw new RuntimeException("La cuenta no pertenece al usuario");
        return cuenta;
    }

    // ── PERFIL ────────────────────────────────────────────────────────────
    @GetMapping("/usuario/perfil")
    public ResponseEntity<Map<String, Object>> perfil(Authentication auth) {
        Usuario u = getUsuario(auth);
        java.util.List<Cuenta> cuentas = cuentaRepository.findAllByUsuario(u);
        Map<String, Object> resp = new HashMap<>();
        resp.put("nombre",   u.getNombre());
        resp.put("apellido", u.getApellido());
        resp.put("email",    u.getEmail());
        resp.put("cuentas",  cuentas.stream().map(c -> {
            Map<String, Object> m = new HashMap<>();
            m.put("id",           c.getId());
            m.put("numeroCuenta", c.getNumeroCuenta());
            m.put("saldo",        c.getSaldo());
            return m;
        }).collect(Collectors.toList()));
        return ResponseEntity.ok(resp);
    }

    // ── SALDO de cuenta específica ────────────────────────────────────────
    @GetMapping("/usuario/saldo")
    public ResponseEntity<Map<String, Object>> saldo(
            @RequestParam Long cuentaId,
            Authentication auth) {
        Usuario u = getUsuario(auth);
        Cuenta  c = getCuentaById(u, cuentaId);
        Map<String, Object> resp = new HashMap<>();
        resp.put("cuentaId", c.getId());
        resp.put("saldo",    c.getSaldo());
        return ResponseEntity.ok(resp);
    }

    // ── TRANSFERENCIA ─────────────────────────────────────────────────────
    @PostMapping("/transferencias")
    public ResponseEntity<Map<String, Object>> transferir(
            @RequestBody TransferenciaRequest req,
            Authentication auth) {
        Usuario origen      = getUsuario(auth);
        Cuenta  cuentaOrigen = getCuentaById(origen, req.getCuentaOrigenId());
        Map<String, Object> resultado = transferenciaService.realizarTransferencia(
                cuentaOrigen, req.getCuentaDestino(), req.getMonto(), req.getConcepto());
        return ResponseEntity.ok(resultado);
    }

    // ── RECARGA ───────────────────────────────────────────────────────────
    @PostMapping("/recargas")
    public ResponseEntity<Map<String, Object>> recargar(
            @RequestBody RecargaRequest req,
            Authentication auth) {
        Usuario usuario      = getUsuario(auth);
        Cuenta  cuentaOrigen = getCuentaById(usuario, req.getCuentaOrigenId());
        Map<String, Object> resultado = transferenciaService.realizarRecarga(
                cuentaOrigen, req.getMonto(), req.getMetodoPago(), req.getCuentaDestino());
        return ResponseEntity.ok(resultado);
    }

    // ── HISTORIAL de cuenta específica ────────────────────────────────────
    @GetMapping("/transferencias/historial")
    public ResponseEntity<List<Map<String, Object>>> historial(
            @RequestParam Long cuentaId,
            Authentication auth) {
        Usuario usuario = getUsuario(auth);
        Cuenta  cuenta  = getCuentaById(usuario, cuentaId);
        return ResponseEntity.ok(mapearMovimientos(transferenciaService.obtenerTodos(cuenta)));
    }

    // ── HISTORIAL DE HOY de cuenta específica ─────────────────────────────
    @GetMapping("/transferencias/historial/hoy")
    public ResponseEntity<List<Map<String, Object>>> historialHoy(
            @RequestParam Long cuentaId,
            Authentication auth) {
        Usuario usuario = getUsuario(auth);
        Cuenta  cuenta  = getCuentaById(usuario, cuentaId);
        return ResponseEntity.ok(mapearMovimientos(transferenciaService.obtenerDeHoy(cuenta)));
    }

    // ── Mapea movimientos a formato que espera Flutter ────────────────────
    private List<Map<String, Object>> mapearMovimientos(List<Movimiento> movimientos) {
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
        LocalDateTime inicioDia = LocalDateTime.now().toLocalDate().atStartOfDay();

        return movimientos.stream().map(m -> {
            Map<String, Object> map = new HashMap<>();
            map.put("referencia",    m.getReferencia());
            map.put("cuentaDestino", m.getCuentaDestino());
            map.put("monto",         m.getMonto());
            map.put("concepto",      m.getConcepto());
            map.put("fechaHora",     m.getFechaHora().format(fmt));
            map.put("estado",        m.getEstado().name().toLowerCase());
            map.put("tipo",          m.getTipo().name().toLowerCase());
            map.put("esHoy",         m.getFechaHora().isAfter(inicioDia));
            return map;
        }).collect(Collectors.toList());
    }
}