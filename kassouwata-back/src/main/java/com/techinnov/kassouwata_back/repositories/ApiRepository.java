package com.techinnov.kassouwata_back.repositories;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.techinnov.kassouwata_back.entitites.Api;


public interface ApiRepository extends JpaRepository<Api, Long> {

	@Query(value="SELECT * FROM api a WHERE pays_id_pays = ?1", nativeQuery = true)
	Page<Api> getAllApiByAtelier(Pageable page);
	
	@Query(value="SELECT * FROM api WHERE type_api = ?1 LIMIT 1", nativeQuery = true)
	Api findByType(int type);
	
}
