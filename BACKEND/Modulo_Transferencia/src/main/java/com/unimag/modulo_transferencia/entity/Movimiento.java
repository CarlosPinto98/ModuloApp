package com.unimag.modulo_transferencia.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "movimientos")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Movimiento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String referencia;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_origen_id", nullable = false)
    private Usuario usuarioOrigen;

    @Column(nullable = false, length = 20)
    private String cuentaDestino;

    @Column(nullable = false)
    private Double monto;

    @Column(nullable = false, length = 100)
    private String concepto;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private TipoMovimiento tipo;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private EstadoMovimiento estado;

    @Column(nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime fechaHora = LocalDateTime.now();

    public enum TipoMovimiento {
        TRANSFERENCIA, RECARGA
    }

    public enum EstadoMovimiento {
        COMPLETADO, FALLIDO, PENDIENTE
    }
}