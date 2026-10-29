package com.techinnov.kassouwata_back.controllers;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Map;
import java.util.function.Supplier;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.techinnov.kassouwata_back.entitites.Tontine;
import com.techinnov.kassouwata_back.entitites.User;
import com.techinnov.kassouwata_back.repositories.TontineRepository;
import com.techinnov.kassouwata_back.repositories.UserRepository;
import com.techinnov.kassouwata_back.services.AdasheProduitService;

/**
 * Adashé Produit : achat groupé d'un produit (voir AdasheProduitService).
 * Les erreurs métier sont renvoyées sous la forme { "error": "message" }.
 */
@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosTontines/produit")
public class AdasheProduitController {

    private final AdasheProduitService service;
    private final UserRepository userRepository;
    private final TontineRepository tontineRepository;

    public AdasheProduitController(AdasheProduitService service, UserRepository userRepository,
                                   TontineRepository tontineRepository) {
        this.service = service;
        this.userRepository = userRepository;
        this.tontineRepository = tontineRepository;
    }

    /**
     * Créer un Adashé Produit.
     * { "idProduit": 12, "periodicite": "mensuelle", "nombrePeriodes": 6,
     *   "nombreMembres": 5, "dateDebut": "2026-11-01", "ouverte": true }
     */
    @PostMapping("")
    public ResponseEntity<?> creer(@RequestBody Map<String, Object> body) {
        return executer(() -> {
            Date debut = null;
            Object d = body.get("dateDebut");
            if (d != null && !d.toString().isBlank()) {
                try {
                    debut = new SimpleDateFormat("yyyy-MM-dd").parse(d.toString().substring(0, 10));
                } catch (Exception e) {
                    return ResponseEntity.badRequest().body(Map.of("error", "Date de début invalide."));
                }
            }
            Tontine t = service.creer(connecte(), entierLong(body.get("idProduit")),
                    (String) body.get("periodicite"), entier(body.get("nombrePeriodes")),
                    entier(body.get("nombreMembres")), debut, Boolean.TRUE.equals(body.get("ouverte")));
            return ResponseEntity.ok(service.resume(t));
        });
    }

    /** Fiche et progression d'un Adashé Produit. */
    @GetMapping("/{idTontine}")
    public ResponseEntity<?> resume(@PathVariable Long idTontine) {
        return executer(() -> tontineRepository.findById(idTontine)
                .<ResponseEntity<?>>map(t -> ResponseEntity.ok(service.resume(t)))
                .orElseGet(() -> ResponseEntity.status(404).body(Map.of("error", "Adashé introuvable."))));
    }

    /** Adashé ouverts d'un produit, à rejoindre. */
    @GetMapping("/de-produit/{idProduit}")
    public ResponseEntity<?> ouverts(@PathVariable Long idProduit) {
        return executer(() -> ResponseEntity.ok(service.ouverts(idProduit)));
    }

    /** Rejoindre un Adashé ouvert. */
    @PostMapping("/{idTontine}/rejoindre")
    public ResponseEntity<?> rejoindre(@PathVariable Long idTontine) {
        return executer(() -> {
            service.rejoindre(connecte(), idTontine);
            return ResponseEntity.ok(service.resume(tontineRepository.findById(idTontine).orElseThrow()));
        });
    }

    /** Décision du vendeur : { "accepte": true } ou { "accepte": false, "motif": "..." } */
    @PostMapping("/{idTontine}/decision")
    public ResponseEntity<?> decision(@PathVariable Long idTontine, @RequestBody Map<String, Object> body) {
        return executer(() -> {
            Tontine t = service.decisionVendeur(connecte(), idTontine,
                    Boolean.TRUE.equals(body.get("accepte")), (String) body.get("motif"));
            return ResponseEntity.ok(service.resume(t));
        });
    }

    /** Adashé Produit portant sur les produits d'une boutique (vue vendeur). */
    @GetMapping("/boutique/{idBoutique}")
    public ResponseEntity<?> pourBoutique(@PathVariable Long idBoutique) {
        return executer(() -> ResponseEntity.ok(service.pourBoutique(connecte(), idBoutique, estAdmin())));
    }

    // ── Outils ──────────────────────────────────────────────────────────────

    private ResponseEntity<?> executer(Supplier<ResponseEntity<?>> action) {
        try {
            return action.get();
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode())
                    .body(Map.of("error", e.getReason() != null ? e.getReason() : "Erreur"));
        }
    }

    private User connecte() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getName() == null) {
            throw new ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Connectez-vous.");
        }
        return userRepository.findByTelephone(auth.getName()).orElseThrow(() ->
                new ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Connectez-vous."));
    }

    private boolean estAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.getAuthorities().stream()
                .anyMatch(a -> "ROLE_ADMIN".equals(a.getAuthority()));
    }

    private static Integer entier(Object o) {
        if (o == null) return null;
        if (o instanceof Number n) return n.intValue();
        try { return Integer.parseInt(o.toString().trim()); } catch (NumberFormatException e) { return null; }
    }

    private static Long entierLong(Object o) {
        Integer i = entier(o);
        if (i == null) {
            throw new ResponseStatusException(org.springframework.http.HttpStatus.BAD_REQUEST, "Produit manquant.");
        }
        return i.longValue();
    }
}
