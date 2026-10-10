package com.techinnov.kassouwata_back.services;

import com.techinnov.kassouwata_back.entitites.CategoriePaiement;
import com.techinnov.kassouwata_back.entitites.MoyenPaiement;
import com.techinnov.kassouwata_back.repositories.CategoriePaiementRepository;
import com.techinnov.kassouwata_back.repositories.MoyenPaiementRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Référentiel des catégories et moyens de paiement (affichage mobile + administration).
 */
@Service
public class MoyenPaiementService {

    private final CategoriePaiementRepository categorieRepository;
    private final MoyenPaiementRepository moyenRepository;
    private final FileService fileService;

    public MoyenPaiementService(CategoriePaiementRepository categorieRepository,
                                MoyenPaiementRepository moyenRepository,
                                FileService fileService) {
        this.categorieRepository = categorieRepository;
        this.moyenRepository = moyenRepository;
        this.fileService = fileService;
    }

    /**
     * Catalogue pour les applications mobiles : catégories actives, chacune avec ses
     * moyens utilisables (actifs et dont le code KomiPay est renseigné), triés par ordre.
     * Une catégorie sans moyen utilisable n'est pas renvoyée.
     */
    public List<Map<String, Object>> catalogue() {
        return construire(true);
    }

    /** Vue complète pour le back-office (y compris éléments inactifs). */
    public List<Map<String, Object>> toutLeReferentiel() {
        return construire(false);
    }

    private List<Map<String, Object>> construire(boolean seulementUtilisables) {
        List<MoyenPaiement> moyens = moyenRepository.findAllByOrderByOrdreAsc();
        List<Map<String, Object>> resultat = new ArrayList<>();
        for (CategoriePaiement c : categorieRepository.findAllByOrderByOrdreAsc()) {
            if (seulementUtilisables && !Boolean.TRUE.equals(c.getActif())) continue;
            List<MoyenPaiement> deLaCategorie = moyens.stream()
                    .filter(m -> m.getCategorie() != null
                            && m.getCategorie().getIdCategoriePaiement().equals(c.getIdCategoriePaiement()))
                    .filter(m -> !seulementUtilisables || m.isUtilisable())
                    .toList();
            if (seulementUtilisables && deLaCategorie.isEmpty()) continue;

            Map<String, Object> cat = new LinkedHashMap<>();
            cat.put("idCategoriePaiement", c.getIdCategoriePaiement());
            cat.put("code", c.getCode());
            cat.put("libelle", c.getLibelle());
            cat.put("description", c.getDescription());
            cat.put("ordre", c.getOrdre());
            cat.put("actif", c.getActif());
            cat.put("moyens", deLaCategorie);
            resultat.add(cat);
        }
        return resultat;
    }

    // ------------------------------------------------------------------
    // Administration
    // ------------------------------------------------------------------

    public CategoriePaiement modifierCategorie(Long id, Map<String, Object> champs) {
        CategoriePaiement c = categorieRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Catégorie introuvable : " + id));
        if (champs.containsKey("libelle")) c.setLibelle(texte(champs.get("libelle")));
        if (champs.containsKey("description")) c.setDescription(texte(champs.get("description")));
        if (champs.containsKey("ordre")) c.setOrdre(entier(champs.get("ordre")));
        if (champs.containsKey("actif")) c.setActif(Boolean.TRUE.equals(champs.get("actif")));
        return categorieRepository.save(c);
    }

    /** Crée un moyen de paiement. Champs : code, libelle, categorieCode, codeAgregateur, ordre, actif. */
    public MoyenPaiement creerMoyen(Map<String, Object> champs) {
        String code = texte(champs.get("code"));
        if (code == null) throw new IllegalArgumentException("code est obligatoire");
        code = code.toUpperCase().replaceAll("[^A-Z0-9_]", "_");
        if (moyenRepository.findByCode(code).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Le code " + code + " existe déjà");
        }
        MoyenPaiement m = new MoyenPaiement();
        m.setCode(code);
        m.setActif(false);
        appliquer(m, champs);
        if (m.getCategorie() == null) throw new IllegalArgumentException("categorieCode est obligatoire");
        return moyenRepository.save(m);
    }

    /** Modifie un moyen de paiement (le code interne n'est pas modifiable : il est stocké dans l'historique). */
    public MoyenPaiement modifierMoyen(Long id, Map<String, Object> champs) {
        MoyenPaiement m = moyenRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Moyen de paiement introuvable : " + id));
        appliquer(m, champs);
        return moyenRepository.save(m);
    }

    public MoyenPaiement changerLogo(Long id, MultipartFile fichier) {
        MoyenPaiement m = moyenRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Moyen de paiement introuvable : " + id));
        if (fichier == null || fichier.isEmpty()) throw new IllegalArgumentException("Fichier vide");
        String type = fichier.getContentType();
        if (type == null || !type.startsWith("image/")) throw new IllegalArgumentException("Le logo doit être une image");
        try {
            String ancien = m.getLogo();
            m.setLogo(fileService.save(fichier));
            m = moyenRepository.save(m);
            if (ancien != null && !ancien.isBlank()) fileService.delete(ancien);
            return m;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR,
                    "Enregistrement du logo impossible : " + e.getMessage());
        }
    }

    private void appliquer(MoyenPaiement m, Map<String, Object> champs) {
        if (champs.containsKey("libelle")) m.setLibelle(texte(champs.get("libelle")));
        if (champs.containsKey("codeAgregateur")) m.setCodeAgregateur(texte(champs.get("codeAgregateur")));
        if (champs.containsKey("ordre")) m.setOrdre(entier(champs.get("ordre")));
        if (champs.containsKey("actif")) m.setActif(Boolean.TRUE.equals(champs.get("actif")));
        if (champs.containsKey("categorieCode")) {
            String code = texte(champs.get("categorieCode"));
            m.setCategorie(categorieRepository.findByCode(code == null ? "" : code.toUpperCase())
                    .orElseThrow(() -> new IllegalArgumentException("Catégorie inconnue : " + code)));
        }
        if (Boolean.TRUE.equals(m.getActif()) && (m.getCodeAgregateur() == null || m.getCodeAgregateur().isBlank())) {
            throw new IllegalArgumentException("Renseignez le code KomiPay (mobile_money) avant d'activer ce moyen de paiement");
        }
    }

    private static String texte(Object o) {
        if (o == null) return null;
        String s = o.toString().trim();
        return s.isEmpty() ? null : s;
    }

    private static Integer entier(Object o) {
        if (o == null || o.toString().isBlank()) return 0;
        return o instanceof Number n ? n.intValue() : Integer.parseInt(o.toString().trim());
    }
}
