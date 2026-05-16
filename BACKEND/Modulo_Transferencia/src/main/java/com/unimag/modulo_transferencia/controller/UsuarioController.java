package com.unimag.modulo_transferencia.controller;

import com.unimag.modulo_transferencia.dto.ActualizarCuentaRequest;
import com.unimag.modulo_transferencia.dto.ActualizarCuentaResponse;
import com.unimag.modulo_transferencia.service.UsuarioService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.Map;

@RestController
@RequestMapping("/api/usuario")
@RequiredArgsConstructor
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class UsuarioController {

    private final UsuarioService usuarioService;

    // ── Actualizar número de cuenta ───────────────────────────────────────
    @PutMapping("/cuenta")
    public ResponseEntity<ActualizarCuentaResponse> actualizarCuenta(
            @RequestBody ActualizarCuentaRequest request,
            Principal principal) {
        ActualizarCuentaResponse response =
                usuarioService.actualizarNumeroCuenta(principal.getName(), request);
        return response.isExito()
                ? ResponseEntity.ok(response)
                : ResponseEntity.badRequest().body(response);
    }

    // ── Crear nueva cuenta (máximo 3) ─────────────────────────────────────
    @PostMapping("/cuenta")
    public ResponseEntity<Map<String, Object>> crearCuenta(Principal principal) {
        Map<String, Object> resultado = usuarioService.crearCuenta(principal.getName());
        boolean exito = Boolean.TRUE.equals(resultado.get("exito"));
        return exito
                ? ResponseEntity.ok(resultado)
                : ResponseEntity.badRequest().body(resultado);
    }

    // ── Eliminar cuenta ───────────────────────────────────────────────────
    @DeleteMapping("/cuenta/{cuentaId}")
    public ResponseEntity<Map<String, Object>> eliminarCuenta(
            @PathVariable Long cuentaId,
            Principal principal) {
        Map<String, Object> resultado = usuarioService.eliminarCuenta(principal.getName(), cuentaId);
        boolean exito = Boolean.TRUE.equals(resultado.get("exito"));
        return exito
                ? ResponseEntity.ok(resultado)
                : ResponseEntity.badRequest().body(resultado);
    }
}