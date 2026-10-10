package com.techinnov.kassouwata_back.services;

import com.techinnov.kassouwata_back.config.PaymentGatewayProperties;
import com.techinnov.kassouwata_back.controllers.dto.B2cCartePayload;
import com.techinnov.kassouwata_back.controllers.dto.B2cStandardPayload;
import com.techinnov.kassouwata_back.controllers.dto.B2cTransfertPayload;
import com.techinnov.kassouwata_back.enums.StatutTransaction;
import com.techinnov.kassouwata_back.controllers.dto.MobileMoneyPaymentRequest;
import com.techinnov.kassouwata_back.controllers.dto.PaymentTokenRequest;
import com.techinnov.kassouwata_back.entitites.CategoriePaiement;
import com.techinnov.kassouwata_back.entitites.MoyenPaiement;
import com.techinnov.kassouwata_back.exceptions.PaymentGatewayException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Map;

/**
 * Appels vers l'agrégateur de moyens de paiement digitaux (Mobile Money, Carte).
 *
 * Le jeton d'accès est généré automatiquement au premier besoin, gardé en mémoire
 * et régénéré seulement quand il arrive à expiration (champ "expires", ~30 min).
 */
@Service
public class PaymentService {

    private static final Logger log = LoggerFactory.getLogger(PaymentService.class);

    /** Durée par défaut si "expires" est absent ou illisible. */
    private static final Duration DEFAULT_VALIDITY = Duration.ofMinutes(30);
    /** On renouvelle le jeton un peu avant son expiration réelle. */
    private static final Duration SAFETY_MARGIN = Duration.ofMinutes(1);

    private static final ParameterizedTypeReference<Map<String, Object>> JSON_MAP =
            new ParameterizedTypeReference<>() {};

    /** Client pour la génération du jeton (payment.gateway.base-url). */
    private final RestClient restClient;
    /** Client pour les transactions (payment.gateway.transaction-base-url). */
    private final RestClient transactionClient;
    private final PaymentGatewayProperties props;

    // Jeton en cache
    private String cachedToken;
    private Instant tokenExpiresAt = Instant.EPOCH;

    public PaymentService(RestClient.Builder builder, PaymentGatewayProperties props) {
        this.props = props;
        this.restClient = builder.clone()
                .baseUrl(props.baseUrl())
                .defaultHeader("Content-Type", MediaType.APPLICATION_JSON_VALUE)
                .build();
        this.transactionClient = builder.clone()
                .baseUrl(props.transactionBaseUrl())
                .defaultHeader("Content-Type", MediaType.APPLICATION_JSON_VALUE)
                .build();
        log.info("Agrégateur de paiement : jeton -> {}, transactions -> {}",
                props.baseUrl(), props.transactionBaseUrl());
    }

    // ------------------------------------------------------------------
    // Jeton
    // ------------------------------------------------------------------

    /**
     * Renvoie un jeton valide : celui en cache s'il n'a pas expiré,
     * sinon un nouveau jeton demandé à l'agrégateur.
     */
    public synchronized String getValidToken() {
        if (cachedToken == null || Instant.now().isAfter(tokenExpiresAt)) {
            refreshToken();
        }
        return cachedToken;
    }

    /** Force la génération d'un nouveau jeton et renvoie la réponse brute de l'agrégateur. */
    public synchronized Map<String, Object> generateToken() {
        return refreshToken();
    }

    private Map<String, Object> refreshToken() {
        PaymentTokenRequest body = new PaymentTokenRequest(
                props.login(), props.password(), props.apiKey());

        Map<String, Object> response = call("generateToken", () -> restClient.post()
                .uri("/generateToken")
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_JSON)
                .body(body)
                .retrieve()
                .body(JSON_MAP));

        // Réponse attendue :
        // {"code":200,"statut":true,"message":"Token généré avec succès","token":"...","expires":"30 minutes"}
        Object statut = response == null ? null : response.get("statut");
        Object token = response == null ? null : response.get("token");
        if (!Boolean.TRUE.equals(statut) || token == null || token.toString().isBlank()) {
            String message = response == null ? null : String.valueOf(response.get("message"));
            log.error("Échec generateToken : code={}, message={}",
                    response == null ? null : response.get("code"), message);
            throw new PaymentGatewayException(
                    "Échec de génération du jeton" + (message != null ? " : " + message : ""),
                    HttpStatus.BAD_GATEWAY, null, null);
        }

