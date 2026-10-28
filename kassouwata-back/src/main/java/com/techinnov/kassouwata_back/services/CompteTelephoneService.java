package com.techinnov.kassouwata_back.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.techinnov.kassouwata_back.entitites.User;
import com.techinnov.kassouwata_back.repositories.DemandeAdhesionRepository;
import com.techinnov.kassouwata_back.repositories.TontineVersementRepository;
import com.techinnov.kassouwata_back.repositories.UserRepository;

/**
 * Cohérence entre le compte et son numéro de téléphone.
 *
 * Les adhésions aux tontines et les cotisations sont rattachées au compte
 * (user_id). Le numéro y est seulement recopié pour l'affichage : il est mis à
 * jour ici lors d'un changement de numéro, en une seule transaction.
 */
@Service
public class CompteTelephoneService implements ApplicationRunner {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DemandeAdhesionRepository demandeRepository;

    @Autowired
    private TontineVersementRepository versementRepository;

    /** Au démarrage : rattache aux comptes les données qui ne sont liées qu'à un numéro. */
    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        try {
            int d = demandeRepository.lierAuxComptes();
            int v = versementRepository.lierAuxComptes();
            if (d + v > 0) {
                System.out.println("[CompteTelephone] Rattachés aux comptes : "
                        + d + " demande(s) d'adhésion, " + v + " cotisation(s).");
            }
        } catch (Exception e) {
            System.err.println("[CompteTelephone] Rattachement impossible : " + e.getMessage());
        }
    }

    /** Après une inscription : relie au nouveau compte les invitations reçues sur ce numéro. */
    @Transactional
    public void lierInvitations() {
        demandeRepository.lierAuxComptes();
        versementRepository.lierAuxComptes();
    }

    /** Change le numéro du compte et le reporte partout où il est recopié. */
    @Transactional
    public User changerTelephone(User user, String nouveau) {
        String ancien = user.getTelephone();
        // Rattacher d'abord ce qui n'était lié qu'à l'ancien numéro
        demandeRepository.lierAuxComptes();
        versementRepository.lierAuxComptes();

        user.setTelephone(nouveau);
        User saved = userRepository.save(user);

        demandeRepository.changerTelephone(saved.getIdUser(), ancien, nouveau);
        versementRepository.changerTelephone(saved.getIdUser(), ancien, nouveau);
        return saved;
    }
}
