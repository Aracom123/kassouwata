package com.techinnov.kassouwata_back.controllers;

import com.techinnov.kassouwata_back.services.PaiementAdminService;
import org.springframework.data.domain.Page;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Date;
import java.util.Map;

/**
 * Consultation des paiements depuis le back-office.
 * Accès réservé au profil ADMIN (cf. SecurityConfig : /api/payment/admin/**).
 */
@RestController
@RequestMapping("/api/payment/admin")
public class PaiementAdminController {

    private final PaiementAdminService paiementAdminService;

    public PaiementAdminController(PaiementAdminService paiementAdminService) {
        this.paiementAdminService = paiementAdminService;
    }

    /**
     * Liste paginée des transactions, avec filtres facultatifs.
     * GET /api/payment/admin/transactions?page=0&size=20&statut=REUSSIE&fournisseur=NITA
     *     &typeOperation=COMMANDE&recherche=CMD-12&commandeId=12&tontineId=3
     *     &dateDebut=2026-10-01&dateFin=2026-10-31
     * statut : EN_ATTENTE | REUSSIE | ECHOUEE | MANUELLE (anciennes transactions sans statut)
     */
    @GetMapping("/transactions")
    public Page<Map<String, Object>> transactions(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String statut,
            @RequestParam(required = false) String fournisseur,
            @RequestParam(required = false) String typeOperation,
            @RequestParam(required = false) String recherche,
            @RequestParam(required = false) Long commandeId,
            @RequestParam(required = false) Long tontineId,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") Date dateDebut,
            @RequestParam(required = false) @DateTimeFormat(pattern = "yyyy-MM-dd") Date dateFin) {
        return paiementAdminService.rechercher(
                new PaiementAdminService.Filtres(statut, fournisseur, typeOperation, recherche,
                        commandeId, tontineId, dateDebut, dateFin),
                page, size);
    }

    /** Détail d'une transaction, avec les réponses brutes de l'agrégateur. */
    @GetMapping("/transactions/{id}")
    public ResponseEntity<Map<String, Object>> detail(@PathVariable Long id) {
        return ResponseEntity.ok(paiementAdminService.detail(id));
    }

    /** Indicateurs : montants par statut, encaissements par fournisseur et par type, taux de réussite. */
    @GetMapping("/statistiques")
    public ResponseEntity<Map<String, Object>> statistiques() {
        return ResponseEntity.ok(paiementAdminService.statistiques());
    }
}