        Instant expiresAt = computeExpiry(response.get("expires"));
        this.cachedToken = token.toString();
        this.tokenExpiresAt = expiresAt.minus(SAFETY_MARGIN);
        log.info("Nouveau jeton de paiement obtenu, valide jusqu'à {}", expiresAt);
        return response;
    }

    private synchronized void invalidateToken() {
        cachedToken = null;
        tokenExpiresAt = Instant.EPOCH;
    }

    // ------------------------------------------------------------------
    // Paiement : Mobile Money, société de transfert (STA), carte bancaire
    // ------------------------------------------------------------------

    /**
     * Vérifie la demande selon la catégorie du moyen de paiement.
     * À appeler AVANT d'enregistrer la transaction (aucune ligne créée si la demande est invalide).
     *
     * @return le numéro de téléphone au format attendu (Mobile Money / STA), ou null pour une carte
     */
    public String validerEtNormaliser(MobileMoneyPaymentRequest req, MoyenPaiement moyen) {
        if (moyen == null || !moyen.isUtilisable()) {
            throw new IllegalArgumentException("Ce moyen de paiement n'est pas disponible pour le moment");
        }
        return switch (moyen.getCategorieCode()) {
            case CategoriePaiement.MOBILE_MONEY -> {
                requireText(req.nomPrenom(), "nomPrenom est obligatoire pour " + moyen.getLibelle());
                requireText(req.numeroTelephone(), "numeroTelephone est obligatoire pour " + moyen.getLibelle());
                yield normaliserNumeroLocal(req.numeroTelephone());
            }
            case CategoriePaiement.STA -> {
                requireText(req.paysPayeur(), "paysPayeur est obligatoire pour " + moyen.getLibelle());
                requireText(req.numeroTelephone(), "numeroTelephone est obligatoire pour " + moyen.getLibelle());
                yield normaliserNumeroInternational(req.numeroTelephone());
            }
            case CategoriePaiement.CARTE -> {
                validerCarte(req);
                yield null;
            }
            default -> throw new IllegalArgumentException("Catégorie de paiement non prise en charge : "
                    + moyen.getCategorieCode());
        };
    }

    /**
     * Envoie la transaction à KomiPay : POST {endpoint_base}/b2c_standard.
     * Le corps dépend de la catégorie ; pour une carte, le CVV est d'abord chiffré (/crypt-cvv)
     * et l'en-tête "keypass" est ajouté.
     *
     * @param telephone numéro normalisé par validerEtNormaliser (null pour une carte)
     * @param reference reference_externe unique de la transaction
     */
    public Map<String, Object> envoyerB2c(MobileMoneyPaymentRequest req, MoyenPaiement moyen,
                                          String telephone, String reference) {
        String montant = formatMontant(req.montant());
        String categorie = moyen.getCategorieCode();

        log.info("Paiement {} ({}) : {} FCFA, {} n°{}, référence {}",
                moyen.getCode(), categorie, req.montant(), req.typeOperation(), req.operationId(), reference);

        return switch (categorie) {
            case CategoriePaiement.MOBILE_MONEY -> post("b2c_standard", "/b2c_standard",
                    new B2cStandardPayload(moyen.getCodeAgregateur(), props.apiKey(), montant,
                            telephone, req.nomPrenom().trim(), reference), false);
            case CategoriePaiement.STA -> post("b2c_standard", "/b2c_standard",
                    new B2cTransfertPayload(moyen.getCodeAgregateur(), props.apiKey(), montant,
                            telephone, req.paysPayeur().trim(), reference), false);
            case CategoriePaiement.CARTE -> {
                String cvvChiffre = chiffrerCvv(req.cvv().trim());
                yield post("b2c_standard (carte)", "/b2c_standard",
                        new B2cCartePayload(
                                moyen.getCodeAgregateur(),          // "bank_card"
                                props.apiKey(),
                                req.nomPrenom().trim(),
                                formaterNumeroCarte(req.numeroCarte()),
                                normaliserDateExpiration(req.dateExpiration()),
                                cvvChiffre,
                                montant,
                                reference,
                                false,
                                false,
                                String.valueOf(req.hauteurEcran() != null ? req.hauteurEcran() : 960),
                                String.valueOf(req.largeurEcran() != null ? req.largeurEcran() : 1536),
                                "1",      // fuseau horaire du Niger (UTC+1)
                                "05"),    // fenêtre 3DS plein écran
                        true);
            }
            default -> throw new IllegalArgumentException("Catégorie de paiement non prise en charge : " + categorie);
        };
    }

    /** POST {endpoint_base}/crypt-cvv : renvoie le CVV chiffré à transmettre dans cvv_number. */
    private String chiffrerCvv(String cvv) {
        Map<String, Object> body = new java.util.LinkedHashMap<>();
        body.put("api_key", props.apiKey());
        body.put("cvv_number", cvv);
        Map<String, Object> reponse = post("crypt-cvv", "/crypt-cvv", body, true);

        Object chiffre = reponse == null ? null
                : reponse.getOrDefault("cvv_encrpyt", reponse.get("cvv_encrypt"));  // la doc écrit "encrpyt"
        if (!Boolean.TRUE.equals(reponse == null ? null : reponse.get("statut"))
                || chiffre == null || chiffre.toString().isBlank()) {
            String message = reponse == null ? null : String.valueOf(reponse.get("message"));
            throw new PaymentGatewayException("Échec du chiffrement du CVV" + (message != null ? " : " + message : ""),
                    HttpStatus.BAD_GATEWAY, null, null);
        }
        return chiffre.toString();
    }

    // ------------------------------------------------------------------
    // Carte bancaire : contrôles
    // ------------------------------------------------------------------

    private static void validerCarte(MobileMoneyPaymentRequest req) {
        requireText(req.nomPrenom(), "nomPrenom (titulaire de la carte) est obligatoire");
        requireText(req.numeroCarte(), "numeroCarte est obligatoire");
        requireText(req.dateExpiration(), "dateExpiration est obligatoire (MM/AA)");
        requireText(req.cvv(), "cvv est obligatoire");

        String chiffres = req.numeroCarte().replaceAll("[^0-9]", "");
        if (chiffres.length() < 13 || chiffres.length() > 19 || !luhnValide(chiffres)) {
            throw new IllegalArgumentException("Numéro de carte invalide");
        }
        if (detecterMarqueCarte(chiffres) == null) {
            throw new IllegalArgumentException("Seules les cartes Visa et MasterCard sont acceptées");
        }
        if (!req.cvv().trim().matches("\\d{3,4}")) {
            throw new IllegalArgumentException("CVV invalide (3 ou 4 chiffres)");
        }
        String expiration = normaliserDateExpiration(req.dateExpiration());
        int mois = Integer.parseInt(expiration.substring(0, 2));
        int annee = 2000 + Integer.parseInt(expiration.substring(3, 5));
        java.time.YearMonth finValidite = java.time.YearMonth.of(annee, mois);
        if (finValidite.isBefore(java.time.YearMonth.now())) {
            throw new IllegalArgumentException("Cette carte est expirée");
        }
    }

    /** VISA (commence par 4) ou MASTERCARD (51-55 ou 2221-2720), sinon null. */
    public static String detecterMarqueCarte(String numero) {
        String c = numero == null ? "" : numero.replaceAll("[^0-9]", "");
        if (c.startsWith("4")) return "VISA";
        if (c.length() >= 2) {
            int deux = Integer.parseInt(c.substring(0, 2));
            if (deux >= 51 && deux <= 55) return "MASTERCARD";
        }
        if (c.length() >= 4) {
            int quatre = Integer.parseInt(c.substring(0, 4));
            if (quatre >= 2221 && quatre <= 2720) return "MASTERCARD";
        }
        return null;
    }

    private static boolean luhnValide(String chiffres) {
        int somme = 0;
        boolean doubler = false;
        for (int i = chiffres.length() - 1; i >= 0; i--) {
            int d = chiffres.charAt(i) - '0';
            if (doubler) {
                d *= 2;
                if (d > 9) d -= 9;
            }
            somme += d;
            doubler = !doubler;
        }
        return somme % 10 == 0;
    }

    /** "5555555555554444" -> "5555-5555-5555-4444" (format de la documentation KomiPay). */
    private static String formaterNumeroCarte(String numero) {
        String c = numero.replaceAll("[^0-9]", "");
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < c.length(); i++) {
            if (i > 0 && i % 4 == 0) sb.append('-');
            sb.append(c.charAt(i));
        }
        return sb.toString();
    }

    /** "12/27", "12/2027", "1227" -> "12/27". */
    private static String normaliserDateExpiration(String date) {
        String c = date.replaceAll("[^0-9]", "");
        if (c.length() == 6) c = c.substring(0, 2) + c.substring(4);   // MMAAAA -> MMAA
        if (c.length() != 4) {
            throw new IllegalArgumentException("Date d'expiration invalide (format attendu : MM/AA)");
        }
        int mois = Integer.parseInt(c.substring(0, 2));
        if (mois < 1 || mois > 12) {
            throw new IllegalArgumentException("Date d'expiration invalide (mois entre 01 et 12)");
        }
        return c.substring(0, 2) + "/" + c.substring(2);
    }

    /** Opérateur télécom : numéro local à 8 chiffres (96XXXXXX). Accepte +227, 00227 ou 227 en préfixe. */
    private static String normaliserNumeroLocal(String numero) {
        String chiffres = numero.replaceAll("[^0-9]", "");
        if (chiffres.length() == 13 && chiffres.startsWith("00227")) chiffres = chiffres.substring(5);
        if (chiffres.length() == 11 && chiffres.startsWith("227"))   chiffres = chiffres.substring(3);
        if (chiffres.length() != 8) {
            throw new IllegalArgumentException("Numéro de téléphone invalide pour un opérateur : "
                    + numero + " (attendu : 8 chiffres, ex. 96000000)");
        }
        return chiffres;
    }

    /** Société de transfert : numéro international (+227XXXXXXXX). Un numéro à 8 chiffres est considéré nigérien. */
    private static String normaliserNumeroInternational(String numero) {
        String brut = numero.trim();
        String chiffres = brut.replaceAll("[^0-9]", "");
        if (chiffres.startsWith("00")) chiffres = chiffres.substring(2);
        else if (chiffres.length() == 8 && !brut.startsWith("+")) chiffres = "227" + chiffres;
        if (chiffres.length() < 10 || chiffres.length() > 15) {
            throw new IllegalArgumentException("Numéro de téléphone invalide pour un transfert : "
                    + numero + " (attendu : format international, ex. +22796000000)");
        }
        return "+" + chiffres;
    }

    private static void requireText(String value, String message) {
        if (value == null || value.isBlank()) throw new IllegalArgumentException(message);
    }

    /**
     * POST authentifié (jeton Bearer, et "keypass" pour les opérations carte).
     * Si le jeton est refusé (401), il est régénéré et la requête renvoyée une fois.
     */
    private Map<String, Object> post(String operation, String uri, Object body, boolean avecKeypass) {
        try {
            return postOnce(operation, uri, body, avecKeypass, true);
        } catch (HttpClientErrorException.Unauthorized e) {
            log.warn("Jeton refusé par l'agrégateur ({}), régénération et nouvel essai", operation);
            invalidateToken();
            return postOnce(operation, uri, body, avecKeypass, false);
        }
    }

    private Map<String, Object> postOnce(String operation, String uri, Object body,
                                         boolean avecKeypass, boolean allowRetry) {
        String token = getValidToken();
        return call(operation, () -> {
            RestClient.RequestBodySpec requete = transactionClient.post()
                    .uri(uri)
                    .contentType(MediaType.APPLICATION_JSON)
                    .accept(MediaType.APPLICATION_JSON)
                    .header("Authorization", "Bearer " + token);
            if (avecKeypass) {
                requete = requete.header("keypass", props.keypass());
            }
            return requete.body(body).retrieve().body(JSON_MAP);
        }, allowRetry);
    }

    // ------------------------------------------------------------------
    // Vérification du statut d'une transaction
    // ------------------------------------------------------------------

    /**
     * Résultat d'une vérification.
     * @param statut REUSSIE, ECHOUEE, ou null si l'agrégateur ne donne pas encore de résultat
     */
    public record VerificationStatut(int codeHttp, Map<String, Object> reponse, StatutTransaction statut) {}

    /**
     * POST {endpoint_base}/check-transaction-status
     * Corps : {"apikey": "...", "reference_transaction": "..."}
     *
     * Attention : un paiement en échec est renvoyé avec un code HTTP 4xx.
     * On lit donc le corps de la réponse au lieu de traiter le 4xx comme une erreur.
     */
    public VerificationStatut verifierStatut(String referenceTransaction) {
        Map<String, Object> payload = new java.util.LinkedHashMap<>();
        payload.put("apikey", props.apiKey());
        payload.put("reference_transaction", referenceTransaction);

        VerificationStatut resultat = checkOnce(payload);
        if (resultat.codeHttp() == 401 && resultat.statut() == null) {
            // 401 sans résultat de transaction : jeton refusé -> nouveau jeton et nouvel essai
            log.warn("Jeton refusé lors de la vérification de {}, régénération", referenceTransaction);
            invalidateToken();
            resultat = checkOnce(payload);
        }
        log.info("Vérification {} : HTTP {}, statut {}", referenceTransaction,
                resultat.codeHttp(), resultat.statut() == null ? "inchangé" : resultat.statut());
        return resultat;
    }

    private VerificationStatut checkOnce(Map<String, Object> payload) {
        String token = getValidToken();
        try {
            return transactionClient.post()
                    .uri("/check-transaction-status")
                    .contentType(MediaType.APPLICATION_JSON)
                    .accept(MediaType.APPLICATION_JSON)
                    .header("Authorization", "Bearer " + token)
                    .body(payload)
                    .exchange((request, response) -> {
                        int code = response.getStatusCode().value();
                        Map<String, Object> body = null;
                        try {
                            body = response.bodyTo(JSON_MAP);
                        } catch (Exception e) {
                            log.warn("Réponse de check-transaction-status illisible (HTTP {})", code);
                        }
                        return new VerificationStatut(code, body, interpreterStatut(body));
                    });
        } catch (ResourceAccessException e) {
            log.error("Agrégateur injoignable (check-transaction-status) : {}", e.getMessage());
            throw new PaymentGatewayException("Agrégateur de paiement injoignable",
                    HttpStatus.SERVICE_UNAVAILABLE, null, e);
        }
    }

    /**
     * Lit data.transactionStatus : "Success" -> REUSSIE, "Echec" -> ECHOUEE.
     * Toute autre valeur (ou absence) -> null : la transaction reste EN_ATTENTE.
     * On ne se fie pas au seul "statut": false, pour ne pas classer en échec
     * un paiement que le client n'a simplement pas encore validé.
     */
    @SuppressWarnings("unchecked")
    static StatutTransaction interpreterStatut(Map<String, Object> body) {
        if (body == null || !(body.get("data") instanceof Map<?, ?> data)) return null;
        Object ts = ((Map<String, Object>) data).get("transactionStatus");
        if (ts == null) return null;
        String s = java.text.Normalizer.normalize(ts.toString().trim(), java.text.Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "").toLowerCase();
        if (s.equals("success") || s.equals("succes") || s.equals("successful") || s.equals("reussi")) {
            return StatutTransaction.REUSSIE;
        }
        if (s.equals("echec") || s.equals("failed") || s.equals("failure") || s.equals("echoue")) {
            return StatutTransaction.ECHOUEE;
        }
        return null;
    }

    // ------------------------------------------------------------------
    // Utilitaires
    // ------------------------------------------------------------------

    /** Extrait le champ "message" d'une réponse d'erreur JSON de l'agrégateur (sinon null). */
    private static String messageAgregateur(String corps) {
        if (corps == null || corps.isBlank()) return null;
        java.util.regex.Matcher m = java.util.regex.Pattern
                .compile("\"message\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"")
                .matcher(corps);
        if (m.find()) return m.group(1);
        String brut = corps.strip();
        return brut.length() <= 150 && !brut.startsWith("<") ? brut : null;
    }

    private <T> T call(String operation, java.util.function.Supplier<T> request) {
        return call(operation, request, false);
    }

    /**
     * Exécute un appel et traduit les erreurs en PaymentGatewayException.
     * @param rethrowUnauthorized laisse passer le 401 pour permettre la régénération du jeton
     */
    private <T> T call(String operation, java.util.function.Supplier<T> request, boolean rethrowUnauthorized) {
        try {
            return request.get();
        } catch (HttpClientErrorException.Unauthorized e) {
            if (rethrowUnauthorized) throw e;
            log.error("Erreur {} [401] : {}", operation, e.getResponseBodyAsString());
            throw new PaymentGatewayException("Identifiants refusés par l'agrégateur",
                    HttpStatus.BAD_GATEWAY, e.getResponseBodyAsString(), e);
        } catch (RestClientResponseException e) {
            log.error("Erreur {} [{}] : {}", operation, e.getStatusCode(), e.getResponseBodyAsString());
            String detail = messageAgregateur(e.getResponseBodyAsString());
            throw new PaymentGatewayException("L'agrégateur a refusé la requête " + operation
                    + " (HTTP " + e.getStatusCode().value() + ")" + (detail != null ? " : " + detail : ""),
                    HttpStatus.BAD_GATEWAY, e.getResponseBodyAsString(), e);
        } catch (ResourceAccessException e) {
            log.error("Agrégateur injoignable ({}) : {}", operation, e.getMessage());
            throw new PaymentGatewayException("Agrégateur de paiement injoignable",
                    HttpStatus.SERVICE_UNAVAILABLE, null, e);
        }
    }

    /** 5000 -> "5 000", comme dans la documentation de l'agrégateur. */
    private static String formatMontant(Long montant) {
        return String.format(java.util.Locale.ROOT, "%,d", montant).replace(',', ' ');
    }

    /** "30 minutes", "1 heure", "1800 secondes"... */
    private static final java.util.regex.Pattern DURATION_TEXT =
            java.util.regex.Pattern.compile("(\\d+)\\s*(s|sec|secondes?|seconds?|mn|min|minutes?|h|heures?|hours?)",
                    java.util.regex.Pattern.CASE_INSENSITIVE);

    /**
     * Interprète le champ "expires". Format actuel de l'agrégateur : "30 minutes".
     * Accepte aussi une durée numérique, un timestamp ou une date, au cas où le format évolue.
     */
    private static Instant computeExpiry(Object expires) {
        Instant now = Instant.now();
        if (expires == null) return now.plus(DEFAULT_VALIDITY);

        String raw = expires.toString().trim();

        java.util.regex.Matcher m = DURATION_TEXT.matcher(raw);
        if (m.matches()) {
            long n = Long.parseLong(m.group(1));
            String unit = m.group(2).toLowerCase();
            if (unit.startsWith("h")) return now.plus(Duration.ofHours(n));
            if (unit.startsWith("s")) return now.plusSeconds(n);
            return now.plus(Duration.ofMinutes(n));
        }

        try {
            long n = (long) Double.parseDouble(raw);
            if (n > 1_000_000_000_000L) return Instant.ofEpochMilli(n);    // timestamp ms
            if (n > 1_000_000_000L)     return Instant.ofEpochSecond(n);   // timestamp s
            if (n > 120)                return now.plusSeconds(n);         // durée en secondes
            if (n > 0)                  return now.plus(Duration.ofMinutes(n)); // durée en minutes
        } catch (NumberFormatException ignored) {
            // pas un nombre : on essaie une date
        }
        try {
            return OffsetDateTime.parse(raw).toInstant();
        } catch (Exception ignored) { }
        try {
            return LocalDateTime.parse(raw.replace(' ', 'T')).atZone(ZoneId.systemDefault()).toInstant();
        } catch (Exception ignored) { }
        try {
            return LocalDateTime.parse(raw, DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss"))
                    .atZone(ZoneId.systemDefault()).toInstant();
        } catch (Exception ignored) { }

        log.warn("Format de 'expires' non reconnu ({}), validité de 30 min appliquée", raw);
        return now.plus(DEFAULT_VALIDITY);
    }
}
