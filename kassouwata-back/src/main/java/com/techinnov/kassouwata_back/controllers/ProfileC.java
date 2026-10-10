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

import com.techinnov.kassouwata_back.entitites.Profile;
import com.techinnov.kassouwata_back.repositories.ProfileRepository;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosProfiles")
public class ProfileC {
	@Autowired
	private ProfileRepository profileRepository;

	
	//Get All Profiles
	@GetMapping("/list")
	public List<Profile> getAllProfiles(){
		return profileRepository.findAll();
	}

	//Get Profile By Id
	@GetMapping("/{id}")
	public ResponseEntity<Profile> getProfileById(@PathVariable Long id){
		Profile profile = profileRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Profile not exit with id:" +id));
		 return ResponseEntity.ok(profile);
	
	}
		
	//Add Profile
	@PostMapping("/save")
	public Profile addProfile(@RequestBody Profile profile) {
		return profileRepository.save(profile);
	}
	
	//Update Profile
	@PutMapping("/update/{id}")
	Profile replaceProfile(@RequestBody Profile newProfile, @PathVariable Long id) {
		return profileRepository.findById(id)
        .map(profile -> {
        	profile.setLibelle(newProfile.getLibelle());
        	profile.setDescription(newProfile.getDescription());
          return profileRepository.save(profile);
        })
        .orElseGet(() -> {
          newProfile.setIdProfile(id);
          return profileRepository.save(newProfile);
        });
    }	
	
	//Delete Profile
	@DeleteMapping("/delete/{id}")
	public void deleteProfileById(@PathVariable Long id) {
		profileRepository.deleteById(id);
	}
		
}