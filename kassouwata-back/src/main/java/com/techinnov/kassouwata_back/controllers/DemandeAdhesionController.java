package com.techinnov.kassouwata_back.controllers;

import java.text.Normalizer;
import java.util.Date;

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
import com.techinnov.kassouwata_back.repositories.DemandeAdhesionRepository;
import com.techinnov.kassouwata_back.repositories.TontineRepository;
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
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            String telephoneConnecte = (auth != null) ? auth.getName() : null;

            if (telephoneConnecte == null || !telephoneConnecte.equals(demande.getTelephone())) {
                throw new ResponseStatusException(
                        HttpStatus.FORBIDDEN,
                        "Seul l'utilisateur invite peut accepter ou refuser cette demande.");
            }

            demande.setStatut(newDemande.getStatut());
        }

        if (newDemande.getTelephone() != null) {
            demande.setTelephone(newDemande.getTelephone());
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