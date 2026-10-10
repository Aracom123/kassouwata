package com.techinnov.kassouwata_back.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import com.techinnov.kassouwata_back.entitites.Livraison;

public interface LivraisonRepository  extends JpaRepository<Livraison,Long> {	
	// @Query(value="SELECT * FROM utilisateur u WHERE u.username = ?1 LIMIT 1 ", nativeQuery=true)
	// User getUserByUsername(@Param("username") String username);
}
