package com.techinnov.kassouwata_back.services;

import com.techinnov.kassouwata_back.entitites.Personne;
import com.techinnov.kassouwata_back.entitites.Transaction;
import com.techinnov.kassouwata_back.entitites.User;
import com.techinnov.kassouwata_back.repositories.TransactionRepository;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Consultation des paiements pour le back-office (réservé aux administrateurs).
 *
 * Les transactions sont renvoyées "à plat" (identifiants au lieu des entités liées)
 * pour éviter de charger commandes, tontines et utilisateurs complets.
 * Les anciennes transactions sans statut (enregistrées avant l'agrégateur)
 * apparaissent avec le statut "MANUELLE".
 */
@Service
public class PaiementAdminService {

    public static final String STATUT_MANUELLE = "MANUELLE";

    private final TransactionRepository transactionRepository;

    public PaiementAdminService(TransactionRepository transactionRepository) {
        this.transactionRepository = transactionRepository;
    }

    /** Filtres de recherche, tous facultatifs. */
    public record Filtres(String statut, String fournisseur, String typeOperation, String recherche,
                          Long commandeId, Long tontineId, Date dateDebut, Date dateFin) {}

    @Transactional(readOnly = true)
    public Page<Map<String, Object>> rechercher(Filtres filtres, int page, int size) {
        PageRequest pageRequest = PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 200),
                Sort.by(Sort.Direction.DESC, "dateTransaction").and(Sort.by(Sort.Direction.DESC, "idTransaction")));
        return transactionRepository.findAll(specification(filtres), pageRequest).map(this::versLigne);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> detail(Long idTransaction) {
        Transaction t = transactionRepository.findById(idTransaction)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Transaction introuvable : " + idTransaction));
        Map<String, Object> detail = versLigne(t);
        detail.put("reponseAgregateur", t.getReponseAgregateur());
        detail.put("reponseVerification", t.getReponseVerification());
        detail.put("creePar", t.getCreated_by());
        detail.put("creeLe", t.getCreated_at());
        detail.put("modifieLe", t.getModified_at());
        return detail;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> statistiques() {
        Map<String, Object> parStatut = new LinkedHashMap<>();
        for (String s : List.of("REUSSIE", "EN_ATTENTE", "ECHOUEE", STATUT_MANUELLE)) {
            parStatut.put(s, compteur(0L, 0.0));
        }
        long nombreTotal = 0;
        for (Object[] row : transactionRepository.statistiquesParStatut()) {
            String statut = row[0] == null ? STATUT_MANUELLE : row[0].toString();
            long nombre = ((Number) row[1]).longValue();
            double montant = ((Number) row[2]).doubleValue();
            parStatut.put(statut, compteur(nombre, montant));
            nombreTotal += nombre;
        }

        long reussies = nombre(parStatut, "REUSSIE");
        long echouees = nombre(parStatut, "ECHOUEE");
        Double tauxReussite = (reussies + echouees) > 0
                ? Math.round(1000.0 * reussies / (reussies + echouees)) / 10.0
                : null;

        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("nombreTotal", nombreTotal);
        stats.put("parStatut", parStatut);
        stats.put("montantEncaisse", montant(parStatut, "REUSSIE"));
        stats.put("montantEnAttente", montant(parStatut, "EN_ATTENTE"));
        stats.put("tauxReussite", tauxReussite);
        stats.put("parFournisseur", lignes(transactionRepository.encaissementsParFournisseur(), "fournisseur"));
        stats.put("parTypeOperation", lignes(transactionRepository.encaissementsParTypeOperation(), "typeOperation"));
        return stats;
    }

    // ------------------------------------------------------------------
    // Filtres
    // ------------------------------------------------------------------

    private Specification<Transaction> specification(Filtres f) {
        return (root, query, cb) -> {
            List<Predicate> p = new ArrayList<>();

            if (estRenseigne(f.statut())) {
                if (STATUT_MANUELLE.equalsIgnoreCase(f.statut())) {
                    p.add(cb.isNull(root.get("statut")));
                } else {
                    p.add(cb.equal(root.get("statut"), f.statut().toUpperCase()));
                }
            }
            if (estRenseigne(f.fournisseur())) {
                p.add(cb.equal(root.get("moyenPaiement"), f.fournisseur().toUpperCase()));
            }
            if (estRenseigne(f.typeOperation())) {
                String type = f.typeOperation().toUpperCase();
                if ("COMMANDE".equals(type)) {
                    // Les anciennes transactions n'ont pas de typeOperation mais sont liées à une commande
                    p.add(cb.or(cb.equal(root.get("typeOperation"), type),
                            cb.and(cb.isNull(root.get("typeOperation")), cb.isNotNull(root.get("commande")))));
                } else {
                    p.add(cb.equal(root.get("typeOperation"), type));
                }
            }
            if (f.commandeId() != null) {
                p.add(cb.equal(root.get("commande").get("idCommande"), f.commandeId()));
            }
            if (f.tontineId() != null) {
                p.add(cb.equal(root.get("tontine").get("idTontine"), f.tontineId()));
            }
            if (estRenseigne(f.recherche())) {
                String motif = "%" + f.recherche().trim().toLowerCase() + "%";
                p.add(cb.or(
                        cb.like(cb.lower(root.get("referenceExterne")), motif),
                        cb.like(cb.lower(root.get("telephonePayeur")), motif)));
            }
            if (f.dateDebut() != null) {
                p.add(cb.greaterThanOrEqualTo(root.get("dateTransaction"), f.dateDebut()));
            }
            if (f.dateFin() != null) {
                p.add(cb.lessThan(root.get("dateTransaction"), finDeJournee(f.dateFin())));
            }
            return cb.and(p.toArray(new Predicate[0]));
        };
    }

    // ------------------------------------------------------------------
    // Conversion
    // ------------------------------------------------------------------

    private Map<String, Object> versLigne(Transaction t) {
        Map<String, Object> l = new LinkedHashMap<>();
        l.put("idTransaction", t.getIdTransaction());
        l.put("referenceExterne", t.getReferenceExterne());
        l.put("dateTransaction", t.getDateTransaction());
        l.put("montant", t.getMontant());
        l.put("statut", t.getStatut() != null ? t.getStatut() : STATUT_MANUELLE);
        l.put("typeOperation", t.getTypeOperation() != null ? t.getTypeOperation()
                : (t.getCommande() != null ? "COMMANDE" : null));
        l.put("commandeId", t.getCommande() != null ? t.getCommande().getIdCommande() : null);
        l.put("tontineId", t.getTontineId());
        l.put("periodeVersementId", t.getPeriodeVersementId());
        l.put("modePaiement", t.getModePaiement());
        l.put("fournisseur", t.getMoyenPaiement());
        l.put("telephonePayeur", t.getTelephonePayeur());
        l.put("nomPayeur", t.getNomPayeur());
        l.put("numeroCarteMasque", t.getNumeroCarteMasque());
        l.put("dateVerification", t.getDateVerification());

        User u = t.getUtilisateur();
        if (u != null) {
            l.put("payeurTelephone", u.getTelephone());
            Personne p = u.getPersonne();
            if (p != null) {
                l.put("payeurNom", ((p.getPrenom() != null ? p.getPrenom() + " " : "")
                        + (p.getNom() != null ? p.getNom() : "")).trim());
            }
        }
        return l;
    }

    // ------------------------------------------------------------------
    // Utilitaires
    // ------------------------------------------------------------------

    private static boolean estRenseigne(String s) {
        return s != null && !s.isBlank();
    }

    private static Date finDeJournee(Date date) {
        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.add(Calendar.DAY_OF_MONTH, 1);
        c.set(Calendar.HOUR_OF_DAY, 0);
        c.set(Calendar.MINUTE, 0);
        c.set(Calendar.SECOND, 0);
        c.set(Calendar.MILLISECOND, 0);
        return c.getTime();
    }

    private static Map<String, Object> compteur(long nombre, double montant) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("nombre", nombre);
        m.put("montant", montant);
        return m;
    }

    @SuppressWarnings("unchecked")
    private static long nombre(Map<String, Object> parStatut, String statut) {
        return ((Number) ((Map<String, Object>) parStatut.get(statut)).get("nombre")).longValue();
    }

    @SuppressWarnings("unchecked")
    private static double montant(Map<String, Object> parStatut, String statut) {
        return ((Number) ((Map<String, Object>) parStatut.get(statut)).get("montant")).doubleValue();
    }

    private static List<Map<String, Object>> lignes(List<Object[]> rows, String cle) {
        List<Map<String, Object>> resultat = new ArrayList<>();
        for (Object[] row : rows) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put(cle, row[0]);
            m.put("nombre", ((Number) row[1]).longValue());
            m.put("montant", ((Number) row[2]).doubleValue());
            resultat.add(m);
        }
        return resultat;
    }
}
