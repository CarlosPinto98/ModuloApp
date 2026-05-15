package com.unimag.modulo_transferencia.service;

import com.unimag.modulo_transferencia.dto.ActualizarCuentaRequest;
import com.unimag.modulo_transferencia.dto.ActualizarCuentaResponse;
import com.unimag.modulo_transferencia.entity.Cuenta;
import com.unimag.modulo_transferencia.entity.Usuario;
import com.unimag.modulo_transferencia.repository.CuentaRepository;
import com.unimag.modulo_transferencia.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;
    private final CuentaRepository  cuentaRepository;

    @Transactional
    public ActualizarCuentaResponse actualizarNumeroCuenta(String email,
                                                           ActualizarCuentaRequest request) {
        // Validaciones
        String nuevaCuenta = request.getNumeroCuenta();
        if (nuevaCuenta == null || nuevaCuenta.trim().isEmpty()) {
            return new ActualizarCuentaResponse(false,
                    "El número de cuenta no puede estar vacío", null);
        }
        if (nuevaCuenta.trim().length() < 8) {
            return new ActualizarCuentaResponse(false,
                    "El número de cuenta debe tener mínimo 8 dígitos", null);
        }
        if (nuevaCuenta.trim().length() > 20) {
            return new ActualizarCuentaResponse(false,
                    "El número de cuenta no puede tener más de 20 dígitos", null);
        }
        if (!nuevaCuenta.matches("[0-9]+")) {
            return new ActualizarCuentaResponse(false,
                    "El número de cuenta solo puede contener dígitos", null);
        }

        // Verificar que el número no esté en uso por otro usuario
        if (cuentaRepository.existsByNumeroCuenta(nuevaCuenta.trim())) {
            return new ActualizarCuentaResponse(false,
                    "Ese número de cuenta ya está registrado", null);
        }

        // Buscar usuario
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        // Buscar cuenta del usuario y actualizar
        Cuenta cuenta = cuentaRepository.findByUsuario(usuario)
                .orElseThrow(() -> new RuntimeException("Cuenta no encontrada"));

        cuenta.setNumeroCuenta(nuevaCuenta.trim());
        cuentaRepository.save(cuenta);

        return new ActualizarCuentaResponse(true,
                "Número de cuenta actualizado correctamente", nuevaCuenta.trim());
    }

    // ── Obtener saldo actual del usuario ──────────────────────────────────
    public Double obtenerSaldo(String email) {
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        Cuenta cuenta = cuentaRepository.findByUsuario(usuario)
                .orElseThrow(() -> new RuntimeException("Cuenta no encontrada"));

        return cuenta.getSaldo();
    }
}