package com.techinnov.kassouwata_back.services;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.techinnov.kassouwata_back.entitites.Boutique;
import com.techinnov.kassouwata_back.entitites.DemandeAdhesion;
import com.techinnov.kassouwata_back.entitites.Produit;
import com.techinnov.kassouwata_back.entitites.Sms;
import com.techinnov.kassouwata_back.entitites.Tontine;
import com.techinnov.kassouwata_back.entitites.TontinePeriodeVersement;
import com.techinnov.kassouwata_back.entitites.User;
import com.techinnov.kassouwata_back.enums.BoutiqueStatus;
import com.techinnov.kassouwata_back.enums.DemandeAdhesionStatus;
import com.techinnov.kassouwata_back.enums.StatutAdashe;
import com.techinnov.kassouwata_back.enums.TypeAdashe;
import com.techinnov.kassouwata_back.repositories.DemandeAdhesionRepository;
import com.techinnov.kassouwata_back.repositories.ProduitRepository;
import com.techinnov.kassouwata_back.repositories.TontinePeriodeVersementRepository;
import com.techinnov.kassouwata_back.repositories.TontineRepository;
import com.techinnov.kassouwata_back.repositories.TontineVersementRepository;

/**
 * Adashé Produit : un groupe se réunit pour acheter UN produit d'une boutique.
 *
 * 1. Un acheteur crée l'Adashé sur un produit « payable en Adashé » : il choisit
 *    la périodicité, le nombre de périodes et le nombre de membres ; le montant
 *    par membre et par période est calculé pour atteindre le prix du produit.
 * 2. Le vendeur accepte (les périodes de cotisation sont alors générées) ou refuse.
 * 3. Les membres rejoignent (Adashé ouvert) ou sont invités, dans la limite prévue.
 * 4. Quand les cotisations couvrent le prix, l'objectif est atteint : vendeur et
 *    créateur sont prévenus par SMS pour la livraison.
 */
@Service
public class AdasheProduitService {

    static final Set<String> PERIODICITES =
            Set.of("quotidienne", "hebdomadaire", "mensuelle", "trimestrielle", "annuelle");

    private final TontineRepository tontineRepository;
    private final ProduitRepository produitRepository;
    private final DemandeAdhesionRepository demandeRepository;
    private final TontinePeriodeVersementRepository periodeRepository;
    private final TontineVersementRepository versementRepository;
    private final SmsService smsService;

    public AdasheProduitService(TontineRepository tontineRepository,
                                ProduitRepository produitRepository,
                                DemandeAdhesionRepository demandeRepository,
                                TontinePeriodeVersementRepository periodeRepository,
                                TontineVersementRepository versementRepository,
                                SmsService smsService) {
        this.tontineRepository = tontineRepository;
        this.produitRepository = produitRepository;
        this.demandeRepository = demandeRepository;
        this.periodeRepository = periodeRepository;
        this.versementRepository = versementRepository;
        this.smsService = smsService;
    }

    // ── Calcul ──────────────────────────────────────────────────────────────

    /** Montant par membre et par période (arrondi au franc supérieur). */
    public static double montantParMembre(double prix, int membres, int periodes) {
        return Math.ceil(prix / ((double) membres * periodes));
    }

    // ── Création ────────────────────────────────────────────────────────────

