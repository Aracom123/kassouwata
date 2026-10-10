package com.techinnov.kassouwata_back.repositories;

import com.techinnov.kassouwata_back.entitites.OtpCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

public interface OtpCodeRepository extends JpaRepository<OtpCode, Long> {

    /** Dernier OTP valide (non expiré, non utilisé) pour un numéro donné */
    @Query("SELECT o FROM OtpCode o WHERE o.telephone = :telephone " +
           "AND o.used = false AND o.expiresAt > :now " +
           "ORDER BY o.createdAt DESC")
    Optional<OtpCode> findValidOtp(@Param("telephone") String telephone,
                                   @Param("now") LocalDateTime now);

    /** Invalide tous les OTP précédents avant d'en générer un nouveau */
    @Modifying
    @Transactional
    @Query("UPDATE OtpCode o SET o.used = true WHERE o.telephone = :telephone AND o.used = false")
    void invalidateAllForTelephone(@Param("telephone") String telephone);
}
