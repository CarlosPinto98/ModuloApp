package com.unimag.modulo_transferencia.repository;

import com.unimag.modulo_transferencia.entity.Movimiento;
import com.unimag.modulo_transferencia.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface MovimientoRepository extends JpaRepository<Movimiento, Long> {

    // Todos los movimientos del usuario ordenados por fecha
    List<Movimiento> findByUsuarioOrigenOrderByFechaHoraDesc(Usuario usuario);

    // Solo los de hoy
    List<Movimiento> findByUsuarioOrigenAndFechaHoraAfterOrderByFechaHoraDesc(
            Usuario usuario, LocalDateTime desde);

    // Movimientos PENDIENTE anteriores a una fecha (para el scheduler)
    List<Movimiento> findByEstadoAndFechaHoraBefore(
            Movimiento.EstadoMovimiento estado, LocalDateTime fechaLimite);
}