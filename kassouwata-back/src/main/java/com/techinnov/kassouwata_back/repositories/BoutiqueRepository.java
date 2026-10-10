package com.techinnov.kassouwata_back.repositories;

import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.techinnov.kassouwata_back.entitites.Boutique;

public interface BoutiqueRepository  extends JpaRepository<Boutique,Long> {
	@Query(value="SELECT * FROM boutique b WHERE b.user_id = ?1 LIMIT 1 ", nativeQuery=true)
	Boutique getUserByVendeurID(@Param("username") UUID username);

	@Query(value="SELECT COUNT(*) FROM boutique WHERE status = 'ACTIVE'", nativeQuery=true)
	int getNombreBoutiquesActives();

	@Query(value="SELECT COUNT(*) FROM boutique", nativeQuery=true)
	int getNombreBoutiquesTotal();
}
