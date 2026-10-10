package com.techinnov.kassouwata_back.controllers;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.techinnov.kassouwata_back.repositories.BoutiqueRepository;
import com.techinnov.kassouwata_back.repositories.CommandeRepository;
import com.techinnov.kassouwata_back.repositories.ProduitRepository;
import com.techinnov.kassouwata_back.repositories.TontineRepository;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosDashboards")
public class DashboardController {

    @Autowired
    private CommandeRepository commandeRepository;

    @Autowired
    private BoutiqueRepository boutiqueRepository;

    @Autowired
    private TontineRepository tontineRepository;

    @Autowired
    private ProduitRepository produitRepository;

    @GetMapping("/indicateurs")
    public Map<String, Object> getIndicateurs() {
        Map<String, Object> jo = new LinkedHashMap<>();

        // ── Utilisateurs ──────────────────────────────────────────
        jo.put("nombreClient",  commandeRepository.getNombreClient());
        jo.put("nombreVendeur", commandeRepository.getNombreVendeur());

        // ── Commandes ─────────────────────────────────────────────
        jo.put("nombreVentes",             commandeRepository.getNombreCommandes());
        jo.put("chiffresAffaires",         commandeRepository.getCA());
        jo.put("chiffresAffairesMois",     commandeRepository.getCAMoisCourant());
        jo.put("totalCommissions",         commandeRepository.getTotalCommissions());

        // Répartition par statut
        jo.put("commandesEnAttente",       commandeRepository.getNombreCommandesEnAttente());
        jo.put("commandesConfirmees",      commandeRepository.getNombreCommandesConfirmees());
        jo.put("commandesEnLivraison",     commandeRepository.getNombreCommandesEnLivraison());
        jo.put("commandesLivrees",         commandeRepository.getNombreCommandesLivrees());
        jo.put("commandesAnnulees",        commandeRepository.getNombreCommandesAnnulees());

        // ── Taux de livraison ─────────────────────────────────────
        int total    = commandeRepository.getNombreCommandes();
        int livrees  = commandeRepository.getNombreCommandesLivrees();
        double tauxLivraison = total > 0 ? Math.round((livrees * 100.0) / total) : 0;
        jo.put("tauxLivraison", tauxLivraison);

        // ── Boutiques ─────────────────────────────────────────────
        jo.put("boutiquesActives", boutiqueRepository.getNombreBoutiquesActives());
        jo.put("boutiquesTotal",   boutiqueRepository.getNombreBoutiquesTotal());

        // ── Produits ──────────────────────────────────────────────
        jo.put("produitsPublies", produitRepository.getNombreProduitsPublies());
        jo.put("produitsTotal",   produitRepository.getNombreProduitsTotal());

        // ── Tontines ──────────────────────────────────────────────
        jo.put("tontinesActives",      tontineRepository.getNombreTontines());
        jo.put("tontinesParticipants", tontineRepository.getNombreParticipants());

        // ── Évolution mensuelle (CA + commissions par mois, année courante) ──
        List<Object[]> rows = commandeRepository.getEvolutionMensuelle();
        List<Map<String, Object>> evolution = new ArrayList<>();
        for (Object[] row : rows) {
            Map<String, Object> point = new LinkedHashMap<>();
            point.put("mois",            ((Number) row[0]).intValue());
            point.put("chiffreAffaires", ((Number) row[1]).doubleValue());
            point.put("commissions",     ((Number) row[2]).doubleValue());
            evolution.add(point);
        }
        jo.put("evolutionMensuelle", evolution);

        return jo;
    }
}
