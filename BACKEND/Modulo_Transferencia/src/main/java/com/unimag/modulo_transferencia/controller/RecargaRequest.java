package com.unimag.modulo_transferencia.controller;

import lombok.*;

@Data
@Getter
@Setter
public class RecargaRequest {

    private Double monto;
    private String metodoPago;
    private String cuentaDestino; // null = recarga propia

    public Double getMonto() {
        return monto;
    }

    public String getMetodoPago() {
        return metodoPago;
    }

    public String getCuentaDestino() {
        return cuentaDestino;
    }
}
