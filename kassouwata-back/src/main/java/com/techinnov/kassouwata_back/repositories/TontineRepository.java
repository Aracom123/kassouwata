package com.techinnov.kassouwata_back.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import com.techinnov.kassouwata_back.entitites.Tontine;

public interface TontineRepository  extends JpaRepository<Tontine,Long> {

	/** Adashé Produit d'un produit */
	@Query("SELECT t FROM Tontine t WHERE t.produit.idProduit = :idProduit ORDER BY t.idTontine DESC")
	java.util.List<Tontine> findByProduitId(@org.springframework.data.repository.query.Param("idProduit") Long idProduit);

	/** Adashé Produit portant sur les produits d'une boutique */
	@Query("SELECT t FROM Tontine t WHERE t.produit.boutique.idBoutique = :idBoutique ORDER BY t.idTontine DESC")
	java.util.List<Tontine> findByBoutiqueId(@org.springframework.data.repository.query.Param("idBoutique") Long idBoutique);


	@Query(value="SELECT COUNT(*) FROM tontine", nativeQuery=true)
	int getNombreTontines();

	/** Nombre de participants avec une demande ACCEPTEE */
	@Query(value="SELECT COUNT(*) FROM demande_adhesion WHERE statut = 'ACCEPTEE'", nativeQuery=true)
	int getNombreParticipants();
}
