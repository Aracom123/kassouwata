package com.techinnov.kassouwata_back.repositories;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.techinnov.kassouwata_back.entitites.Produit;

public interface ProduitRepository  extends JpaRepository<Produit,Long> {

	/**
	 * Retourne tous les produits triés par date de création décroissante
	 * (les plus récents en premier). Utilisé par GET /api/nosProduits/list.
	 */
	@Query(value = "SELECT * FROM produit ORDER BY created_at DESC", nativeQuery = true)
	List<Produit> findAllOrderByCreatedAtDesc();

	@Query(value="SELECT * FROM produit u WHERE u.boutique_id = ?1", nativeQuery=true)
	List<Produit> getByBoutiqueId(@Param("idBoutique") Long idBoutique);

	@Query(value="SELECT COUNT(*) FROM produit WHERE statut = true", nativeQuery=true)
	int getNombreProduitsPublies();

	@Query(value="SELECT COUNT(*) FROM produit", nativeQuery=true)
	int getNombreProduitsTotal();

	@Query(value="SELECT COUNT(*) FROM produit WHERE boutique_id = :idBoutique", nativeQuery=true)
	int getNombreProduitsByBoutique(@Param("idBoutique") Long idBoutique);

	@Query(value="SELECT COUNT(*) FROM produit WHERE boutique_id = :idBoutique AND statut = true", nativeQuery=true)
	int getNombreProduitsPubliesByBoutique(@Param("idBoutique") Long idBoutique);
}
