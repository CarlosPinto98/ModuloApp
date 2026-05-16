package com.unimag.modulo_transferencia.repository;

import com.unimag.modulo_transferencia.entity.Cuenta;
import com.unimag.modulo_transferencia.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CuentaRepository extends JpaRepository<Cuenta, Long> {

    // Todas las cuentas de un usuario
    java.util.List<Cuenta> findAllByUsuario(Usuario usuario);

    // Cantidad de cuentas del usuario (para validar límite de 3)
    long countByUsuario(Usuario usuario);

    // Buscar cuenta por número de cuenta
    Optional<Cuenta> findByNumeroCuenta(String numeroCuenta);

    // Verificar si un número de cuenta ya existe
    boolean existsByNumeroCuenta(String numeroCuenta);
}