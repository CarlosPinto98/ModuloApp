package com.unimag.modulo_transferencia.service;

import com.unimag.modulo_transferencia.model.Movimiento;
import com.unimag.modulo_transferencia.model.Usuario;
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

    private final UsuarioRepository usuarioRepository;
    private final MovimientoRepository movimientoRepository;

    // ── Genera referencia única garantizada con UUID ───────────────────────
    private String generarReferencia(String prefijo) {
        return prefijo + "-" + UUID.randomUUID().toString().substring(0, 7).toUpperCase();
    }

    // ── TRANSFERENCIA ─────────────────────────────────────────────────────
    @Transactional
    public Map<String, Object> realizarTransferencia(Usuario origen, String cuentaDestino, Double monto, String concepto) {
        Map<String, Object> resultado = new HashMap<>();
        String referencia = generarReferencia("TRF");
        LocalDateTime ahora = LocalDateTime.now();
        String conceptoFinal = concepto != null && !concepto.isBlank() ? concepto : "Transferencia";

        // Validar saldo insuficiente → FALLIDO
        if (origen.getSaldo() < monto) {
            movimientoRepository.save(Movimiento.builder()
                    .referencia(referencia)
                    .usuarioOrigen(origen)
                    .cuentaDestino(cuentaDestino)
                    .monto(monto)
                    .concepto(conceptoFinal)
                    .tipo(Movimiento.TipoMovimiento.TRANSFERENCIA)
                    .estado(Movimiento.EstadoMovimiento.FALLIDO)
                    .fechaHora(ahora)
                    .build());

            resultado.put("exito", false);
            resultado.put("referencia", referencia);
            resultado.put("mensaje", "Saldo insuficiente");
            resultado.put("fechaHora", ahora.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")));
            return resultado;
        }

        // Validar cuenta propia → FALLIDO
        if (origen.getNumeroCuenta().equals(cuentaDestino)) {
            movimientoRepository.save(Movimiento.builder()
                    .referencia(referencia)
                    .usuarioOrigen(origen)
                    .cuentaDestino(cuentaDestino)
                    .monto(monto)
                    .concepto(conceptoFinal)
                    .tipo(Movimiento.TipoMovimiento.TRANSFERENCIA)
                    .estado(Movimiento.EstadoMovimiento.FALLIDO)
                    .fechaHora(ahora)
                    .build());

            resultado.put("exito", false);
            resultado.put("referencia", referencia);
            resultado.put("mensaje", "No puedes transferir a tu propia cuenta");
            resultado.put("fechaHora", ahora.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")));
            return resultado;
        }

        // Descontar saldo al origen siempre
        origen.setSaldo(origen.getSaldo() - monto);
        usuarioRepository.save(origen);

        boolean cuentaExiste = usuarioRepository.findByNumeroCuenta(cuentaDestino).isPresent();

        if (cuentaExiste) {
            // Acreditar al destino → COMPLETADO
            usuarioRepository.findByNumeroCuenta(cuentaDestino).ifPresent(destino -> {
                destino.setSaldo(destino.getSaldo() + monto);
                usuarioRepository.save(destino);
            });

            movimientoRepository.save(Movimiento.builder()
                    .referencia(referencia)
                    .usuarioOrigen(origen)
                    .cuentaDestino(cuentaDestino)
                    .monto(monto)
                    .concepto(conceptoFinal)
                    .tipo(Movimiento.TipoMovimiento.TRANSFERENCIA)
                    .estado(Movimiento.EstadoMovimiento.COMPLETADO)
                    .fechaHora(ahora)
                    .build());

            resultado.put("exito", true);
            resultado.put("referencia", referencia);
            resultado.put("mensaje", "Transferencia procesada correctamente");
        } else {
            // Cuenta no existe → PENDIENTE (esperando confirmación 5 min)
            movimientoRepository.save(Movimiento.builder()
                    .referencia(referencia)
                    .usuarioOrigen(origen)
                    .cuentaDestino(cuentaDestino)
                    .monto(monto)
                    .concepto(conceptoFinal)
                    .tipo(Movimiento.TipoMovimiento.TRANSFERENCIA)
                    .estado(Movimiento.EstadoMovimiento.PENDIENTE)
                    .fechaHora(ahora)
                    .build());

            resultado.put("exito", true);
            resultado.put("referencia", referencia);
            resultado.put("mensaje", "Transferencia en proceso. Se confirmará en los próximos minutos.");
        }

        resultado.put("fechaHora", ahora.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")));
        return resultado;
    }

    // ── RECARGA ───────────────────────────────────────────────────────────
    @Transactional
    public Map<String, Object> realizarRecarga(Usuario usuario, Double monto, String metodoPago, String cuentaDestino) {
        Map<String, Object> resultado = new HashMap<>();
        LocalDateTime ahora = LocalDateTime.now();
        String referencia = generarReferencia("REC");
        String concepto = "Recarga - " + (metodoPago != null ? metodoPago : "App");

        boolean esPropia = cuentaDestino == null || cuentaDestino.equals(usuario.getNumeroCuenta());

        // Validar saldo insuficiente para recarga a otro → FALLIDO
        if (!esPropia && usuario.getSaldo() < monto) {
            movimientoRepository.save(Movimiento.builder()
                    .referencia(referencia)
                    .usuarioOrigen(usuario)
                    .cuentaDestino(cuentaDestino)
                    .monto(monto)
                    .concepto(concepto)
                    .tipo(Movimiento.TipoMovimiento.RECARGA)
                    .estado(Movimiento.EstadoMovimiento.FALLIDO)
                    .fechaHora(ahora)
                    .build());

            resultado.put("exito", false);
            resultado.put("mensaje", "Saldo insuficiente");
            return resultado;
        }

        if (esPropia) {
            usuario.setSaldo(usuario.getSaldo() + monto);
            usuarioRepository.save(usuario);
        } else {
            usuario.setSaldo(usuario.getSaldo() - monto);
            usuarioRepository.save(usuario);

            usuarioRepository.findByNumeroCuenta(cuentaDestino).ifPresent(destino -> {
                destino.setSaldo(destino.getSaldo() + monto);
                usuarioRepository.save(destino);
            });
        }

        movimientoRepository.save(Movimiento.builder()
                .referencia(referencia)
                .usuarioOrigen(usuario)
                .cuentaDestino(esPropia ? usuario.getNumeroCuenta() : cuentaDestino)
                .monto(monto)
                .concepto(concepto)
                .tipo(Movimiento.TipoMovimiento.RECARGA)
                .estado(Movimiento.EstadoMovimiento.COMPLETADO)
                .fechaHora(ahora)
                .build());

        resultado.put("exito", true);
        resultado.put("mensaje", "Recarga realizada correctamente");
        resultado.put("nuevoSaldo", usuario.getSaldo());
        return resultado;
    }

    // ── HISTORIAL COMPLETO ────────────────────────────────────────────────
    public List<Movimiento> obtenerTodos(Usuario usuario) {
        return movimientoRepository.findByUsuarioOrigenOrderByFechaHoraDesc(usuario);
    }

    // ── HISTORIAL DE HOY ──────────────────────────────────────────────────
    public List<Movimiento> obtenerDeHoy(Usuario usuario) {
        LocalDateTime inicioDia = LocalDateTime.now().toLocalDate().atStartOfDay();
        return movimientoRepository
                .findByUsuarioOrigenAndFechaHoraAfterOrderByFechaHoraDesc(usuario, inicioDia);
    }
}