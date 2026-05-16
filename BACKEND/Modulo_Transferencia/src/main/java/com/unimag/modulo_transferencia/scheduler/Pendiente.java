package com.unimag.modulo_transferencia.scheduler;

import com.unimag.modulo_transferencia.entity.Cuenta;
import com.unimag.modulo_transferencia.entity.Movimiento;
import com.unimag.modulo_transferencia.repository.CuentaRepository;
import com.unimag.modulo_transferencia.repository.MovimientoRepository;
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
    private final CuentaRepository     cuentaRepository;

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
            boolean cuentaExiste = cuentaRepository
                    .findByNumeroCuenta(mov.getCuentaDestino()).isPresent();

            if (cuentaExiste) {
                // Acreditar al destino y marcar COMPLETADO
                cuentaRepository.findByNumeroCuenta(mov.getCuentaDestino())
                        .ifPresent(cuentaDestino -> {
                            cuentaDestino.setSaldo(cuentaDestino.getSaldo() + mov.getMonto());
                            cuentaRepository.save(cuentaDestino);
                        });

                mov.setEstado(Movimiento.EstadoMovimiento.COMPLETADO);
                log.info("Movimiento {} → COMPLETADO", mov.getReferencia());

            } else {
                // Devolver saldo al origen y marcar FALLIDO
                Cuenta cuentaOrigen = mov.getCuentaOrigen();
                cuentaOrigen.setSaldo(cuentaOrigen.getSaldo() + mov.getMonto());
                cuentaRepository.save(cuentaOrigen);

                mov.setEstado(Movimiento.EstadoMovimiento.FALLIDO);
                log.info("Movimiento {} → FALLIDO (cuenta destino no encontrada, saldo devuelto)",
                        mov.getReferencia());
            }
            movimientoRepository.save(mov);
        }
    }
}