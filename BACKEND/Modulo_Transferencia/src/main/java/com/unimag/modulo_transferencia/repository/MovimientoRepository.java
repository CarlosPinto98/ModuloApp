package com.unimag.modulo_transferencia.repository;

import com.unimag.modulo_transferencia.entity.Cuenta;
import com.unimag.modulo_transferencia.entity.Movimiento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface MovimientoRepository extends JpaRepository<Movimiento, Long> {

    // Todos los movimientos de una cuenta ordenados por fecha
    List<Movimiento> findByCuentaOrigenOrderByFechaHoraDesc(Cuenta cuenta);

    // Solo los de hoy de una cuenta
    List<Movimiento> findByCuentaOrigenAndFechaHoraAfterOrderByFechaHoraDesc(
            Cuenta cuenta, LocalDateTime desde);

    // Movimientos PENDIENTE anteriores a una fecha (para el scheduler)
    List<Movimiento> findByEstadoAndFechaHoraBefore(
            Movimiento.EstadoMovimiento estado, LocalDateTime fechaLimite);
}