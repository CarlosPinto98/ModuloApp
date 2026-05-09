package com.unimag.modulo_transferencia.controller;

import com.unimag.modulo_transferencia.dto.AuthDTO;
import com.unimag.modulo_transferencia.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<AuthDTO.LoginResponse> login(@Valid @RequestBody AuthDTO.LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/registro")
    public ResponseEntity<AuthDTO.LoginResponse> registro(@Valid @RequestBody AuthDTO.RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    // ── NUEVO: Valida el tokenApp externo y devuelve JWT propio ──────────
    // POST /api/auth/token-externo
    // Body: { "tokenApp": "eyJ..." }
    // El backend valida el token con el microservicio externo,
    // busca o crea el usuario en la BD y devuelve su JWT propio.
    @PostMapping("/token-externo")
    public ResponseEntity<AuthDTO.LoginResponse> loginConTokenExterno(
            @RequestBody AuthDTO.TokenExternoRequest request) {
        return ResponseEntity.ok(authService.loginConTokenExterno(request.getTokenApp()));
    }
}