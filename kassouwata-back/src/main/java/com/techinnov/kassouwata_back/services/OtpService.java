package com.techinnov.kassouwata_back.services;

import com.techinnov.kassouwata_back.entitites.OtpCode;
import com.techinnov.kassouwata_back.entitites.Sms;
import com.techinnov.kassouwata_back.repositories.OtpCodeRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Random;

@Service
public class OtpService {

    @Autowired
    private OtpCodeRepository otpCodeRepository;

    @Autowired
    private SmsService smsService;

    private static final int OTP_VALIDITY_MINUTES = 30;

    /**
     * Génère un OTP à 6 chiffres, invalide les anciens,
     * persiste le nouveau et l'envoie par SMS.
     */
    public void sendOtp(String telephone) {
        // Invalider les OTP précédents
        otpCodeRepository.invalidateAllForTelephone(telephone);

        // Générer un code à 6 chiffres avec zéros initiaux conservés
        String code = String.format("%06d", new Random().nextInt(1_000_000));

        // Persister
        OtpCode otp = new OtpCode();
        otp.setTelephone(telephone);
        otp.setCode(code);
        otp.setExpiresAt(LocalDateTime.now().plusMinutes(OTP_VALIDITY_MINUTES));
        otpCodeRepository.save(otp);

        // Envoyer par SMS via SmsService
        String message = "Votre code de vérification Kassouwata est : " + code +
                         ". Valable " + OTP_VALIDITY_MINUTES + " minutes.";
        try {
            Sms sms = new Sms();
            sms.setReceiver(telephone);
            sms.setMessage(message);
            smsService.send(sms);
        } catch (Exception e) {
            // Ne pas bloquer l'inscription si le SMS échoue — logger seulement
            System.err.println("[OtpService] Erreur envoi SMS OTP : " + e.getMessage());
        }
    }

    /**
     * Vérifie le code OTP fourni.
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
                    return false;
                })
                .orElse(false);
    }
}
