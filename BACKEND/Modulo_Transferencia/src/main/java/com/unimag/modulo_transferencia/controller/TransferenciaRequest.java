package com.unimag.modulo_transferencia.controller;

public class TransferenciaRequest {

    private Long   cuentaOrigenId;
    private String cuentaDestino;
    private Double monto;
    private String concepto;

    public Long   getCuentaOrigenId() {
        return cuentaOrigenId;
    }

    public String getCuentaDestino() {
        return cuentaDestino;
    }

    public Double getMonto() {
        return monto;
    }

    public String getConcepto() {
        return concepto;
    }

}