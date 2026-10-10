package com.techinnov.kassouwata_back.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import com.techinnov.kassouwata_back.entitites.Tontine;

public interface TontineRepository  extends JpaRepository<Tontine,Long> {

	@Query(value="SELECT COUNT(*) FROM tontine", nativeQuery=true)
	int getNombreTontines();

	/** Nombre de participants avec une demande ACCEPTEE */
	@Query(value="SELECT COUNT(*) FROM demande_adhesion WHERE statut = 'ACCEPTEE'", nativeQuery=true)
	int getNombreParticipants();
}
