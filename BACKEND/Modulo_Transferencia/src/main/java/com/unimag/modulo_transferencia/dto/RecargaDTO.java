package com.unimag.modulo_transferencia.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class RecargaDTO {

    @Data
    public static class Request {
        @NotNull(message = "El monto es obligatorio")
        @Min(value = 5000, message = "El monto mínimo de recarga es $5.000")
        @Max(value = 10000000, message = "El monto máximo de recarga es $10.000.000")
        private Double monto;

        @NotBlank(message = "El método de pago es obligatorio")
        private String metodoPago;

        // Si es recarga a otro usuario
        private String cuentaDestino;
    }

    @Data
    public static class Response {
        private Boolean exito;
        private String mensaje;
        private Double nuevoSaldo;
    }
}
