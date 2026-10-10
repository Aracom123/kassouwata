package com.techinnov.kassouwata_back.controllers;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.rest.webmvc.ResourceNotFoundException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.techinnov.kassouwata_back.entitites.Produit;
import com.techinnov.kassouwata_back.repositories.BoutiqueRepository;
import com.techinnov.kassouwata_back.repositories.CategorieRepository;
import com.techinnov.kassouwata_back.repositories.ProduitCommandeRepository;
import com.techinnov.kassouwata_back.repositories.ProduitRepository;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosProduits")
public class ProduitController {

    @Autowired
    private ProduitRepository produitRepository;

    @Autowired
    private BoutiqueRepository boutiqueRepository;

    @Autowired
    private CategorieRepository categorieRepository;

    @Autowired
    private ProduitCommandeRepository produitCommandeRepository;

    // Get All Produits — liste complète triée par date de publication décroissante
    @GetMapping("/list")
    public List<Produit> getAllProduits() {
        return produitRepository.findAllOrderByCreatedAtDesc();
    }

    // Get Produit By Id
    @GetMapping("/{id}")
    public ResponseEntity<Produit> getProduitById(@PathVariable Long id) {
        Produit produit = produitRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Produit non trouvé : " + id));
        return ResponseEntity.ok(produit);
    }

    // Add Produit
    @PostMapping("/save")
    public ResponseEntity<?> addProduit(@RequestBody Produit produit) {
        try {
            // Résoudre les associations par ID pour éviter TransientPropertyValueException
            if (produit.getBoutique() != null && produit.getBoutique().getIdBoutique() != null) {
                produit.setBoutique(boutiqueRepository.getReferenceById(produit.getBoutique().getIdBoutique()));
            }
            if (produit.getCategorie() != null && produit.getCategorie().getIdCategorie() != null) {
                produit.setCategorie(categorieRepository.getReferenceById(produit.getCategorie().getIdCategorie()));
            }
            Produit saved = produitRepository.save(produit);
            return ResponseEntity.ok(saved.getIdProduit());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Erreur lors de la création : " + e.getMessage());
        }
    }

    // Update Produit
    @PutMapping("/update/{id}")
    public ResponseEntity<?> replaceProduit(@RequestBody Produit newProduit, @PathVariable Long id) {
        try {
            Produit produit = produitRepository.findById(id)
                    .orElseThrow(() -> new ResourceNotFoundException("Produit non trouvé : " + id));

            produit.setLibelle(newProduit.getLibelle());
            produit.setDescription(newProduit.getDescription());
            produit.setPrixUnitaire(newProduit.getPrixUnitaire());
            produit.setQuantite(newProduit.getQuantite());
            produit.setStatut(newProduit.getStatut());
            produit.setImagePrincipale(newProduit.getImagePrincipale());
            produit.setPhotos(newProduit.getPhotos());
            produit.setNombreTranches(newProduit.getNombreTranches());

            if (newProduit.getBoutique() != null && newProduit.getBoutique().getIdBoutique() != null) {
                produit.setBoutique(boutiqueRepository.getReferenceById(newProduit.getBoutique().getIdBoutique()));
            }
            if (newProduit.getCategorie() != null && newProduit.getCategorie().getIdCategorie() != null) {
                produit.setCategorie(categorieRepository.getReferenceById(newProduit.getCategorie().getIdCategorie()));
            }

            Produit updated = produitRepository.save(produit);
            return ResponseEntity.ok(updated.getIdProduit());
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Erreur lors de la mise à jour : " + e.getMessage());
        }
    }

    // Delete Produit (seulement si pas de commande)
    @DeleteMapping("/delete/{id}")
    public ResponseEntity<String> deleteProduitById(@PathVariable Long id) {
        if (produitCommandeRepository.existsByProduit_IdProduit(id)) {
            return ResponseEntity.badRequest()
                    .body("Ce produit ne peut pas être supprimé car il fait l'objet de commandes.");
        }
        produitRepository.deleteById(id);
        return ResponseEntity.ok("Produit supprimé avec succès.");
    }

    // Get produits by boutique
    @GetMapping("/getByBoutiqueId/{idBoutique}")
    public List<Produit> getByBoutique(@PathVariable(value = "idBoutique") Long idBoutique) {
        return produitRepository.getByBoutiqueId(idBoutique);
    }
}