    @Transactional
    public Tontine creer(User createur, Long idProduit, String periodicite, Integer nombrePeriodes,
                         Integer nombreMembres, Date dateDebut, Boolean ouverte) {
        Produit produit = produitRepository.findById(idProduit)
                .orElseThrow(() -> erreur(HttpStatus.NOT_FOUND, "Produit introuvable."));
        if (!Boolean.TRUE.equals(produit.getAdasheAutorise())) {
            throw erreur(HttpStatus.BAD_REQUEST, "Ce produit ne peut pas être acheté en Adashé.");
        }
        Boutique boutique = produit.getBoutique();
        if (boutique == null || boutique.getStatus() != BoutiqueStatus.ACTIVE) {
            throw erreur(HttpStatus.BAD_REQUEST, "La boutique de ce produit n'est pas active.");
        }
        if (periodicite == null || !PERIODICITES.contains(periodicite.toLowerCase())) {
            throw erreur(HttpStatus.BAD_REQUEST, "Périodicité invalide.");
        }
        if (nombrePeriodes == null || nombrePeriodes < 1 || nombrePeriodes > 60) {
            throw erreur(HttpStatus.BAD_REQUEST, "Le nombre de périodes doit être compris entre 1 et 60.");
        }
        if (nombreMembres == null || nombreMembres < 2 || nombreMembres > 100) {
            throw erreur(HttpStatus.BAD_REQUEST, "Le nombre de membres doit être compris entre 2 et 100.");
        }
        double prix = produit.getPrixUnitaire();
        if (prix <= 0) {
            throw erreur(HttpStatus.BAD_REQUEST, "Ce produit n'a pas de prix.");
        }

        Tontine t = new Tontine();
        t.setTypeAdashe(TypeAdashe.PRODUIT);
        t.setStatutAdashe(StatutAdashe.EN_ATTENTE_VENDEUR);
        t.setProduit(produit);
        t.setLibelle("Adashé " + produit.getLibelle());
        t.setDescription("Achat groupé de « " + produit.getLibelle() + " » ("
                + boutique.getLibelle() + ")");
        t.setPeriodicite(periodicite.toLowerCase());
        t.setNombrePeriodes(nombrePeriodes);
        t.setNombreMembres(nombreMembres);
        t.setMontantCible(prix);
        t.setMontant(montantParMembre(prix, nombreMembres, nombrePeriodes));
        t.setOuverte(Boolean.TRUE.equals(ouverte));
        t.setDateDebut(dateDebut);
        t.setTontineOwner(createur);
        t = tontineRepository.save(t);

        // Le créateur est le premier membre
        ajouterMembre(t, createur);

        sms(boutique.getVendeur(), "Nouvelle demande d'Adashe pour \"" + produit.getLibelle()
                + "\" (" + nombreMembres + " membres). Acceptez ou refusez dans KASUWATA My Buz, espace Vendeur.");
        return t;
    }

    // ── Décision du vendeur ─────────────────────────────────────────────────

    @Transactional
    public Tontine decisionVendeur(User vendeur, Long idTontine, boolean accepte, String motif) {
        Tontine t = adasheProduit(idTontine);
        Boutique boutique = t.getProduit().getBoutique();
        if (boutique == null || boutique.getVendeur() == null
                || !Objects.equals(boutique.getVendeur().getIdUser(), vendeur.getIdUser())) {
            throw erreur(HttpStatus.FORBIDDEN, "Seul le vendeur du produit peut répondre à cette demande.");
        }
        if (t.statutEffectif() != StatutAdashe.EN_ATTENTE_VENDEUR) {
            throw erreur(HttpStatus.CONFLICT, "Cette demande a déjà été traitée.");
        }

        if (!accepte) {
            t.setStatutAdashe(StatutAdashe.REFUSE);
            t.setMotifRefus(motif);
            t = tontineRepository.save(t);
            sms(t.getTontineOwner(), "Le vendeur a refuse l'Adashe \"" + t.getLibelle() + "\""
                    + (motif != null && !motif.isBlank() ? " : " + motif : "") + ".");
            return t;
        }

        // Génération des périodes à partir de la date de début (au plus tôt aujourd'hui)
        LocalDate debut = LocalDate.now();
        if (t.getDateDebut() != null) {
            LocalDate prevu = t.getDateDebut().toInstant().atZone(ZoneId.systemDefault()).toLocalDate();
            if (prevu.isAfter(debut)) debut = prevu;
        }
        LocalDate courant = debut;
        LocalDate fin = debut;
        for (int i = 1; i <= t.getNombrePeriodes(); i++) {
            LocalDate suivant = suivante(courant, t.getPeriodicite());
            TontinePeriodeVersement p = new TontinePeriodeVersement();
            p.setLibelle("Période " + i);
            p.setDateDebut(date(courant));
            fin = suivant.minusDays(1);
            p.setDateFin(date(fin));
            p.setTontine(t);
            periodeRepository.save(p);
            courant = suivant;
        }
        t.setDateDebut(date(debut));
        t.setDateFin(date(fin));
        t.setStatutAdashe(StatutAdashe.ACTIF);
        t = tontineRepository.save(t);

        for (User membre : membres(t)) {
            sms(membre, "L'Adashe \"" + t.getLibelle() + "\" est valide par le vendeur. Cotisation : "
                    + Math.round(t.getMontant()) + " FCFA par periode (" + t.getPeriodicite() + ").");
        }
        return t;
    }

