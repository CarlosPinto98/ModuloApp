package com.unimag.modulo_transferencia.repository;


import com.unimag.modulo_transferencia.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {
    Optional<Usuario> findByEmail(String email);
    Optional<Usuario> findByNumeroCuenta(String numeroCuenta);
    boolean existsByEmail(String email);
    boolean existsByNumeroCuenta(String numeroCuenta);
}