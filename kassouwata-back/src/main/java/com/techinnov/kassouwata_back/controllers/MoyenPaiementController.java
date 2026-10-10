package com.techinnov.kassouwata_back.controllers;

import com.techinnov.kassouwata_back.entitites.CategoriePaiement;
import com.techinnov.kassouwata_back.entitites.MoyenPaiement;
import com.techinnov.kassouwata_back.services.MoyenPaiementService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.PathResource;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.MediaTypeFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.List;
import java.util.Map;

/**
 * Catégories et moyens de paiement.
 *  - GET  /api/payment/moyens                     : catalogue pour les applications (utilisateur connecté)
 *  - GET  /api/payment/logos/{fichier}            : logos (public, utilisable dans une balise image)
 *  - /api/payment/admin/...                       : administration (profil ADMIN, cf. SecurityConfig)
 */
@RestController
@RequestMapping("/api/payment")
public class MoyenPaiementController {

    private final MoyenPaiementService service;
    private final Path dossierImages;

    public MoyenPaiementController(MoyenPaiementService service, @Value("${upload.path}") String uploadPath) {
        this.service = service;
        this.dossierImages = Paths.get(uploadPath).toAbsolutePath().normalize();
    }

    /**
     * Catalogue affiché sur le téléphone : catégories (Mobile Money, STA, Carte),
     * chacune avec ses moyens actifs (libellé, logoPath, code à renvoyer dans moyenPaiement).
     */
    @GetMapping("/moyens")
    public List<Map<String, Object>> catalogue() {
        return service.catalogue();
    }

    /** Sert un logo. URL complète = URL de l'API + logoPath (ex. http://serveur:8082/api/payment/logos/x.png). */
    @GetMapping("/logos/{fichier:.+}")
    public ResponseEntity<Resource> logo(@PathVariable String fichier) {
        Path chemin = dossierImages.resolve(fichier).normalize();
        if (!chemin.startsWith(dossierImages) || !Files.isRegularFile(chemin)) {
            return ResponseEntity.notFound().build();
        }
        MediaType type = MediaTypeFactory.getMediaType(chemin.getFileName().toString())
                .orElse(MediaType.APPLICATION_OCTET_STREAM);
        return ResponseEntity.ok()
                .contentType(type)
                .cacheControl(CacheControl.maxAge(Duration.ofDays(1)).cachePublic())
                .body(new PathResource(chemin));
    }

    // ------------------------------------------------------------------
    // Administration (back-office)
    // ------------------------------------------------------------------

    @GetMapping("/admin/moyens")
    public List<Map<String, Object>> referentiel() {
        return service.toutLeReferentiel();
    }

    @PostMapping("/admin/moyens")
    public MoyenPaiement creerMoyen(@RequestBody Map<String, Object> champs) {
        return service.creerMoyen(champs);
    }

    @PutMapping("/admin/moyens/{id}")
    public MoyenPaiement modifierMoyen(@PathVariable Long id, @RequestBody Map<String, Object> champs) {
        return service.modifierMoyen(id, champs);
    }

    @PostMapping("/admin/moyens/{id}/logo")
    public MoyenPaiement changerLogo(@PathVariable Long id, @RequestParam("file") MultipartFile fichier) {
        return service.changerLogo(id, fichier);
    }

    @PutMapping("/admin/categories/{id}")
    public CategoriePaiement modifierCategorie(@PathVariable Long id, @RequestBody Map<String, Object> champs) {
        return service.modifierCategorie(id, champs);
    }

    /** Données incorrectes -> 400 au format {"error": "..."}. */
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleBadArgument(IllegalArgumentException e) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("error", e.getMessage(), "status", 400));
    }
}
