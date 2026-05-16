package com.unimag.modulo_transferencia.dto;

public class ActualizarCuentaResponse {
    private boolean exito;
    private String  mensaje;
    private String  numeroCuenta;

    public ActualizarCuentaResponse(boolean exito, String mensaje, String numeroCuenta) {
        this.exito        = exito;
        this.mensaje      = mensaje;
        this.numeroCuenta = numeroCuenta;
    }

    public boolean isExito()        { return exito; }
    public String  getMensaje()     { return mensaje; }
    public String  getNumeroCuenta(){ return numeroCuenta; }
}