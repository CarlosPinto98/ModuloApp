package com.unimag.modulo_transferencia.service;

import com.unimag.modulo_transferencia.dto.AuthDTO;
import com.unimag.modulo_transferencia.entity.Cuenta;
import com.unimag.modulo_transferencia.entity.Usuario;
import com.unimag.modulo_transferencia.repository.CuentaRepository;
import com.unimag.modulo_transferencia.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UsuarioRepository     usuarioRepository;
    private final CuentaRepository      cuentaRepository;
    private final JwtService            jwtService;
    private final PasswordEncoder       passwordEncoder;
    private final AuthenticationManager authenticationManager;

    private static final String URL_VALIDAR_TOKEN =
            "https://mriai.coreunimag.com/api/auth/validate-token";

    // ── Construye LoginResponse con lista de cuentas ──────────────────────
    private AuthDTO.LoginResponse buildResponse(Usuario usuario, String token) {
        java.util.List<Cuenta> cuentas = cuentaRepository.findAllByUsuario(usuario);

        java.util.List<AuthDTO.CuentaDTO> cuentasDTO = cuentas.stream().map(c -> {
            AuthDTO.CuentaDTO dto = new AuthDTO.CuentaDTO();
            dto.setId(c.getId());
            dto.setNumeroCuenta(c.getNumeroCuenta());
            dto.setSaldo(c.getSaldo());
            return dto;
        }).collect(java.util.stream.Collectors.toList());

        AuthDTO.LoginResponse response = new AuthDTO.LoginResponse();
        response.setToken(token);
        response.setNombre(usuario.getNombre());
        response.setApellido(usuario.getApellido());
        response.setEmail(usuario.getEmail());
        response.setCuentas(cuentasDTO);
        return response;
    }

    // ── LOGIN ─────────────────────────────────────────────────────────────
    public AuthDTO.LoginResponse login(AuthDTO.LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );
        Usuario usuario = usuarioRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));
        String token = jwtService.generarToken(usuario.getEmail());
        return buildResponse(usuario, token);
    }

    // ── REGISTRO ──────────────────────────────────────────────────────────
    @Transactional
    public AuthDTO.LoginResponse register(AuthDTO.RegisterRequest request) {
        if (usuarioRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("El email ya está registrado");
        }
        Usuario usuario = Usuario.builder()
                .nombre(request.getNombre())
                .apellido(request.getApellido())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .build();
        usuarioRepository.save(usuario);

        Cuenta cuenta = Cuenta.builder()
                .usuario(usuario)
                .numeroCuenta(generarNumeroCuenta())
                .saldo(0.0)
                .build();
        cuentaRepository.save(cuenta);

        String token = jwtService.generarToken(usuario.getEmail());
        return buildResponse(usuario, token);
    }

    // ── LOGIN CON TOKEN EXTERNO ───────────────────────────────────────────
    @Transactional
    public AuthDTO.LoginResponse loginConTokenExterno(String tokenApp) {
        try {
            String[] partes = tokenApp.split("\\.");
            if (partes.length < 2) throw new RuntimeException("Token externo inválido");

            String payloadBase64 = partes[1];
            int mod = payloadBase64.length() % 4;
            if (mod != 0) payloadBase64 += "=".repeat(4 - mod);

            byte[]     payloadBytes = java.util.Base64.getUrlDecoder().decode(payloadBase64);
            String     payloadJson  = new String(payloadBytes);

            ObjectMapper mapper  = new ObjectMapper();
            JsonNode     payload = mapper.readTree(payloadJson);

            String sub = payload.has("sub") ? payload.get("sub").asText() : null;
            if (sub == null || sub.isBlank()) {
                throw new RuntimeException("No se pudo extraer el identificador del token");
            }
            if (payload.has("exp")) {
                long exp     = payload.get("exp").asLong();
                long ahoraMs = System.currentTimeMillis() / 1000;
                if (ahoraMs > exp) throw new RuntimeException("El tokenApp ha expirado");
            }

            String nombre   = payload.has("nombres")   ? payload.get("nombres").asText()   : "Usuario";
            String apellido = payload.has("apellidos")  ? payload.get("apellidos").asText()  : "App";

            // Buscar o crear usuario
            Usuario usuario = usuarioRepository.findByEmail(sub).orElseGet(() -> {
                Usuario nuevo = Usuario.builder()
                        .nombre(nombre).apellido(apellido).email(sub)
                        .password(passwordEncoder.encode(tokenApp.substring(0, 20)))
                        .build();
                return usuarioRepository.save(nuevo);
            });

            // Si no tiene ninguna cuenta, crear la primera
            if (cuentaRepository.countByUsuario(usuario) == 0) {
                Cuenta nueva = Cuenta.builder()
                        .usuario(usuario)
                        .numeroCuenta(generarNumeroCuenta())
                        .saldo(50000.0)
                        .build();
                cuentaRepository.save(nueva);
            }

            // Actualizar nombre y apellido si cambiaron
            usuario.setNombre(nombre);
            usuario.setApellido(apellido);
            usuarioRepository.save(usuario);

            String jwtPropio = jwtService.generarToken(usuario.getEmail());
            return buildResponse(usuario, jwtPropio);

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
        } while (cuentaRepository.existsByNumeroCuenta(cuenta));
        return cuenta;
    }
}