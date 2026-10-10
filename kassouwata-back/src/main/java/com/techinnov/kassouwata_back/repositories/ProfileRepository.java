package com.techinnov.kassouwata_back.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.techinnov.kassouwata_back.entitites.Profile;


public interface ProfileRepository extends JpaRepository<Profile,Long> {

	@Query(value="SELECT p FROM Profile p WHERE p.libelle = ?1", nativeQuery = true)
	public Profile findByProfile(String libelle);
	
	@Query(value="SELECT p FROM Profile p WHERE p.id_profile = ?1", nativeQuery = true)
	public Profile getById(Long id);
	
	
	@Query("SELECT p FROM Profile p WHERE p.libelle = ?1")
	public Profile getProfileClient(String libelle);
}
