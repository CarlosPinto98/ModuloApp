package com.unimag.modulo_transferencia.service;

import com.unimag.modulo_transferencia.entity.Cuenta;
import com.unimag.modulo_transferencia.entity.Movimiento;

import com.unimag.modulo_transferencia.repository.CuentaRepository;
import com.unimag.modulo_transferencia.repository.MovimientoRepository;
import com.unimag.modulo_transferencia.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TransferenciaService {

    private final UsuarioRepository    usuarioRepository;
    private final MovimientoRepository movimientoRepository;
    private final CuentaRepository     cuentaRepository;

    // ── Genera referencia única garantizada con UUID ───────────────────────
    private String generarReferencia(String prefijo) {
        return prefijo + "-" + UUID.randomUUID().toString().substring(0, 7).toUpperCase();
    }

    // ── TRANSFERENCIA ─────────────────────────────────────────────────────
    @Transactional
    public Map<String, Object> realizarTransferencia(Cuenta cuentaOrigen, String cuentaDestino,
                                                     Double monto, String concepto) {
        Map<String, Object> resultado = new HashMap<>();
        String referencia     = generarReferencia("TRF");
        LocalDateTime ahora   = LocalDateTime.now();
        String conceptoFinal  = concepto != null && !concepto.isBlank() ? concepto : "Transferencia";

        // Validar saldo insuficiente → FALLIDO
        if (cuentaOrigen.getSaldo() < monto) {
            movimientoRepository.save(Movimiento.builder()
                    .referencia(referencia).cuentaOrigen(cuentaOrigen)
                    .cuentaDestino(cuentaDestino).monto(monto).concepto(conceptoFinal)
                    .tipo(Movimiento.TipoMovimiento.TRANSFERENCIA)
                    .estado(Movimiento.EstadoMovimiento.FALLIDO).fechaHora(ahora).build());
            resultado.put("exito", false);
            resultado.put("referencia", referencia);
            resultado.put("mensaje", "Saldo insuficiente");
            resultado.put("fechaHora", ahora.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")));
            return resultado;
        }

        // Validar cuenta propia → FALLIDO
        if (cuentaOrigen.getNumeroCuenta().equals(cuentaDestino)) {
            movimientoRepository.save(Movimiento.builder()
                    .referencia(referencia).cuentaOrigen(cuentaOrigen)
                    .cuentaDestino(cuentaDestino).monto(monto).concepto(conceptoFinal)
                    .tipo(Movimiento.TipoMovimiento.TRANSFERENCIA)
                    .estado(Movimiento.EstadoMovimiento.FALLIDO).fechaHora(ahora).build());
            resultado.put("exito", false);
            resultado.put("referencia", referencia);
            resultado.put("mensaje", "No puedes transferir a tu propia cuenta");
            resultado.put("fechaHora", ahora.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")));
            return resultado;
        }

        // Descontar saldo al origen
        cuentaOrigen.setSaldo(cuentaOrigen.getSaldo() - monto);
        cuentaRepository.save(cuentaOrigen);

        boolean cuentaExiste = cuentaRepository.findByNumeroCuenta(cuentaDestino).isPresent();

        if (cuentaExiste) {
            cuentaRepository.findByNumeroCuenta(cuentaDestino).ifPresent(destino -> {
                destino.setSaldo(destino.getSaldo() + monto);
                cuentaRepository.save(destino);
            });
            movimientoRepository.save(Movimiento.builder()
                    .referencia(referencia).cuentaOrigen(cuentaOrigen)
                    .cuentaDestino(cuentaDestino).monto(monto).concepto(conceptoFinal)
                    .tipo(Movimiento.TipoMovimiento.TRANSFERENCIA)
                    .estado(Movimiento.EstadoMovimiento.COMPLETADO).fechaHora(ahora).build());
            resultado.put("exito", true);
            resultado.put("referencia", referencia);
            resultado.put("mensaje", "Transferencia procesada correctamente");
        } else {
            movimientoRepository.save(Movimiento.builder()
                    .referencia(referencia).cuentaOrigen(cuentaOrigen)
                    .cuentaDestino(cuentaDestino).monto(monto).concepto(conceptoFinal)
                    .tipo(Movimiento.TipoMovimiento.TRANSFERENCIA)
                    .estado(Movimiento.EstadoMovimiento.PENDIENTE).fechaHora(ahora).build());
            resultado.put("exito", true);
            resultado.put("referencia", referencia);
            resultado.put("mensaje", "Transferencia en proceso. Se confirmará en los próximos minutos.");
        }

        resultado.put("fechaHora", ahora.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")));
        return resultado;
    }

    // ── RECARGA ───────────────────────────────────────────────────────────
    @Transactional
    public Map<String, Object> realizarRecarga(Cuenta cuentaOrigen, Double monto,
                                               String metodoPago, String cuentaDestino) {
        Map<String, Object> resultado = new HashMap<>();
        LocalDateTime ahora   = LocalDateTime.now();
        String referencia     = generarReferencia("REC");
        String concepto       = "Recarga - " + (metodoPago != null ? metodoPago : "App");

        boolean esPropia = cuentaDestino == null ||
                cuentaDestino.equals(cuentaOrigen.getNumeroCuenta());

        // Validar saldo insuficiente para recarga a otro
        if (!esPropia && cuentaOrigen.getSaldo() < monto) {
            movimientoRepository.save(Movimiento.builder()
                    .referencia(referencia).cuentaOrigen(cuentaOrigen)
                    .cuentaDestino(cuentaDestino).monto(monto).concepto(concepto)
                    .tipo(Movimiento.TipoMovimiento.RECARGA)
                    .estado(Movimiento.EstadoMovimiento.FALLIDO).fechaHora(ahora).build());
            resultado.put("exito", false);
            resultado.put("mensaje", "Saldo insuficiente");
            return resultado;
        }

        if (esPropia) {
            cuentaOrigen.setSaldo(cuentaOrigen.getSaldo() + monto);
            cuentaRepository.save(cuentaOrigen);
        } else {
            cuentaOrigen.setSaldo(cuentaOrigen.getSaldo() - monto);
            cuentaRepository.save(cuentaOrigen);
            cuentaRepository.findByNumeroCuenta(cuentaDestino).ifPresent(destino -> {
                destino.setSaldo(destino.getSaldo() + monto);
                cuentaRepository.save(destino);
            });
        }

        movimientoRepository.save(Movimiento.builder()
                .referencia(referencia).cuentaOrigen(cuentaOrigen)
                .cuentaDestino(esPropia ? cuentaOrigen.getNumeroCuenta() : cuentaDestino)
                .monto(monto).concepto(concepto)
                .tipo(Movimiento.TipoMovimiento.RECARGA)
                .estado(Movimiento.EstadoMovimiento.COMPLETADO).fechaHora(ahora).build());

        resultado.put("exito", true);
        resultado.put("mensaje", "Recarga realizada correctamente");
        resultado.put("nuevoSaldo", cuentaOrigen.getSaldo());
        return resultado;
    }

    // ── HISTORIAL COMPLETO ────────────────────────────────────────────────
    public List<Movimiento> obtenerTodos(Cuenta cuenta) {
        return movimientoRepository.findByCuentaOrigenOrderByFechaHoraDesc(cuenta);
    }

    // ── HISTORIAL DE HOY ──────────────────────────────────────────────────
    public List<Movimiento> obtenerDeHoy(Cuenta cuenta) {
        LocalDateTime inicioDia = LocalDateTime.now().toLocalDate().atStartOfDay();
        return movimientoRepository.findByCuentaOrigenAndFechaHoraAfterOrderByFechaHoraDesc(cuenta, inicioDia);
    }
}