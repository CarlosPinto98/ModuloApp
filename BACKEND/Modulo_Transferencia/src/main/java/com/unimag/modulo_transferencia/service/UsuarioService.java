package com.unimag.modulo_transferencia.service;

import com.unimag.modulo_transferencia.dto.ActualizarCuentaRequest;
import com.unimag.modulo_transferencia.dto.ActualizarCuentaResponse;
import com.unimag.modulo_transferencia.model.Usuario;
import com.unimag.modulo_transferencia.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class UsuarioService {

    @Autowired
    private UsuarioRepository usuarioRepository;

    public ActualizarCuentaResponse actualizarNumeroCuenta(String email, ActualizarCuentaRequest request) {

        // Validaciones
        String nuevaCuenta = request.getNumeroCuenta();
        if (nuevaCuenta == null || nuevaCuenta.trim().isEmpty()) {
            return new ActualizarCuentaResponse(false, "El número de cuenta no puede estar vacío", null);
        }
        if (nuevaCuenta.trim().length() < 8) {
            return new ActualizarCuentaResponse(false, "El número de cuenta debe tener mínimo 8 dígitos", null);
        }
        if (nuevaCuenta.trim().length() > 20) {
            return new ActualizarCuentaResponse(false, "El número de cuenta no puede tener más de 20 dígitos", null);
        }
        if (!nuevaCuenta.matches("[0-9]+")) {
            return new ActualizarCuentaResponse(false, "El número de cuenta solo puede contener dígitos", null);
        }

        // Verificar que el número no esté en uso por otro usuario
        if (usuarioRepository.existsByNumeroCuenta(nuevaCuenta.trim())) {
            return new ActualizarCuentaResponse(false, "Ese número de cuenta ya está registrado", null);
        }

        // Buscar usuario y actualizar
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        usuario.setNumeroCuenta(nuevaCuenta.trim());
        usuarioRepository.save(usuario);

        return new ActualizarCuentaResponse(true, "Número de cuenta actualizado correctamente", nuevaCuenta.trim());
    }
}
