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

    // ── Actualizar número de cuenta específica ────────────────────────────
    @Transactional
    public ActualizarCuentaResponse actualizarNumeroCuenta(String email,
                                                           ActualizarCuentaRequest request) {
        String nuevaCuenta = request.getNumeroCuenta();
        if (nuevaCuenta == null || nuevaCuenta.trim().isEmpty())
            return new ActualizarCuentaResponse(false, "El número de cuenta no puede estar vacío", null);
        if (nuevaCuenta.trim().length() < 8)
            return new ActualizarCuentaResponse(false, "El número de cuenta debe tener mínimo 8 dígitos", null);
        if (nuevaCuenta.trim().length() > 20)
            return new ActualizarCuentaResponse(false, "El número de cuenta no puede tener más de 20 dígitos", null);
        if (!nuevaCuenta.matches("[0-9]+"))
            return new ActualizarCuentaResponse(false, "El número de cuenta solo puede contener dígitos", null);
        if (cuentaRepository.existsByNumeroCuenta(nuevaCuenta.trim()))
            return new ActualizarCuentaResponse(false, "Ese número de cuenta ya está registrado", null);

        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        Long cuentaId = request.getCuentaId();
        if (cuentaId == null)
            return new ActualizarCuentaResponse(false, "Se requiere el id de la cuenta", null);

        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new RuntimeException("Cuenta no encontrada"));

        if (!cuenta.getUsuario().getId().equals(usuario.getId()))
            return new ActualizarCuentaResponse(false, "La cuenta no pertenece al usuario", null);

        cuenta.setNumeroCuenta(nuevaCuenta.trim());
        cuentaRepository.save(cuenta);
        return new ActualizarCuentaResponse(true, "Número de cuenta actualizado correctamente", nuevaCuenta.trim());
    }

    // ── Obtener saldo de cuenta específica ────────────────────────────────
    public Double obtenerSaldo(String email, Long cuentaId) {
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new RuntimeException("Cuenta no encontrada"));
        if (!cuenta.getUsuario().getId().equals(usuario.getId()))
            throw new RuntimeException("La cuenta no pertenece al usuario");
        return cuenta.getSaldo();
    }

    // ── Crear nueva cuenta (máximo 3) ─────────────────────────────────────
    @Transactional
    public java.util.Map<String, Object> crearCuenta(String email) {
        java.util.Map<String, Object> resultado = new java.util.HashMap<>();
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        long total = cuentaRepository.countByUsuario(usuario);
        if (total >= 3) {
            resultado.put("exito", false);
            resultado.put("mensaje", "Has alcanzado el límite de 3 cuentas");
            return resultado;
        }

        String numero;
        do {
            numero = String.format("%010d",
                    (long)(Math.random() * 9_000_000_000L) + 1_000_000_000L);
        } while (cuentaRepository.existsByNumeroCuenta(numero));

        Cuenta nueva = Cuenta.builder()
                .usuario(usuario).numeroCuenta(numero).saldo(0.0).build();
        cuentaRepository.save(nueva);

        resultado.put("exito", true);
        resultado.put("mensaje", "Cuenta creada correctamente");
        resultado.put("cuentaId", nueva.getId());
        resultado.put("numeroCuenta", nueva.getNumeroCuenta());
        resultado.put("saldo", nueva.getSaldo());
        return resultado;
    }

    // ── Eliminar cuenta (no se puede eliminar la única) ───────────────────
    @Transactional
    public java.util.Map<String, Object> eliminarCuenta(String email, Long cuentaId) {
        java.util.Map<String, Object> resultado = new java.util.HashMap<>();
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));

        long total = cuentaRepository.countByUsuario(usuario);
        if (total <= 1) {
            resultado.put("exito", false);
            resultado.put("mensaje", "No puedes eliminar tu única cuenta");
            return resultado;
        }

        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new RuntimeException("Cuenta no encontrada"));

        if (!cuenta.getUsuario().getId().equals(usuario.getId())) {
            resultado.put("exito", false);
            resultado.put("mensaje", "La cuenta no pertenece al usuario");
            return resultado;
        }

        if (cuenta.getSaldo() > 0) {
            resultado.put("exito", false);
            resultado.put("mensaje", "No puedes eliminar una cuenta con saldo");
            return resultado;
        }

        //cuenta.setActiva(false);
        //cuentaRepository.save(cuenta);
        cuentaRepository.delete(cuenta);
        resultado.put("exito", true);
        resultado.put("mensaje", "Cuenta eliminada correctamente");
        return resultado;
    }
}