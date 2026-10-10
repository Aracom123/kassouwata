package com.techinnov.kassouwata_back.exceptions;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

/**
 * Gestionnaire global d'exceptions.
 * Transforme les exceptions métier en réponses HTTP structurées
 * de la forme : {"error": "message lisible"}.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * BusinessException → 409 Conflict
     * Utilisée pour les violations de règles métier (ex: numéro/email déjà utilisé).
     */
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<Map<String, String>> handleBusiness(BusinessException ex) {
        return ResponseEntity
                .status(HttpStatus.CONFLICT)
                .body(Map.of("error", ex.getMessage()));
    }

    /**
     * ResponseStatusException → statut HTTP correspondant avec message dans {"error": "..."}.
     * Spring Boot 3 n'inclut pas le message par défaut dans le corps de la réponse,
     * ce handler garantit que le message est toujours renvoyé au client.
     */
    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, String>> handleResponseStatus(ResponseStatusException ex) {
        return ResponseEntity
                .status(ex.getStatusCode())
                .body(Map.of("error", ex.getReason() != null ? ex.getReason() : ex.getMessage()));
    }
}
