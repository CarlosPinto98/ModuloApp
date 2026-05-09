package com.unimag.modulo_transferencia.dto;

import lombok.Data;

@Data
public class MovimientoDTO {

    private String referencia;
    private String cuentaDestino;
    private Double monto;
    private String concepto;
    private String fechaHora;
    private String estado;
    private String tipo;
    private Boolean esHoy;
}
