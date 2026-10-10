package com.techinnov.kassouwata_back.entitites;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Data
@Table(name = "otp_code")
public class OtpCode {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Numéro de téléphone destinataire */
    @Column(nullable = false)
    private String telephone;

    /** Code OTP à 6 chiffres */
    @Column(nullable = false, length = 6)
    private String code;

    /** Date/heure d'expiration (30 minutes après génération) */
    @Column(nullable = false)
    private LocalDateTime expiresAt;

    /** true si déjà utilisé (consommé après vérification réussie) */
    @Column(nullable = false)
    private boolean used = false;

    /** Date de création */
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
}
