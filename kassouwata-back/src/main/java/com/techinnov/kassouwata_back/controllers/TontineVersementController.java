package com.techinnov.kassouwata_back.controllers;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

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
import com.techinnov.kassouwata_back.entitites.User;
import com.techinnov.kassouwata_back.repositories.TontinePeriodeVersementRepository;
import com.techinnov.kassouwata_back.repositories.TontineVersementRepository;
import com.techinnov.kassouwata_back.repositories.UserRepository;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosTontineVersements")
public class TontineVersementController {
	@Autowired
	private TontineVersementRepository tontineRepository;

	@Autowired
	private UserRepository userRepository;

	@Autowired
	private TontinePeriodeVersementRepository periodeRepository;

	
	//Get All TontineVersements
	@GetMapping("/list")
	public Page<TontineVersement> getAllTontineVersements(Pageable page){
		return tontineRepository.findAll(page);
	}

	//Get TontineVersement By Id
	@GetMapping("/{id}")
	public ResponseEntity<TontineVersement> getTontineVersementById(@PathVariable UUID id){
		TontineVersement tontine = tontineRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("TontineVersement not exit with id:" +id));
		 return ResponseEntity.ok(tontine);
	
	}
		
	//Add TontineVersement
	@PostMapping("/save")
	public TontineVersement addTontineVersement(@RequestBody TontineVersement tontine) {
		if (tontine.getMembre() != null && tontine.getMembre().getIdUser() != null) {
			userRepository.findById(tontine.getMembre().getIdUser())
				.ifPresent(tontine::setMembre);
		}
		if (tontine.getTontinePeriodeVersement() != null
				&& tontine.getTontinePeriodeVersement().getIdTontinePeriodeVersement() != null) {
			periodeRepository.findById(tontine.getTontinePeriodeVersement().getIdTontinePeriodeVersement())
				.ifPresent(tontine::setTontinePeriodeVersement);
		}
		return tontineRepository.save(tontine);
	}
	
	//Update TontineVersement
	@PutMapping("/update/{id}")
	TontineVersement replaceTontineVersement(@RequestBody TontineVersement newTontineVersement, @PathVariable UUID id) {
		User resolvedMembre = null;
		if (newTontineVersement.getMembre() != null && newTontineVersement.getMembre().getIdUser() != null) {
			resolvedMembre = userRepository.findById(newTontineVersement.getMembre().getIdUser()).orElse(null);
		}
		TontinePeriodeVersement resolvedPeriode = null;
		if (newTontineVersement.getTontinePeriodeVersement() != null
				&& newTontineVersement.getTontinePeriodeVersement().getIdTontinePeriodeVersement() != null) {
			resolvedPeriode = periodeRepository.findById(
				newTontineVersement.getTontinePeriodeVersement().getIdTontinePeriodeVersement()).orElse(null);
		}
		final User finalMembre = resolvedMembre;
		final TontinePeriodeVersement finalPeriode = resolvedPeriode;
		return tontineRepository.findById(id)
        .map(tontine -> {
        	tontine.setDateVersement(newTontineVersement.getDateVersement());
        	tontine.setMontant(newTontineVersement.getMontant());
        	tontine.setMembre(finalMembre);
        	tontine.setTontinePeriodeVersement(finalPeriode);
        	tontine.setTypeVersement(newTontineVersement.getTypeVersement());
          return tontineRepository.save(tontine);
        })
        .orElseGet(() -> {
          newTontineVersement.setIdTontineVersement(id);
          newTontineVersement.setMembre(finalMembre);
          newTontineVersement.setTontinePeriodeVersement(finalPeriode);
          return tontineRepository.save(newTontineVersement);
        });
    }	
	
	//Delete TontineVersement
	@DeleteMapping("/delete/{id}")
	public void deleteTontineVersementById(@PathVariable UUID id) {
		tontineRepository.deleteById(id);
	}
		
}