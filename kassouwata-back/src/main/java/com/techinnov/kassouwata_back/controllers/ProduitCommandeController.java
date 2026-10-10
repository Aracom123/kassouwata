package com.techinnov.kassouwata_back.controllers;

import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.techinnov.kassouwata_back.entitites.ProduitCommande;
import com.techinnov.kassouwata_back.repositories.ProduitCommandeRepository;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosProduitsCommandes")
public class ProduitCommandeController {
	@Autowired
	private ProduitCommandeRepository produitCommandeRepository;

	
	//Get All ProduitCommandes
	@GetMapping("/list")
	public Page<ProduitCommande> getAllProduitCommandes(Pageable page){
		return produitCommandeRepository.findAll(page);
	}

	//Get ProduitCommande By Id
	@GetMapping("/{id}")
	public ResponseEntity<ProduitCommande> getProduitCommandeById(@PathVariable Long id){
		ProduitCommande produitCommande = produitCommandeRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("ProduitCommande not exit with id:" +id));
		 return ResponseEntity.ok(produitCommande);
	
	}
		
	//Add ProduitCommande
	@PostMapping("/save")
	public ProduitCommande addProduitCommande(@RequestBody ProduitCommande produitCommande) {
		return produitCommandeRepository.save(produitCommande);
	}
	
	//Update ProduitCommande
	@PutMapping("/update/{id}")
	ProduitCommande replaceProduitCommande(@RequestBody ProduitCommande newProduitCommande, @PathVariable Long id) {
		return produitCommandeRepository.findById(id)
        .map(produitCommande -> {
        	produitCommande.setCommande(newProduitCommande.getCommande());
        	produitCommande.setProduit(newProduitCommande.getProduit());
        	produitCommande.setQuantite(newProduitCommande.getQuantite());
        	produitCommande.setPrixUnitaire(newProduitCommande.getPrixUnitaire());
          return produitCommandeRepository.save(produitCommande);
        })
        .orElseGet(() -> {
          newProduitCommande.setIdProduitCommande(id);
          return produitCommandeRepository.save(newProduitCommande);
        });
    }	
	
	//Delete ProduitCommande
	@DeleteMapping("/delete/{id}")
	public void deleteProduitCommandeById(@PathVariable Long id) {
		produitCommandeRepository.deleteById(id);
	}
		
}