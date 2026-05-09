package com.unimag.modulo_transferencia.dto;

import jakarta.validation.constraints.*;
import lombok.Data;

// ── AUTH ──

public class AuthDTO {

    @Data
    public static class LoginRequest {
        @NotBlank(message = "El email es obligatorio")
        @Email(message = "Email inválido")
        private String email;

        @NotBlank(message = "La contraseña es obligatoria")
        private String password;
    }

    @Data
    public static class RegisterRequest {
        @NotBlank(message = "El nombre es obligatorio")
        private String nombre;

        @NotBlank(message = "El apellido es obligatorio")
        private String apellido;

        @NotBlank(message = "El email es obligatorio")
        @Email(message = "Email inválido")
        private String email;

        @NotBlank(message = "La contraseña es obligatoria")
        @Size(min = 6, message = "La contraseña debe tener mínimo 6 caracteres")
        private String password;
    }

    @Data
    public static class LoginResponse {
        private String token;
        private String numeroCuenta;
        private String nombre;
        private String apellido;
        private String email;
        private Double saldo;
    }

    // ── NUEVO: Request para login con token externo ───────────────────────
    @Data
    public static class TokenExternoRequest {
        @NotBlank(message = "El tokenApp es obligatorio")
        private String tokenApp;
    }
}