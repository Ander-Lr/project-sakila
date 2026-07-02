package com.example.demo.repositories;

import com.example.demo.models.RevokedToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.time.LocalDateTime;

@Repository
public interface RevokedTokenRepository extends JpaRepository<RevokedToken, String> {
    Optional<RevokedToken> findByJti(String jti);
    boolean existsByJti(String jti);
    
    void deleteByExpiresAtBefore(LocalDateTime now);
}
