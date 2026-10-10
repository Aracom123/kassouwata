package com.techinnov.kassouwata_back.repositories;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.techinnov.kassouwata_back.entitites.DemandeAdhesion;

public interface DemandeAdhesionRepository extends JpaRepository<DemandeAdhesion, Long> {

    @Query("SELECT d FROM DemandeAdhesion d WHERE d.tontine.idTontine = :idTontine ORDER BY d.dateEnvoi DESC")
    List<DemandeAdhesion> findByTontineId(@Param("idTontine") Long idTontine);
}