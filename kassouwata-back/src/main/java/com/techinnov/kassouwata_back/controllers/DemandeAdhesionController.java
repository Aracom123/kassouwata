package com.techinnov.kassouwata_back.controllers;

import java.text.Normalizer;
import java.util.Date;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.rest.webmvc.ResourceNotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.techinnov.kassouwata_back.entitites.DemandeAdhesion;
import com.techinnov.kassouwata_back.entitites.Sms;
import com.techinnov.kassouwata_back.entitites.User;
import com.techinnov.kassouwata_back.repositories.DemandeAdhesionRepository;
import com.techinnov.kassouwata_back.repositories.TontineRepository;
import com.techinnov.kassouwata_back.repositories.UserRepository;
import com.techinnov.kassouwata_back.services.SmsService;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosDemandesAdhesion")
public class DemandeAdhesionController {

    @Autowired
    private DemandeAdhesionRepository demandeAdhesionRepository;

    @Autowired
    private SmsService smsService;

    @Autowired
    private TontineRepository tontineRepository;

    @Autowired
    private UserRepository userRepository;

    /** Utilisateur connecté (le jeton contient son numéro de téléphone). */
    private User utilisateurConnecte() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getName() == null) return null;
        return userRepository.findByTelephone(auth.getName()).orElse(null);
    }

    /** Rattache la demande au compte qui porte le numéro invité (s'il existe). */
    private void rattacherMembre(DemandeAdhesion demande) {
        if (demande.getTelephone() == null) {
            demande.setMembre(null);
            return;
        }
        demande.setTelephone(demande.getTelephone().trim());
        demande.setMembre(userRepository.findByTelephone(demande.getTelephone()).orElse(null));
    }

    /**
     * Demandes reçues par l'utilisateur connecté (invitations et tontines rejointes).
     * Basé sur le compte : un changement de numéro ne fait rien perdre.
     */
    @GetMapping("/mes-demandes")
    public List<DemandeAdhesion> getMesDemandes() {
        User user = utilisateurConnecte();
        if (user == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Utilisateur non connecté.");
        }
        return demandeAdhesionRepository.findPourUtilisateur(user.getIdUser(), user.getTelephone());
    }

    // Get All (paginé)
    @GetMapping("/list")
    public Page<DemandeAdhesion> getAllDemandes(Pageable page) {
        return demandeAdhesionRepository.findAll(page);
    }

    // Get by ID
    @GetMapping("/{id}")
    public ResponseEntity<DemandeAdhesion> getDemandeById(@PathVariable Long id) {
        DemandeAdhesion demande = demandeAdhesionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "DemandeAdhesion not found with id: " + id));
        return ResponseEntity.ok(demande);
    }

    // Créer une demande — dateEnvoi initialisée automatiquement + envoi SMS
    @PostMapping("/save")
    public DemandeAdhesion addDemande(@RequestBody DemandeAdhesion demande) {
        if (demande.getDateEnvoi() == null) {
            demande.setDateEnvoi(new Date());
        }
        rattacherMembre(demande);
        DemandeAdhesion saved = demandeAdhesionRepository.save(demande);

        // Envoi SMS au destinataire de l'invitation
        try {
            // Charger le libellé depuis la BDD (relation LAZY non chargée depuis le JSON)
            String tontineLibelle = "une tontine";
            if (saved.getTontine() != null && saved.getTontine().getIdTontine() != null) {
                tontineRepository.findById(saved.getTontine().getIdTontine())
                        .ifPresent(t -> saved.getTontine().setLibelle(t.getLibelle()));
                tontineLibelle = saved.getTontine().getLibelle() != null
                        ? saved.getTontine().getLibelle()
                        : "une tontine";
            }
            // Message sans accents, max 160 caracteres (contrainte GSM 7-bit)
            String message = supprimerAccents(
                "Vous etes invite(e) a rejoindre la tontine \""
                + tontineLibelle
                + "\". Connectez-vous a Kassouwata pour accepter ou refuser.");
            if (message.length() > 160) {
                message = message.substring(0, 160);
            }
            Sms sms = new Sms();
            sms.setReceiver(saved.getTelephone());
            sms.setMessage(message);
            smsService.send(sms);
        } catch (Exception e) {
            // L'échec SMS ne bloque pas la réponse HTTP
            System.err.println("[DemandeAdhesion] Echec envoi SMS : " + e.getMessage());
        }

        return saved;
    }

    // Mettre à jour (statut principalement)
    // Règle métier : seul l'utilisateur destinataire de la demande peut
    // changer le statut en ACCEPTEE ou REFUSEE.
    @PutMapping("/update/{id}")
    public DemandeAdhesion updateDemande(
            @RequestBody DemandeAdhesion newDemande,
            @PathVariable Long id) {

        DemandeAdhesion demande = demandeAdhesionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "DemandeAdhesion not found with id: " + id));

        // Vérification : si on tente de changer le statut (accepter/refuser),
        // l'utilisateur authentifié doit être le destinataire de la demande.
        if (newDemande.getStatut() != null) {
            User connecte = utilisateurConnecte();
            boolean destinataire = connecte != null && (demande.getMembre() != null
                    ? demande.getMembre().getIdUser().equals(connecte.getIdUser())
                    : connecte.getTelephone().equals(demande.getTelephone()));

            if (!destinataire) {
                throw new ResponseStatusException(
                        HttpStatus.FORBIDDEN,
                        "Seul l'utilisateur invite peut accepter ou refuser cette demande.");
            }

            if (demande.getMembre() == null) {
                demande.setMembre(connecte);
            }
            demande.setStatut(newDemande.getStatut());
        }

        if (newDemande.getTelephone() != null
                && !newDemande.getTelephone().trim().equals(demande.getTelephone())) {
            demande.setTelephone(newDemande.getTelephone());
            rattacherMembre(demande);
        }

        return demandeAdhesionRepository.save(demande);
    }

    // Supprimer
    @DeleteMapping("/delete/{id}")
    public void deleteDemande(@PathVariable Long id) {
        demandeAdhesionRepository.deleteById(id);
    }

    /**
     * Supprime les accents et caracteres speciaux non GSM 7-bit d'une chaine.
     * Utilise la normalisation Unicode NFD pour decomposer les caracteres accentues,
     * puis retire les diacritiques (classe Unicode Mn).
     */
    private String supprimerAccents(String texte) {
        if (texte == null) return "";
        String normalise = Normalizer.normalize(texte, Normalizer.Form.NFD);
        return normalise.replaceAll("\\p{Mn}", "");
    }


}