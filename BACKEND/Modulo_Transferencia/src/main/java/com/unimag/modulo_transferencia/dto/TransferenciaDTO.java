package com.unimag.modulo_transferencia.dto;


import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class TransferenciaDTO {

    @Data
    public static class Request {
        @NotBlank(message = "La cuenta destino es obligatoria")
        @Size(min = 8, max = 20, message = "La cuenta destino debe tener entre 8 y 20 dígitos")
        private String cuentaDestino;

        @NotNull(message = "El monto es obligatorio")
        @Min(value = 1000, message = "El monto mínimo es $1.000")
        @Max(value = 50000000, message = "El monto máximo es $50.000.000")
        private Double monto;

        @NotBlank(message = "El concepto es obligatorio")
        @Size(min = 3, max = 100, message = "El concepto debe tener entre 3 y 100 caracteres")
        private String concepto;
    }

    @Data
    public static class Response {

        private Boolean exito;
        private String referencia;
        private String mensaje;
        private String fechaHora;
    }
}
