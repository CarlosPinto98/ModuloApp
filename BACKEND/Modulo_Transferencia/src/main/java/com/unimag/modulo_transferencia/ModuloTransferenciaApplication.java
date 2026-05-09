package com.unimag.modulo_transferencia;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class ModuloTransferenciaApplication {

    public static void main(String[] args) {
        SpringApplication.run(ModuloTransferenciaApplication.class, args);
    }
}