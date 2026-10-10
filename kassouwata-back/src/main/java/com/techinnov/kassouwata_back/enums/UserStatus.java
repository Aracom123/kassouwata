package com.techinnov.kassouwata_back.enums;

public enum UserStatus {
    /** Numéro de téléphone non encore vérifié par OTP — connexion bloquée */
    PHONE_UNVERIFIED,
    /** Compte créé et numéro vérifié, mais profil incomplet */
    KYC_PENDING,
    ACTIVE,
    SUSPENDED,
    BLOCKED,
    CLOSED
}
