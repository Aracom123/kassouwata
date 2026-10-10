package com.techinnov.kassouwata_back.repositories;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.techinnov.kassouwata_back.entitites.TontinePeriodeVersement;

public interface TontinePeriodeVersementRepository extends JpaRepository<TontinePeriodeVersement, Long> {

    @Query("SELECT p FROM TontinePeriodeVersement p WHERE p.tontine.idTontine = :idTontine ORDER BY p.dateDebut ASC")
    List<TontinePeriodeVersement> findByTontineId(@Param("idTontine") Long idTontine);
}
