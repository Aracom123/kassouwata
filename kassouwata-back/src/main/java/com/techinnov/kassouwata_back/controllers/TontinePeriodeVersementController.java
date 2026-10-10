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

import com.techinnov.kassouwata_back.entitites.TontinePeriodeVersement;
import com.techinnov.kassouwata_back.entitites.TontineVersement;
import com.techinnov.kassouwata_back.repositories.TontinePeriodeVersementRepository;
import com.techinnov.kassouwata_back.repositories.TontineVersementRepository;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosTontinePeriodeVersements")
public class TontinePeriodeVersementController {
	@Autowired
	private TontinePeriodeVersementRepository tontineRepository;

	@Autowired
	private TontineVersementRepository versementRepository;

	
	//Get All TontinePeriodeVersements
	@GetMapping("/list")
	public Page<TontinePeriodeVersement> getAllTontinePeriodeVersements(Pageable page){
		return tontineRepository.findAll(page);
	}

	//Get TontinePeriodeVersement By Id
	@GetMapping("/{id}")
	public ResponseEntity<TontinePeriodeVersement> getTontinePeriodeVersementById(@PathVariable Long id){
		TontinePeriodeVersement tontine = tontineRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("TontinePeriodeVersement not exit with id:" +id));
		 return ResponseEntity.ok(tontine);
	
	}
		
	//Add TontinePeriodeVersement
	@PostMapping("/save")
	public TontinePeriodeVersement addTontinePeriodeVersement(@RequestBody TontinePeriodeVersement tontine) {
		return tontineRepository.save(tontine);
	}
	
	//Update TontinePeriodeVersement
	@PutMapping("/update/{id}")
	TontinePeriodeVersement replaceTontinePeriodeVersement(@RequestBody TontinePeriodeVersement newTontinePeriodeVersement, @PathVariable Long id) {
		return tontineRepository.findById(id)
        .map(tontine -> {
        	tontine.setLibelle(newTontinePeriodeVersement.getLibelle());
        	tontine.setDateDebut(newTontinePeriodeVersement.getDateDebut());
        	tontine.setDateFin(newTontinePeriodeVersement.getDateFin());
        	tontine.setBeneficiaire(newTontinePeriodeVersement.getBeneficiaire());
        	tontine.setTontine(newTontinePeriodeVersement.getTontine());
          return tontineRepository.save(tontine);
        })
        .orElseGet(() -> {
          newTontinePeriodeVersement.setIdTontinePeriodeVersement(id);
          return tontineRepository.save(newTontinePeriodeVersement);
        });
    }	
	
	//Delete TontinePeriodeVersement
	@DeleteMapping("/delete/{id}")
	public void deleteTontinePeriodeVersementById(@PathVariable Long id) {
		tontineRepository.deleteById(id);
	}

	/** Liste des versements d'une période */
	@GetMapping("/{id}/versements")
	public List<TontineVersement> getVersementsByPeriode(@PathVariable Long id) {
		return versementRepository.findByPeriodeId(id);
	}

}