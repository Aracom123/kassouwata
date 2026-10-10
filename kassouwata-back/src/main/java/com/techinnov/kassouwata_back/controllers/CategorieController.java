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

import com.techinnov.kassouwata_back.entitites.Categorie;
import com.techinnov.kassouwata_back.repositories.CategorieRepository;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosCategories")
public class CategorieController {
	@Autowired
	private CategorieRepository categorieRepository;

	
	//Get All Categories
	@GetMapping("/list")
	public Page<Categorie> getAllCategories(Pageable page){
		return categorieRepository.findAll(page);
	}

	//Get Categorie By Id
	@GetMapping("/{id}")
	public ResponseEntity<Categorie> getCategorieById(@PathVariable Long id){
		Categorie categorie = categorieRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Categorie not exit with id:" +id));
		 return ResponseEntity.ok(categorie);
	
	}
		
	//Add Categorie
	@PostMapping("/save")
	public Categorie addCategorie(@RequestBody Categorie categorie) {
		return categorieRepository.save(categorie);
	}
	
	//Add Categorie
	// @GetMapping("/getCandidatCategorie")
	// public Categorie getCategorieByLibelle(@RequestParam("libelle") String libelle) {
	// 	return categorieRepository.findCategorieByLibelle(libelle);
	// }
	
	//Update Categorie
	@PutMapping("/update/{id}")
	Categorie replaceCategorie(@RequestBody Categorie newCategorie, @PathVariable Long id) {
		return categorieRepository.findById(id)
        .map(categorie -> {
        	categorie.setLibelle(newCategorie.getLibelle());
        	categorie.setDescription(newCategorie.getDescription());
          return categorieRepository.save(categorie);
        })
        .orElseGet(() -> {
          newCategorie.setIdCategorie(id);
          return categorieRepository.save(newCategorie);
        });
    }	
	
	//Delete Categorie
	@DeleteMapping("/delete/{id}")
	public void deleteCategorieById(@PathVariable Long id) {
		categorieRepository.deleteById(id);
	}
		
}