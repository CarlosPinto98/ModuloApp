package com.unimag.modulo_transferencia.repository;

import com.unimag.modulo_transferencia.entity.Cuenta;
import com.unimag.modulo_transferencia.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CuentaRepository extends JpaRepository<Cuenta, Long> {

    // Buscar cuenta por usuario
    Optional<Cuenta> findByUsuario(Usuario usuario);

    // Buscar cuenta por número de cuenta
    Optional<Cuenta> findByNumeroCuenta(String numeroCuenta);

    // Verificar si un número de cuenta ya existe
    boolean existsByNumeroCuenta(String numeroCuenta);
}