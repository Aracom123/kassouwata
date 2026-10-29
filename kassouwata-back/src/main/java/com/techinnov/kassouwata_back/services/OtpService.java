package com.techinnov.kassouwata_back.services;

import com.techinnov.kassouwata_back.entitites.OtpCode;
import com.techinnov.kassouwata_back.entitites.Sms;
import com.techinnov.kassouwata_back.repositories.OtpCodeRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;

@Service
public class OtpService {

    @Autowired
    private OtpCodeRepository otpCodeRepository;

    @Autowired
    private SmsService smsService;

    private static final int OTP_VALIDITY_MINUTES = 30;
    /** Validité plus courte pour la réinitialisation du mot de passe. */
    private static final int RESET_VALIDITY_MINUTES = 10;
    /** Délai minimum entre deux envois de code au même numéro. */
    public static final Duration DELAI_RENVOI = Duration.ofSeconds(60);
    /** Nombre maximum de saisies erronées avant invalidation du code. */
    private static final int MAX_TENTATIVES = 5;

    private static final SecureRandom RANDOM = new SecureRandom();

    /**
     * DÉVELOPPEMENT UNIQUEMENT : affiche le code dans la console du backend pour
     * tester sans SMS (variable OTP_LOG_CODE=true dans .env). Jamais en production.
     */
    @Value("${otp.journaliser-code:false}")
    private boolean journaliserCode;

    /**
     * Génère un OTP à 6 chiffres, invalide les anciens,
     * persiste le nouveau et l'envoie par SMS (vérification du numéro à l'inscription).
     */
    public void sendOtp(String telephone) {
        envoyer(telephone, OTP_VALIDITY_MINUTES,
                "KASUWATA : votre code de verification est %s. Valable %d minutes.");
    }

    /** Envoie un code de confirmation au nouveau numéro lors d'un changement de numéro. */
    public void sendChangeOtp(String nouveauTelephone) {
        envoyer(nouveauTelephone, RESET_VALIDITY_MINUTES,
                "KASUWATA : votre code de confirmation du nouveau numero est %s. "
                        + "Valable %d minutes. Ne le communiquez a personne.");
    }

    /** Envoie un code de réinitialisation du mot de passe. */
    public void sendResetOtp(String telephone) {
        envoyer(telephone, RESET_VALIDITY_MINUTES,
                "KASUWATA : votre code pour changer de mot de passe est %s. "
                        + "Valable %d minutes. Ne le communiquez a personne.");
    }

    /**
     * Secondes restantes avant de pouvoir renvoyer un code à ce numéro (0 = autorisé).
     * Évite l'envoi massif de SMS sur un même numéro.
     */
    public long secondesAvantRenvoi(String telephone) {
        return otpCodeRepository.findFirstByTelephoneOrderByCreatedAtDesc(telephone)
                .map(o -> {
                    long ecoule = Duration.between(o.getCreatedAt(), LocalDateTime.now()).getSeconds();
                    return Math.max(0, DELAI_RENVOI.getSeconds() - ecoule);
                })
                .orElse(0L);
    }

    private void envoyer(String telephone, int validiteMinutes, String modeleMessage) {
        // Invalider les OTP précédents
        otpCodeRepository.invalidateAllForTelephone(telephone);

        // Code à 6 chiffres (zéros initiaux conservés), générateur cryptographique
        String code = String.format("%06d", RANDOM.nextInt(1_000_000));

        OtpCode otp = new OtpCode();
        otp.setTelephone(telephone);
        otp.setCode(code);
        otp.setExpiresAt(LocalDateTime.now().plusMinutes(validiteMinutes));
        otpCodeRepository.save(otp);

        if (journaliserCode) {
            System.out.println("[OtpService][DEV] Code pour " + telephone + " : " + code);
        }

        try {
            Sms sms = new Sms();
            sms.setReceiver(telephone);
            sms.setMessage(String.format(modeleMessage, code, validiteMinutes));
            smsService.send(sms);
        } catch (Exception e) {
            // Ne pas bloquer le parcours si le SMS échoue — logger seulement
            System.err.println("[OtpService] Erreur envoi SMS OTP : " + e.getMessage());
        }
    }

    /**
     * Vérifie le code OTP fourni et le consomme s'il est correct.
     * Après 5 saisies erronées, le code est invalidé (protection contre la force brute).
     * @return true si valide, false sinon
     */
    public boolean verifyOtp(String telephone, String code) {
        return otpCodeRepository
                .findValidOtp(telephone, LocalDateTime.now())
                .map(otp -> {
                    if (otp.getCode().equals(code)) {
                        otp.setUsed(true);
                        otpCodeRepository.save(otp);
                        return true;
                    }
                    int tentatives = (otp.getAttempts() == null ? 0 : otp.getAttempts()) + 1;
                    otp.setAttempts(tentatives);
                    if (tentatives >= MAX_TENTATIVES) {
                        otp.setUsed(true);
                    }
                    otpCodeRepository.save(otp);
                    return false;
                })
                .orElse(false);
    }
}