    // ── Rejoindre un Adashé ouvert ──────────────────────────────────────────

    @Transactional
    public DemandeAdhesion rejoindre(User user, Long idTontine) {
        Tontine t = adasheProduit(idTontine);
        if (!Boolean.TRUE.equals(t.getOuverte())) {
            throw erreur(HttpStatus.FORBIDDEN, "Cet Adashé est sur invitation uniquement.");
        }
        StatutAdashe statut = t.statutEffectif();
        if (statut == StatutAdashe.REFUSE || statut == StatutAdashe.OBJECTIF_ATTEINT) {
            throw erreur(HttpStatus.CONFLICT, "Cet Adashé n'accepte plus de membres.");
        }
        if (estMembre(t, user)) {
            throw erreur(HttpStatus.CONFLICT, "Vous êtes déjà membre de cet Adashé.");
        }
        if (placesRestantes(t) <= 0) {
            throw erreur(HttpStatus.CONFLICT, "Cet Adashé est complet.");
        }
        return ajouterMembre(t, user);
    }

    /** Places restantes (membres acceptés comparés au nombre prévu). */
    public int placesRestantes(Tontine t) {
        if (t.getNombreMembres() == null) return Integer.MAX_VALUE;
        return Math.max(0, t.getNombreMembres() - nombreMembres(t));
    }

    public int nombreMembres(Tontine t) {
        return (int) demandeRepository.findByTontineId(t.getIdTontine()).stream()
                .filter(d -> d.getStatut() == DemandeAdhesionStatus.ACCEPTEE)
                .count();
    }

    // ── Consultation ────────────────────────────────────────────────────────

    /** Fiche d'un Adashé Produit avec sa progression. */
    public Map<String, Object> resume(Tontine t) {
        Map<String, Object> m = new LinkedHashMap<>();
        double collecte = versementRepository.totalCotise(t.getIdTontine());
        m.put("tontine", t);
        m.put("statut", t.statutEffectif().name());
        m.put("montantCible", t.getMontantCible());
        m.put("collecte", collecte);
        m.put("membres", nombreMembres(t));
        m.put("nombreMembres", t.getNombreMembres());
        m.put("placesRestantes", t.getNombreMembres() == null ? null : placesRestantes(t));
        return m;
    }

    /** Adashé ouverts d'un produit, qu'un acheteur peut rejoindre. */
    public List<Map<String, Object>> ouverts(Long idProduit) {
        List<Map<String, Object>> res = new ArrayList<>();
        for (Tontine t : tontineRepository.findByProduitId(idProduit)) {
            StatutAdashe s = t.statutEffectif();
            if (Boolean.TRUE.equals(t.getOuverte())
                    && (s == StatutAdashe.EN_ATTENTE_VENDEUR || s == StatutAdashe.ACTIF)
                    && placesRestantes(t) > 0) {
                res.add(resume(t));
            }
        }
        return res;
    }

    /** Adashé Produit des produits d'une boutique (vue vendeur). */
    public List<Map<String, Object>> pourBoutique(User vendeur, Long idBoutique, boolean admin) {
        List<Tontine> liste = tontineRepository.findByBoutiqueId(idBoutique);
        List<Map<String, Object>> res = new ArrayList<>();
        for (Tontine t : liste) {
            Boutique b = t.getProduit().getBoutique();
            if (!admin && (b.getVendeur() == null
                    || !Objects.equals(b.getVendeur().getIdUser(), vendeur.getIdUser()))) {
                throw erreur(HttpStatus.FORBIDDEN, "Cette boutique n'est pas la vôtre.");
            }
            res.add(resume(t));
        }
        return res;
    }

