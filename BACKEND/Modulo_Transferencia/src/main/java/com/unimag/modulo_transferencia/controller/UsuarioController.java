package com.unimag.modulo_transferencia.controller;

import com.unimag.modulo_transferencia.dto.ActualizarCuentaRequest;
import com.unimag.modulo_transferencia.dto.ActualizarCuentaResponse;

import com.unimag.modulo_transferencia.service.UsuarioService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;

@RestController
@RequestMapping("/api/usuario")
public class UsuarioController {

    private final UsuarioService usuarioService;

    public UsuarioController(UsuarioService usuarioService) {
        this.usuarioService = usuarioService;
    }

    @PutMapping("/cuenta")
    public ResponseEntity<ActualizarCuentaResponse> actualizarCuenta(
            @RequestBody ActualizarCuentaRequest request,
            Principal principal) {

        // principal.getName() devuelve el email del JWT autenticado
        ActualizarCuentaResponse response =
                usuarioService.actualizarNumeroCuenta(principal.getName(), request);

        if (response.isExito()) {
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.badRequest().body(response);
        }
    }
}
