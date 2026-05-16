package com.unimag.modulo_transferencia.controller;

public class RecargaRequest {

    private Long   cuentaOrigenId;
    private Double monto;
    private String metodoPago;
    private String cuentaDestino; // null = recarga propia

    public Long   getCuentaOrigenId() {
        return cuentaOrigenId;
    }

    public Double getMonto() {
        return monto;
    }

    public String getMetodoPago() {
        return metodoPago;
    }

    public String getCuentaDestino()  {
        return cuentaDestino;
    }
}