package com.unimag.modulo_transferencia.service;

import com.unimag.modulo_transferencia.dto.AuthDTO;
import com.unimag.modulo_transferencia.model.Usuario;
import com.unimag.modulo_transferencia.repository.UsuarioRepository;
import com.unimag.modulo_transferencia.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UsuarioRepository     usuarioRepository;
    private final JwtService            jwtService;
    private final PasswordEncoder       passwordEncoder;
    private final AuthenticationManager authenticationManager;

    // ── URL del microservicio externo para validar el tokenApp ────────────
    private static final String URL_VALIDAR_TOKEN =
            "https://mriai.coreunimag.com/api/auth/validate-token";

    public AuthDTO.LoginResponse login(AuthDTO.LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        Usuario usuario = usuarioRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        String token = jwtService.generarToken(usuario.getEmail());

        AuthDTO.LoginResponse response = new AuthDTO.LoginResponse();
        response.setToken(token);
        response.setNumeroCuenta(usuario.getNumeroCuenta());
        response.setNombre(usuario.getNombre());
        response.setApellido(usuario.getApellido());
        response.setEmail(usuario.getEmail());
        response.setSaldo(usuario.getSaldo());
        return response;
    }

    public AuthDTO.LoginResponse register(AuthDTO.RegisterRequest request) {
        if (usuarioRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("El email ya está registrado");
        }

        Usuario usuario = Usuario.builder()
                .nombre(request.getNombre())
                .apellido(request.getApellido())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .numeroCuenta(generarNumeroCuenta())
                .saldo(0.0)
                .build();

        usuarioRepository.save(usuario);

        String token = jwtService.generarToken(usuario.getEmail());

        AuthDTO.LoginResponse response = new AuthDTO.LoginResponse();
        response.setToken(token);
        response.setNumeroCuenta(usuario.getNumeroCuenta());
        response.setNombre(usuario.getNombre());
        response.setApellido(usuario.getApellido());
        response.setEmail(usuario.getEmail());
        response.setSaldo(usuario.getSaldo());
        return response;
    }

    // ── NUEVO: Login con tokenApp externo (Pay School Snacks) ─────────────
    // 1. Decodifica el JWT externo para extraer el email (sub)
    // 2. Busca el usuario en la BD por ese email
    // 3. Si no existe, lo crea automáticamente
    // 4. Devuelve un JWT propio del backend
    public AuthDTO.LoginResponse loginConTokenExterno(String tokenApp) {
        try {
            // ── Decodificar el JWT externo sin verificar firma ──────────
            // El token tiene formato: header.payload.signature
            // Decodificamos el payload (base64) para extraer el email
            String[] partes  = tokenApp.split("\\.");
            if (partes.length < 2) {
                throw new RuntimeException("Token externo inválido");
            }

            // Decodificar el payload en base64
            String payloadBase64 = partes[1];
            // Añadir padding si es necesario
            int mod = payloadBase64.length() % 4;
            if (mod != 0) payloadBase64 += "=".repeat(4 - mod);

            byte[]     payloadBytes = java.util.Base64.getUrlDecoder().decode(payloadBase64);
            String     payloadJson  = new String(payloadBytes);

            ObjectMapper mapper = new ObjectMapper();
            JsonNode    payload = mapper.readTree(payloadJson);

            // ── Extraer el email del campo "sub" ────────────────────────
            // El token de Pay School Snacks usa "sub" con el identificador
            // Ejemplo: "pendiente_177755885695@tmp.com" o el email real
            String sub = payload.has("sub") ? payload.get("sub").asText() : null;

            if (sub == null || sub.isBlank()) {
                throw new RuntimeException("No se pudo extraer el identificador del token");
            }

            // ── Verificar que el token no esté expirado ─────────────────
            if (payload.has("exp")) {
                long exp     = payload.get("exp").asLong();
                long ahoraMs = System.currentTimeMillis() / 1000;
                if (ahoraMs > exp) {
                    throw new RuntimeException("El tokenApp ha expirado");
                }
            }

            // ── Extraer nombre y apellido del token si están disponibles ─
            String nombre   = payload.has("nombres")   ? payload.get("nombres").asText()   : "Usuario";
            String apellido = payload.has("apellidos")  ? payload.get("apellidos").asText()  : "App";

            // ── Buscar o crear el usuario en la BD ──────────────────────
            // Usamos el "sub" como email identificador único
            Usuario usuario = usuarioRepository.findByEmail(sub).orElseGet(() -> {
                // Crear usuario nuevo con el identificador del token externo
                Usuario nuevo = Usuario.builder()
                        .nombre(nombre)
                        .apellido(apellido)
                        .email(sub)
                        .password(passwordEncoder.encode(tokenApp.substring(0, 20)))
                        .numeroCuenta(generarNumeroCuenta())
                        .saldo(50000.0) // saldo inicial
                        .build();
                return usuarioRepository.save(nuevo);
            });

            // ── Generar JWT propio del backend ──────────────────────────
            String jwtPropio = jwtService.generarToken(usuario.getEmail());

            AuthDTO.LoginResponse response = new AuthDTO.LoginResponse();
            response.setToken(jwtPropio);
            response.setNumeroCuenta(usuario.getNumeroCuenta());
            response.setNombre(usuario.getNombre());
            response.setApellido(usuario.getApellido());
            response.setEmail(usuario.getEmail());
            response.setSaldo(usuario.getSaldo());
            return response;

        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException("Error al procesar el token externo: " + e.getMessage());
        }
    }

    // ── Genera número de cuenta único de 10 dígitos ───────────────────────
    private String generarNumeroCuenta() {
        String cuenta;
        do {
            cuenta = String.format("%010d",
                    (long)(Math.random() * 9_000_000_000L) + 1_000_000_000L);
        } while (usuarioRepository.existsByNumeroCuenta(cuenta));
        return cuenta;
    }
}