package com.techinnov.kassouwata_back.exceptions;

import org.springframework.http.HttpStatus;

/**
 * Erreur remontée lors d'un appel à l'agrégateur de paiement.
 */
public class PaymentGatewayException extends RuntimeException {

    private final HttpStatus status;
    private final String responseBody;

    public PaymentGatewayException(String message, HttpStatus status, String responseBody, Throwable cause) {
        super(message, cause);
        this.status = status;
        this.responseBody = responseBody;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public String getResponseBody() {
        return responseBody;
    }
}
