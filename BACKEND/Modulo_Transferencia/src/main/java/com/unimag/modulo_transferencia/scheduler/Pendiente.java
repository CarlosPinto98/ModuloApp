package com.unimag.modulo_transferencia.scheduler;

import com.unimag.modulo_transferencia.model.Movimiento;
import com.unimag.modulo_transferencia.model.Usuario;
import com.unimag.modulo_transferencia.repository.MovimientoRepository;
import com.unimag.modulo_transferencia.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;


@Slf4j
@Component
@RequiredArgsConstructor
public class Pendiente {

    private final MovimientoRepository movimientoRepository;
    private final UsuarioRepository    usuarioRepository;

    // ── Ejecuta cada 60 segundos ──────────────────────────────────────────
    // Revisa movimientos PENDIENTE de más de 5 minutos:
    // - Si la cuenta destino ya existe → COMPLETADO y acredita el saldo
    // - Si la cuenta destino sigue sin existir → FALLIDO y devuelve el saldo
    @Scheduled(fixedDelay = 60000)
    @Transactional
    public void resolverPendientes() {
        LocalDateTime limite = LocalDateTime.now().minusMinutes(5);

        List<Movimiento> pendientes = movimientoRepository
                .findByEstadoAndFechaHoraBefore(
                        Movimiento.EstadoMovimiento.PENDIENTE, limite);

        if (pendientes.isEmpty()) return;

        log.info("Resolviendo {} movimiento(s) pendiente(s)...", pendientes.size());

        for (Movimiento mov : pendientes) {
            boolean cuentaExiste = usuarioRepository
                    .findByNumeroCuenta(mov.getCuentaDestino()).isPresent();

            if (cuentaExiste) {
                // Acreditar al destino y marcar COMPLETADO
                usuarioRepository.findByNumeroCuenta(mov.getCuentaDestino())
                        .ifPresent(destino -> {
                            destino.setSaldo(destino.getSaldo() + mov.getMonto());
                            usuarioRepository.save(destino);
                        });
                mov.setEstado(Movimiento.EstadoMovimiento.COMPLETADO);
                log.info("Movimiento {} → COMPLETADO", mov.getReferencia());
            } else {
                // Devolver saldo al origen y marcar FALLIDO
                Usuario origen = mov.getUsuarioOrigen();
                origen.setSaldo(origen.getSaldo() + mov.getMonto());
                usuarioRepository.save(origen);
                mov.setEstado(Movimiento.EstadoMovimiento.FALLIDO);
                log.info("Movimiento {} → FALLIDO (cuenta destino no encontrada, saldo devuelto)",
                        mov.getReferencia());
            }
            movimientoRepository.save(mov);
        }
    }
}