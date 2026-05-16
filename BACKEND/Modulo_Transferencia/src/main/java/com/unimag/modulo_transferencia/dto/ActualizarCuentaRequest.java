package com.unimag.modulo_transferencia.dto;

public class ActualizarCuentaRequest {
    private Long   cuentaId;
    private String numeroCuenta;

    public Long getCuentaId() {
        return cuentaId; }

    public void setCuentaId(Long cuentaId) {
        this.cuentaId = cuentaId; }

    public String getNumeroCuenta() {
        return numeroCuenta; }
    public void setNumeroCuenta(String numeroCuenta) {
        this.numeroCuenta = numeroCuenta; }
}