    /** Après une cotisation : objectif atteint ? (appelé à chaque cotisation réussie) */
    @Transactional
    public void verifierObjectif(Tontine t) {
        if (t == null || !t.estProduit() || t.statutEffectif() != StatutAdashe.ACTIF
                || t.getMontantCible() == null) {
            return;
        }
        double collecte = versementRepository.totalCotise(t.getIdTontine());
        if (collecte + 0.5 < t.getMontantCible()) return;

        t.setStatutAdashe(StatutAdashe.OBJECTIF_ATTEINT);
        tontineRepository.save(t);
        String produit = t.getProduit().getLibelle();
        sms(t.getProduit().getBoutique().getVendeur(), "Objectif atteint pour l'Adashe \"" + t.getLibelle()
                + "\" : " + Math.round(collecte) + " FCFA reunis. Preparez la livraison de \"" + produit + "\".");
        sms(t.getTontineOwner(), "Felicitations : votre Adashe \"" + t.getLibelle()
                + "\" a atteint son objectif. Le vendeur va organiser la livraison.");
    }

    // ── Outils ──────────────────────────────────────────────────────────────

    private Tontine adasheProduit(Long idTontine) {
        Tontine t = tontineRepository.findById(idTontine)
                .orElseThrow(() -> erreur(HttpStatus.NOT_FOUND, "Adashé introuvable."));
        if (!t.estProduit() || t.getProduit() == null) {
            throw erreur(HttpStatus.BAD_REQUEST, "Cet Adashé n'est pas un Adashé Produit.");
        }
        return t;
    }

    private DemandeAdhesion ajouterMembre(Tontine t, User user) {
        DemandeAdhesion d = new DemandeAdhesion();
        d.setTontine(t);
        d.setTelephone(user.getTelephone());
        d.setMembre(user);
        d.setDateEnvoi(new Date());
        d.setStatut(DemandeAdhesionStatus.ACCEPTEE);
        return demandeRepository.save(d);
    }

    private boolean estMembre(Tontine t, User user) {
        return demandeRepository.findByTontineId(t.getIdTontine()).stream()
                .anyMatch(d -> d.getStatut() == DemandeAdhesionStatus.ACCEPTEE
                        && ((d.getMembre() != null && Objects.equals(d.getMembre().getIdUser(), user.getIdUser()))
                            || Objects.equals(d.getTelephone(), user.getTelephone())));
    }

    private List<User> membres(Tontine t) {
        List<User> res = new ArrayList<>();
        for (DemandeAdhesion d : demandeRepository.findByTontineId(t.getIdTontine())) {
            if (d.getStatut() == DemandeAdhesionStatus.ACCEPTEE && d.getMembre() != null) {
                res.add(d.getMembre());
            }
        }
        return res;
    }

    private static LocalDate suivante(LocalDate d, String periodicite) {
        switch (periodicite == null ? "" : periodicite.toLowerCase()) {
            case "quotidienne": return d.plusDays(1);
            case "hebdomadaire": return d.plusWeeks(1);
            case "trimestrielle": return d.plusMonths(3);
            case "annuelle": return d.plusYears(1);
            default: return d.plusMonths(1); // mensuelle
        }
    }

    private static Date date(LocalDate d) {
        return Date.from(d.atStartOfDay(ZoneId.systemDefault()).toInstant());
    }

    private void sms(User destinataire, String message) {
        if (destinataire == null || destinataire.getTelephone() == null) return;
        try {
            Sms sms = new Sms();
            sms.setReceiver(destinataire.getTelephone());
            sms.setMessage(message);
            smsService.send(sms);
        } catch (Exception e) {
            System.err.println("[AdasheProduit] SMS non envoyé : " + e.getMessage());
        }
    }

    private static ResponseStatusException erreur(HttpStatus status, String message) {
        return new ResponseStatusException(status, message);
    }
}
