package com.techinnov.kassouwata_back.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import com.techinnov.kassouwata_back.entitites.ProduitCommande;

public interface ProduitCommandeRepository  extends JpaRepository<ProduitCommande,Long> {
	boolean existsByProduit_IdProduit(Long idProduit);
}
