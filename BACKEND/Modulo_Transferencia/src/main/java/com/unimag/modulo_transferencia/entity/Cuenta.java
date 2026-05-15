package com.unimag.modulo_transferencia.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "cuentas")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Cuenta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id", nullable = false, unique = true)
    private Usuario usuario;

    @Column(nullable = false, length = 20)
    private String numeroCuenta;

    @Column(nullable = false)
    @Builder.Default
    private Double saldo = 0.0;

    @Column(nullable = false)
    @Builder.Default
    private Boolean activa = true;

    @Column(nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime creadaEn = LocalDateTime.now();
}