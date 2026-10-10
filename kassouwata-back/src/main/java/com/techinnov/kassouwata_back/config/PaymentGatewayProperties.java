package com.techinnov.kassouwata_back.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Paramètres de l'agrégateur de paiement (Mobile Money / Carte),
 * lus depuis application.properties avec le préfixe "payment.gateway".
 */
@ConfigurationProperties(prefix = "payment.gateway")
public record PaymentGatewayProperties(
        String baseUrl,             // base du jeton : {endpoint_base}/generateToken
        String transactionBaseUrl,  // base des transactions : b2c_standard, crypt-cvv, check-transaction-status
        String login,
        String password,
        String apiKey,
        String keypass    // en-tête "keypass" des requêtes de paiement par carte
) {}
