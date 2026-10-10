package com.techinnov.kassouwata_back.controllers.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Corps de la requête envoyée à l'agrégateur sur /generateToken :
 * { "login": "...", "password": "...", "api_key": "..." }
 */
public record PaymentTokenRequest(
        String login,
        String password,
        @JsonProperty("api_key") String apiKey
) {}
