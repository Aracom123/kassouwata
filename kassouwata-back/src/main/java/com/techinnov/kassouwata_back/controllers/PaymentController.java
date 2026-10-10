package com.techinnov.kassouwata_back.controllers;

import com.techinnov.kassouwata_back.controllers.dto.MobileMoneyPaymentRequest;
import com.techinnov.kassouwata_back.exceptions.PaymentGatewayException;
import com.techinnov.kassouwata_back.services.PaymentService;
import com.techinnov.kassouwata_back.services.TransactionPaiementService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/payment")
public class PaymentController {

    private final PaymentService paymentService;
    private final TransactionPaiementService transactionPaiementService;

    public PaymentController(PaymentService paymentService,
                             TransactionPaiementService transactionPaiementService) {
        this.paymentService = paymentService;
        this.transactionPaiementService = transactionPaiementService;
    }

    /**
     * Force la génération d'un nouveau jeton (utile pour les tests).
     * Les paiements n'en ont pas besoin : le jeton est géré automatiquement.
     * POST /api/payment/token
     */
    @PostMapping("/token")
    public ResponseEntity<Map<String, Object>> generateToken() {
        return ResponseEntity.ok(paymentService.generateToken());
    }

    /**
     * Effectue une transaction Mobile Money (opérateur télécom ou société de transfert)
     * et l'enregistre dans la table transaction.
     * POST /api/payment/mobile-money
     */
    @PostMapping("/mobile-money")
    public ResponseEntity<Map<String, Object>> payerMobileMoney(
            @Valid @RequestBody MobileMoneyPaymentRequest request) {
        return ResponseEntity.ok(transactionPaiementService.effectuerTransaction(request));
    }

    /**
     * Vérifie le statut d'une transaction auprès de l'agrégateur et met à jour la base.
     * À appeler par l'application après le paiement (ex. toutes les 5 s pendant 2 min)
     * pour afficher le résultat au client.
     * GET /api/payment/statut/{referenceExterne}
     */
    @GetMapping("/statut/{referenceExterne}")
    public ResponseEntity<Map<String, Object>> verifierStatut(@PathVariable String referenceExterne) {
        return ResponseEntity.ok(transactionPaiementService.verifierTransaction(referenceExterne));
    }

    /**
     * Situation de paiement d'une commande : montant total, payé, reste à payer,
     * statut de paiement et, pour une vente PREPAYE, le montant conseillé d'une tranche.
     * GET /api/payment/commande/{idCommande}/resume
     */
    @GetMapping("/commande/{idCommande}/resume")
    public ResponseEntity<Map<String, Object>> resumeCommande(@PathVariable Long idCommande) {
        return ResponseEntity.ok(transactionPaiementService.resumePaiementCommande(idCommande));
    }

    // ------------------------------------------------------------------
    // Gestion des erreurs (traitées ici pour ne pas passer par /error)
    // ------------------------------------------------------------------

    /** Erreurs de l'agrégateur -> 502 / 503. */
    @ExceptionHandler(PaymentGatewayException.class)
    public ResponseEntity<Map<String, Object>> handlePaymentError(PaymentGatewayException e) {
        Map<String, Object> body = error(e.getStatus(), e.getMessage());
        if (e.getResponseBody() != null) {
            body.put("details", e.getResponseBody());
        }
        return ResponseEntity.status(e.getStatus()).body(body);
    }

    /** Données incohérentes (numéro invalide, nomPrenom ou paysPayeur manquant...) -> 400. */
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleBadArgument(IllegalArgumentException e) {
        return ResponseEntity.badRequest().body(error(HttpStatus.BAD_REQUEST, e.getMessage()));
    }

    /** Champs obligatoires manquants (@NotNull, @NotBlank, @Positive) -> 400. */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException e) {
        String message = e.getBindingResult().getFieldErrors().stream()
                .map(f -> f.getField() + " : " + f.getDefaultMessage())
                .collect(Collectors.joining(", "));
        return ResponseEntity.badRequest().body(error(HttpStatus.BAD_REQUEST, message));
    }

    /** JSON illisible ou valeur inconnue (ex. fournisseur "orange_money") -> 400. */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, Object>> handleUnreadable(HttpMessageNotReadableException e) {
        Throwable cause = e.getMostSpecificCause();
        String message = cause instanceof IllegalArgumentException ? cause.getMessage()
                : "Corps de requête invalide : " + cause.getMessage();
        return ResponseEntity.badRequest().body(error(HttpStatus.BAD_REQUEST, message));
    }

    private static Map<String, Object> error(HttpStatus status, String message) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("error", message);   // même format que GlobalExceptionHandler
        body.put("status", status.value());
        return body;
    }
}
