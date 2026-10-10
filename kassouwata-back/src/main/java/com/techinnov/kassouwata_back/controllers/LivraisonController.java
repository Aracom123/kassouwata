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

import com.techinnov.kassouwata_back.entitites.Livraison;
import com.techinnov.kassouwata_back.repositories.LivraisonRepository;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosLivraisons")
public class LivraisonController {
	@Autowired
	private LivraisonRepository commandeRepository;

	
	//Get All Livraisons
	@GetMapping("/list")
	public Page<Livraison> getAllLivraisons(Pageable page){
		return commandeRepository.findAll(page);
	}

	//Get Livraison By Id
	@GetMapping("/{id}")
	public ResponseEntity<Livraison> getLivraisonById(@PathVariable Long id){
		Livraison commande = commandeRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Livraison not exit with id:" +id));
		 return ResponseEntity.ok(commande);
	
	}
		
	//Add Livraison
	@PostMapping("/save")
	public Livraison addLivraison(@RequestBody Livraison commande) {
		return commandeRepository.save(commande);
	}
	
	//Update Livraison
	@PutMapping("/update/{id}")
	Livraison replaceLivraison(@RequestBody Livraison newLivraison, @PathVariable Long id) {
		return commandeRepository.findById(id)
        .map(commande -> {
        	commande.setDateLivraison(newLivraison.getDateLivraison());
        	commande.setCommande(newLivraison.getCommande());
        	commande.setAdresseLivraison(newLivraison.getAdresseLivraison());
          return commandeRepository.save(commande);
        })
        .orElseGet(() -> {
          newLivraison.setIdLivraison(id);
          return commandeRepository.save(newLivraison);
        });
    }	
	
	//Delete Livraison
	@DeleteMapping("/delete/{id}")
	public void deleteLivraisonById(@PathVariable Long id) {
		commandeRepository.deleteById(id);
	}
		
}