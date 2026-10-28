package com.techinnov.kassouwata_back.repositories;

import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.techinnov.kassouwata_back.entitites.Boutique;
import com.techinnov.kassouwata_back.enums.BoutiqueStatus;

public interface BoutiqueRepository  extends JpaRepository<Boutique,Long> {
	/**
	 * Boutique d'un vendeur. S'il en a plusieurs (doublon créé par erreur), on
	 * retient celle qui a le plus de produits, puis la plus ancienne.
	 */
	@Query(value="SELECT b.* FROM boutique b WHERE b.user_id = ?1 "
			+ "ORDER BY (SELECT COUNT(*) FROM produit p WHERE p.boutique_id = b.id_boutique) DESC, "
			+ "b.id_boutique ASC LIMIT 1", nativeQuery=true)
	Boutique getUserByVendeurID(@Param("username") UUID username);

	/** Boutiques visibles par le public (catalogue des applications mobiles). */
	Page<Boutique> findByStatus(BoutiqueStatus status, Pageable page);

	@Query(value="SELECT COUNT(*) FROM boutique WHERE status = 'ACTIVE'", nativeQuery=true)
	int getNombreBoutiquesActives();

	@Query(value="SELECT COUNT(*) FROM boutique", nativeQuery=true)
	int getNombreBoutiquesTotal();
}
