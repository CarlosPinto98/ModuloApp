package com.unimag.modulo_transferencia.controller;

import com.unimag.modulo_transferencia.model.Movimiento;
import com.unimag.modulo_transferencia.model.Usuario;
import com.unimag.modulo_transferencia.repository.UsuarioRepository;
import com.unimag.modulo_transferencia.service.TransferenciaService;
import jakarta.validation.constraints.*;
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

    private final UsuarioRepository usuarioRepository;
    private final TransferenciaService transferenciaService;

    // ── Obtener usuario autenticado ───────────────────────────────────────
    private Usuario getUsuario(Authentication auth) {
        return usuarioRepository.findByEmail(auth.getName())
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));
    }

    // ── PERFIL ────────────────────────────────────────────────────────────
    @GetMapping("/usuario/perfil")
    public ResponseEntity<Map<String, Object>> perfil(Authentication auth) {
        Usuario u = getUsuario(auth);
        Map<String, Object> resp = new HashMap<>();
        resp.put("numeroCuenta", u.getNumeroCuenta());
        resp.put("nombre",       u.getNombre());
        resp.put("apellido",     u.getApellido());
        resp.put("email",        u.getEmail());
        resp.put("saldo",        u.getSaldo());
        return ResponseEntity.ok(resp);
    }

    // ── SALDO ─────────────────────────────────────────────────────────────
    @GetMapping("/usuario/saldo")
    public ResponseEntity<Map<String, Object>> saldo(Authentication auth) {
        Usuario u = getUsuario(auth);
        Map<String, Object> resp = new HashMap<>();
        resp.put("saldo", u.getSaldo());
        return ResponseEntity.ok(resp);
    }

    // ── TRANSFERENCIA ─────────────────────────────────────────────────────
    @PostMapping("/transferencias")
    public ResponseEntity<Map<String, Object>> transferir(
            @RequestBody TransferenciaRequest req,
            Authentication auth) {
        Usuario origen = getUsuario(auth);
        Map<String, Object> resultado = transferenciaService.realizarTransferencia(
                origen, req.getCuentaDestino(), req.getMonto(), req.getConcepto());
        return ResponseEntity.ok(resultado);
    }

    // ── RECARGA ───────────────────────────────────────────────────────────
    @PostMapping("/recargas")
    public ResponseEntity<Map<String, Object>> recargar(
            @RequestBody RecargaRequest req,
            Authentication auth) {
        Usuario usuario = getUsuario(auth);
        Map<String, Object> resultado = transferenciaService.realizarRecarga(
                usuario, req.getMonto(), req.getMetodoPago(), req.getCuentaDestino());
        return ResponseEntity.ok(resultado);
    }

    // ── HISTORIAL COMPLETO ────────────────────────────────────────────────
    @GetMapping("/transferencias/historial")
    public ResponseEntity<List<Map<String, Object>>> historial(Authentication auth) {
        Usuario usuario = getUsuario(auth);
        List<Movimiento> movimientos = transferenciaService.obtenerTodos(usuario);
        return ResponseEntity.ok(mapearMovimientos(movimientos));
    }

    // ── HISTORIAL DE HOY ──────────────────────────────────────────────────
    @GetMapping("/transferencias/historial/hoy")
    public ResponseEntity<List<Map<String, Object>>> historialHoy(Authentication auth) {
        Usuario usuario = getUsuario(auth);
        List<Movimiento> movimientos = transferenciaService.obtenerDeHoy(usuario);
        return ResponseEntity.ok(mapearMovimientos(movimientos));
    }

    // ── Mapea movimientos a formato que espera Flutter ────────────────────
    // FIX: reemplazado Map.of() por HashMap para evitar error de tipos genéricos
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
