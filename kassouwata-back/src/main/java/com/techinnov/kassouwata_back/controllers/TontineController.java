package com.techinnov.kassouwata_back.controllers;

import java.util.Date;
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

import com.techinnov.kassouwata_back.entitites.DemandeAdhesion;
import com.techinnov.kassouwata_back.entitites.Tontine;
import com.techinnov.kassouwata_back.entitites.TontinePeriodeVersement;
import com.techinnov.kassouwata_back.enums.DemandeAdhesionStatus;
import com.techinnov.kassouwata_back.repositories.DemandeAdhesionRepository;
import com.techinnov.kassouwata_back.repositories.TontinePeriodeVersementRepository;
import com.techinnov.kassouwata_back.repositories.TontineRepository;
import com.techinnov.kassouwata_back.repositories.UserRepository;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosTontines")
public class TontineController {
	@Autowired
	private TontineRepository tontineRepository;

	@Autowired
	private UserRepository userRepository;

	@Autowired
	private DemandeAdhesionRepository demandeAdhesionRepository;

	@Autowired
	private TontinePeriodeVersementRepository periodeVersementRepository;

	
	//Get All Tontines
	@GetMapping("/list")
	public Page<Tontine> getAllTontines(Pageable page){
		return tontineRepository.findAll(page);
	}

	//Get Tontine By Id
	@GetMapping("/{id}")
	public ResponseEntity<Tontine> getTontineById(@PathVariable Long id){
		Tontine tontine = tontineRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Tontine not exit with id:" +id));
		 return ResponseEntity.ok(tontine);
	
	}
		
	//Add Tontine
	@PostMapping("/save")
	public Tontine addTontine(@RequestBody Tontine tontine) {
		if (tontine.getTontineOwner() != null && tontine.getTontineOwner().getIdUser() != null) {
			userRepository.findById(tontine.getTontineOwner().getIdUser())
				.ifPresent(tontine::setTontineOwner);
		}
		Tontine saved = tontineRepository.save(tontine);
		if (saved.getTontineOwner() != null && saved.getTontineOwner().getTelephone() != null) {
			DemandeAdhesion adhesion = new DemandeAdhesion();
			adhesion.setTelephone(saved.getTontineOwner().getTelephone());
			adhesion.setDateEnvoi(new Date());
			adhesion.setStatut(DemandeAdhesionStatus.ACCEPTEE);
			adhesion.setTontine(saved);
			demandeAdhesionRepository.save(adhesion);
		}
		return saved;
	}
	
	//Update Tontine
	@PutMapping("/update/{id}")
	Tontine replaceTontine(@RequestBody Tontine newTontine, @PathVariable Long id) {
		return tontineRepository.findById(id)
        .map(tontine -> {
        	tontine.setLibelle(newTontine.getLibelle());
        	tontine.setDateDebut(newTontine.getDateDebut());
        	tontine.setDateFin(newTontine.getDateFin());
        	tontine.setMontant(newTontine.getMontant());
        	tontine.setDescription(newTontine.getDescription());
          return tontineRepository.save(tontine);
        })
        .orElseGet(() -> {
          newTontine.setIdTontine(id);
          return tontineRepository.save(newTontine);
        });
    }	
	
	//Delete Tontine
	@DeleteMapping("/delete/{id}")
	public void deleteTontineById(@PathVariable Long id) {
		tontineRepository.deleteById(id);
	}

	/** Liste des membres (DemandeAdhesion) d'une tontine */
	@GetMapping("/{id}/membres")
	public List<DemandeAdhesion> getMembresByTontine(@PathVariable Long id) {
		return demandeAdhesionRepository.findByTontineId(id);
	}

	/** Liste des périodes de versement d'une tontine */
	@GetMapping("/{id}/periodes")
	public List<TontinePeriodeVersement> getPeriodesByTontine(@PathVariable Long id) {
		return periodeVersementRepository.findByTontineId(id);
	}

}