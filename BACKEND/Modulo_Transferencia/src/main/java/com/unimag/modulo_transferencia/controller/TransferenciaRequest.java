package com.unimag.modulo_transferencia.controller;

import lombok.*;


@Data
@Getter
@Setter
public class TransferenciaRequest {

    private String cuentaDestino;
    private Double monto;
    private String concepto;
}
